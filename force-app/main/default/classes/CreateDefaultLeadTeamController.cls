public class CreateDefaultLeadTeamController 
{
    public User user { get; set; }    
    public Boolean enableDefaultLeadTeam { get; set; }
    public Boolean updateLeadTeam { get; set; }
    public List<Default_Lead_Team__c> defaultLeadTeams { get; set; }
    
    
    public CreateDefaultLeadTeamController(ApexPages.StandardSetController stdController)
    {
        init();
    }
    
    public void init()
    {
        Id userId = ApexPages.currentPage().getParameters().get('Id');
        if (userId == NULL)
        {
            userId = System.UserInfo.getUserId();
        }
        user = [SELECT Name FROM User WHERE Id =:userId];
        User_Setting__c userSetting = User_Setting__c.getInstance(user.Id);
        enableDefaultLeadTeam = userSetting.Enable_Default_Lead_Team__c;
        updateLeadTeam = false;
        defaultLeadTeams = new List<Default_Lead_Team__c>();
        for (Integer i=0; i<5; i++)
        {
            Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(OwnerId = userId);
            defaultLeadTeams.add(defaultLeadTeam);
        }
    }
    
    public PageReference save()
    {
        boolean success = LeadTeamController.createOrUpdateDefaultLeadTeam(defaultLeadTeams, user.Id, updateLeadTeam);
        if (success)
        {
			User_Setting__c userSetting = User_Setting__c.getInstance(user.Id);
            userSetting.Enable_Default_Lead_Team__c = enableDefaultLeadTeam;
			upsert userSetting;   
            
            Id userId = ApexPages.currentPage().getParameters().get('Id');
            if (userId == null)
                return new PageReference('/' + Default_Lead_Team__c.sObjectType.getDescribe().getKeyPrefix());
            else
                return new PageReference('/' + user.Id);            
        }
        else return null;
    }

    public void saveAndMore()
    {        
        boolean success = LeadTeamController.createOrUpdateDefaultLeadTeam(defaultLeadTeams, user.Id, updateLeadTeam);
        if (success)
        {
			User_Setting__c userSetting = User_Setting__c.getInstance(user.Id);
            userSetting.Enable_Default_Lead_Team__c = enableDefaultLeadTeam;
			upsert userSetting;        
        }
        init();
    }  
    
    public PageReference cancel()
    {		       
        Id userId = ApexPages.currentPage().getParameters().get('Id');
        if (userId == null)
        	return new PageReference('/' + Default_Lead_Team__c.sObjectType.getDescribe().getKeyPrefix());
        else
        	return new PageReference('/' + user.Id);
    }    
}