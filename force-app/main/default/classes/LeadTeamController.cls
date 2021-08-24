public class LeadTeamController 
{
    public static final String SHARING_REASON = 'Manual';
    public static final String ACCESS_READ = 'Read';
    
    public static void createShares(List<Lead_Team__c> leadTeams)
    {                
        //If current user is not Lead owner or above owner in role hierarchy then need to prevent them from managing team
        Map<Id, UserRecordAccess> userAccessMap = new Map<Id, UserRecordAccess>();
        for (Lead_Team__c leadTeam : leadTeams)
        {
            userAccessMap.put(leadTeam.Lead__c, null);
        }
        List<UserRecordAccess> userAccesses = [SELECT RecordId, HasEditAccess, HasTransferAccess, MaxAccessLevel FROM UserRecordAccess 
                                               WHERE UserId = :System.UserInfo.getUserId() AND RecordId IN :userAccessMap.keySet()];
        for (UserRecordAccess userAccess : userAccesses)
        {            
			userAccessMap.put(userAccess.RecordId, userAccess);
        }

        //Get OWD of Lead
        Organization org = [Select DefaultLeadAccess from Organization];
            
        List<LeadShare> leadShares = new List<LeadShare>();
        for (Lead_Team__c leadTeam : leadTeams)
        {            
            UserRecordAccess userAccess = userAccessMap.get(leadTeam.Lead__c);            
            if (!userAccess.MaxAccessLevel.equalsIgnoreCase('All')) //Only owners and users above Lead owner in role hierarchy have 'All', team members have 'Edit'
            {
                LeadTeam.addError('insufficient access rights on object id');
                continue;
            }        
            if (org.DefaultLeadAccess.equalsIgnoreCase(ACCESS_READ) && leadTeam.Lead_Access__c.equalsIgnoreCase(ACCESS_READ))
            {
                continue;
            }
            LeadShare leadShare = new LeadShare();
            leadShare.LeadAccessLevel = leadTeam.Lead_Access__c;
            leadShare.UserOrGroupId = leadTeam.Team_Member__c;
            leadShare.LeadId = leadTeam.Lead__c;
            leadShare.RowCause = SHARING_REASON;
            leadShares.add(leadShare);
        }
        insert leadShares;        
    }
    
    public static void deleteShares(List<Lead_Team__c> leadTeams)
    {        
        //If current user is not Lead owner or above owner in role hierarchy then need to prevent them from managing team
        Map<Id, UserRecordAccess> userAccessMap = new Map<Id, UserRecordAccess>();
        for (Lead_Team__c leadTeam : leadTeams)
        {
			userAccessMap.put(leadTeam.Lead__c, null);            
        }
        List<UserRecordAccess> userAccesses = [SELECT RecordId, HasEditAccess, HasTransferAccess, MaxAccessLevel FROM UserRecordAccess 
                                               WHERE UserId = :System.UserInfo.getUserId() AND RecordId IN :userAccessMap.keySet()];
        for (UserRecordAccess userAccess : userAccesses)
        {            
			userAccessMap.put(userAccess.RecordId, userAccess);
        }
        
        List<Id> userIds = new List<Id>();        
        for (Lead_Team__c leadTeam : leadTeams)
        {
            UserRecordAccess userAccess = userAccessMap.get(leadTeam.Lead__c);            
            if (!userAccess.MaxAccessLevel.equalsIgnoreCase('All')) //Only owners and users above Lead owner in role hierarchy have 'All', team members have 'Edit'
            {
                leadTeam.addError('insufficient access rights on object id');                
                continue;
            }
            userIds.add(leadTeam.Team_Member__c);
        }
        
        List<LeadShare> leadShares = [SELECT Id FROM LeadShare WHERE UserOrGroupId IN :userIds AND LeadId IN :userAccessMap.keySet() AND RowCause = :SHARING_REASON];
        delete leadShares;         
    }
    
    @AuraEnabled
    public static void createOrUpdateLeadTeam(List<Lead_Team__c> leadTeams)
    {
        System.debug(leadTeams);
        
        Map<Id, Lead_Team__c> leadTeamMap = new Map<Id, Lead_Team__c>();
        Id leadId;
        for(Lead_Team__c leadTeam : leadTeams)
        {
            leadTeamMap.put(LeadTeam.Team_Member__c, LeadTeam);
            leadId = leadTeam.Lead__c;
        }
        
        {
            List<Lead> ownedLeads = [SELECT Id, (SELECT Team_Member__c FROM Lead_Teams__r WHERE Team_Member__c IN :LeadTeamMap.keySet()) FROM Lead WHERE Id = :leadId];
            List<Lead_Team__c> newLeadTeams = new List<Lead_Team__c>();
            List<Lead_Team__c> existingLeadTeams = new List<Lead_Team__c>();
            List<Id> ownedLeadIds = new List<Id>();
            for (Lead ownedLead : ownedLeads)
            {
                Set<Id> teamMemberExisting = new Set<Id>();
                if (ownedLead.Lead_Teams__r != NULL && ownedLead.Lead_Teams__r.size() > 0)
                {                        
                    for (Lead_Team__c existingLeadTeam : ownedLead.Lead_Teams__r)
                    {
                        if (leadTeamMap.containsKey(existingLeadTeam.Team_Member__c))
                        {
                            Lead_Team__c leadTeam = leadTeamMap.get(existingLeadTeam.Team_Member__c);
                            existingLeadTeam.Lead_Access__c = leadTeam.Lead_Access__c;
                            existingLeadTeam.Team_Role__c = leadTeam.Team_Role__c;
                            existingLeadTeams.add(existingLeadTeam);
                            teamMemberExisting.add(existingLeadTeam.Team_Member__c);
                        }
                    }                       
                }
                for (Id teamMemberId : leadTeamMap.keySet())
                {
                    if (!teamMemberExisting.contains(teamMemberId))
                    {
                        Lead_Team__c LeadTeam = leadTeamMap.get(teamMemberId);
                        Lead_Team__c newLeadTeam = new Lead_Team__c(Lead__c = ownedLead.Id);
                        newLeadTeam.Team_Member__c = teamMemberId;
                        newLeadTeam.Lead_Access__c = LeadTeam.Lead_Access__c;
                        newLeadTeam.Team_Role__c = LeadTeam.Team_Role__c;
                        newLeadTeams.add(newLeadTeam);
                    }                          
                }
            }
            insert newLeadTeams;
            update existingLeadTeams;
        }        
	}
    
    @AuraEnabled
    public static boolean createOrUpdateDefaultLeadTeam(List<Default_Lead_Team__c> defaultLeadTeams, Id userId, boolean updateLeadTeam)
    {        
        Map<Id, Default_Lead_Team__c> allDefaultLeadTeamMap = new Map<Id, Default_Lead_Team__c>();   
        Map<Id, Default_Lead_Team__c> newDefaultLeadTeamMap = new Map<Id, Default_Lead_Team__c>();
        for (Default_Lead_Team__c item : defaultLeadTeams)
        {
            if (item.Team_Member__c == NULL)
            {
                continue;
            }
            if (item.Team_Member__c != NULL && (item.Team_Role__c == null || item.Lead_Access__c == null))
            {
                return false;
            }            
            allDefaultLeadTeamMap.put(item.Team_Member__c, item); 
            newDefaultLeadTeamMap.put(item.Team_Member__c, item);
        }
        if (allDefaultLeadTeamMap.size() > 0)
        {    
            List<Default_Lead_Team__c> existingDefaultLeadTeams = [SELECT Team_Member__c FROM Default_Lead_Team__c WHERE Team_Member__c IN :allDefaultLeadTeamMap.keySet() AND OwnerId = :userId];
            List<Default_Lead_Team__c> newDefaultLeadTeams = new List<Default_Lead_Team__c>();
            for (Default_Lead_Team__c item : existingDefaultLeadTeams)
            {
                Default_Lead_Team__c matchedDefaultLeadTeam = allDefaultLeadTeamMap.get(item.Team_Member__c);
                item.Lead_Access__c = matchedDefaultLeadTeam.Lead_Access__c;
                item.Team_Role__c = matchedDefaultLeadTeam.Team_Role__c;
                newDefaultLeadTeamMap.remove(item.Team_Member__c);
            }
            newDefaultLeadTeams = newDefaultLeadTeamMap.values();
            insert newDefaultLeadTeams;             
            update existingDefaultLeadTeams;
            if (updateLeadTeam == true)
            {
                List<Lead> ownedLeads = [SELECT Id, (SELECT Team_Member__c FROM Lead_Teams__r WHERE Team_Member__c IN :allDefaultLeadTeamMap.keySet()) FROM Lead WHERE OwnerId =: userId];
                List<Lead_Team__c> newLeadTeams = new List<Lead_Team__c>();
                List<Lead_Team__c> existingLeadTeams = new List<Lead_Team__c>();
                List<Id> ownedLeadIds = new List<Id>();
                for (Lead ownedLead : ownedLeads)
                {
                    Set<Id> teamMemberExisting = new Set<Id>();
                    if (ownedLead.Lead_Teams__r != NULL && ownedLead.Lead_Teams__r.size() > 0)
                    {                        
                        for (Lead_Team__c existingLeadTeam : ownedLead.Lead_Teams__r)
                        {
                            if (allDefaultLeadTeamMap.containsKey(existingLeadTeam.Team_Member__c))
                            {
                                Default_Lead_Team__c defaultLeadTeam = allDefaultLeadTeamMap.get(existingLeadTeam.Team_Member__c);
                                existingLeadTeam.Lead_Access__c = defaultLeadTeam.Lead_Access__c;
                                existingLeadTeam.Team_Role__c = defaultLeadTeam.Team_Role__c;
                                existingLeadTeams.add(existingLeadTeam);
                                teamMemberExisting.add(existingLeadTeam.Team_Member__c);
                            }
                        }                       
                    }
                    for (Id teamMemberId : allDefaultLeadTeamMap.keySet())
                    {
                        if (!teamMemberExisting.contains(teamMemberId))
                        {
                            Default_Lead_Team__c defaultLeadTeam = allDefaultLeadTeamMap.get(teamMemberId);
                            Lead_Team__c newLeadTeam = new Lead_Team__c(Lead__c = ownedLead.Id);
                            newLeadTeam.Team_Member__c = teamMemberId;
                            newLeadTeam.Lead_Access__c = defaultLeadTeam.Lead_Access__c;
                            newLeadTeam.Team_Role__c = defaultLeadTeam.Team_Role__c;
                            newLeadTeams.add(newLeadTeam);
                        }                          
                    }
                }
                insert newLeadTeams;
                update existingLeadTeams;
            }            
        }        
        return true;
    }
}