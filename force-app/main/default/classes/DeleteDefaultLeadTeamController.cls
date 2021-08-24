public class DeleteDefaultLeadTeamController 
{
    public User user { get; set; }    
    public Boolean deleteLeadTeam { get; set; }
    public Default_Lead_Team__c defaultLeadTeam { get; set; }
    
    public DeleteDefaultLeadTeamController(ApexPages.StandardController stdController)
    {
        defaultLeadTeam = (Default_Lead_Team__c) stdController.getRecord();
        init();
    }
    
    public void init()
    {                
        defaultLeadTeam = [SELECT OwnerId, Team_Member__c FROM Default_Lead_Team__c WHERE Id =:defaultLeadTeam.Id];
        user = [SELECT Name FROM User WHERE Id = :defaultLeadTeam.OwnerId];        
        deleteLeadTeam = false;
    }

    public PageReference deleteRecord()
    {        
        if (deleteLeadTeam == true)
        {
            List<Lead> ownedLeads = [SELECT Id, (SELECT Team_Member__c FROM Lead_Teams__r WHERE Team_Member__c = :defaultLeadTeam.Team_Member__c) FROM Lead WHERE OwnerId =: user.Id];            
            List<Lead_Team__c> existingLeadTeams = new List<Lead_Team__c>();            
            for (Lead ownedLead : ownedLeads)
            {      
                for (Lead_Team__c existingLeadTeam : ownedLead.Lead_Teams__r)
                {                                           
                    existingLeadTeams.add(existingLeadTeam);                        
                }
            } 
            delete existingLeadTeams;
        }
        delete defaultLeadTeam;        
        return new PageReference('/' + user.Id);
    }  
    
    public PageReference cancel()
    {		       
        return new PageReference('/' + user.Id);
    }
}