public class EditDefaultLeadTeamController
{
    public User user { get; set; }
    public User_Setting__c userSetting { get; set; }
    public Boolean updateLeadTeam { get; set; }
    public Default_Lead_Team__c defaultLeadTeam { get; set; }
    
    public EditDefaultLeadTeamController(ApexPages.StandardController stdController)
    {
        defaultLeadTeam = (Default_Lead_Team__c) stdController.getRecord();
        init();
    }
    
    public void init()
    {        
        defaultLeadTeam = [SELECT OwnerId, Lead_Access__c, Team_Role__c, Team_Member__c, Team_Member__r.Name FROM Default_Lead_Team__c WHERE Id = :defaultLeadTeam.Id];
        user = [SELECT Name FROM User WHERE Id = :defaultLeadTeam.OwnerId];
        userSetting = User_Setting__c.getInstance(user.Id);
        updateLeadTeam = false;
    }

    public PageReference save()
    {        
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        defaultLeadTeams.add(defaultLeadTeam);
        boolean success = LeadTeamController.createOrUpdateDefaultLeadTeam(defaultLeadTeams, user.Id, updateLeadTeam);
        if (success)
        {
        	upsert userSetting;   
        }
        return new PageReference('/' + userSetting.SetupOwnerId);
    }  
    
    public PageReference cancel()
    {		       
        return new PageReference('/' + userSetting.SetupOwnerId);
    }
}