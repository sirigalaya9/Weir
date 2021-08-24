public class CreateDefaultOrderTeamController 
{
    public User user { get; set; }    
    public Boolean enableDefaultOrderTeam { get; set; }
    public Boolean updateOrderTeam { get; set; }
    public List<Default_Order_Team__c> defaultOrderTeams { get; set; }
    
    
    public CreateDefaultOrderTeamController(ApexPages.StandardSetController stdController)
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
        enableDefaultOrderTeam = userSetting.Enable_Default_Order_Team__c;
        updateOrderTeam = false;
        defaultOrderTeams = new List<Default_Order_Team__c>();
        for (Integer i=0; i<5; i++)
        {
            Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(OwnerId = userId);
            defaultOrderTeams.add(defaultOrderTeam);
        }
    }
    
    public PageReference save()
    {
        boolean success = OrderTeamController.createOrUpdateDefaultOrderTeam(defaultOrderTeams, user.Id, updateOrderTeam);
        if (success)
        {
			User_Setting__c userSetting = User_Setting__c.getInstance(user.Id);
            userSetting.Enable_Default_Order_Team__c = enableDefaultOrderTeam;
			upsert userSetting;   
            
            Id userId = ApexPages.currentPage().getParameters().get('Id');
            if (userId == null)
                return new PageReference('/' + Default_Order_Team__c.sObjectType.getDescribe().getKeyPrefix());
            else
                return new PageReference('/' + user.Id);            
        }
        else return null;
    }

    public void saveAndMore()
    {        
        boolean success = OrderTeamController.createOrUpdateDefaultOrderTeam(defaultOrderTeams, user.Id, updateOrderTeam);
        if (success)
        {
			User_Setting__c userSetting = User_Setting__c.getInstance(user.Id);
            userSetting.Enable_Default_Order_Team__c = enableDefaultOrderTeam;
			upsert userSetting;        
        }
        init();
    }  
    
    public PageReference cancel()
    {		       
        Id userId = ApexPages.currentPage().getParameters().get('Id');
        if (userId == null)
        	return new PageReference('/' + Default_Order_Team__c.sObjectType.getDescribe().getKeyPrefix());
        else
        	return new PageReference('/' + user.Id);
    }    
}