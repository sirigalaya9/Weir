public class EditDefaultOrderTeamController
{
    public User user { get; set; }
    public User_Setting__c userSetting { get; set; }
    public Boolean updateOrderTeam { get; set; }
    public Default_Order_Team__c defaultOrderTeam { get; set; }
    
    public EditDefaultOrderTeamController(ApexPages.StandardController stdController)
    {
        defaultOrderTeam = (Default_Order_Team__c) stdController.getRecord();
        init();
    }
    
    public void init()
    {        
        defaultOrderTeam = [SELECT OwnerId, Order_Access__c, Team_Role__c, Team_Member__c, Team_Member__r.Name FROM Default_Order_Team__c WHERE Id = :defaultOrderTeam.Id];
        user = [SELECT Name FROM User WHERE Id = :defaultOrderTeam.OwnerId];
        userSetting = User_Setting__c.getInstance(user.Id);
        updateOrderTeam = false;
    }

    public PageReference save()
    {        
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        defaultOrderTeams.add(defaultOrderTeam);
        boolean success = OrderTeamController.createOrUpdateDefaultOrderTeam(defaultOrderTeams, user.Id, updateOrderTeam);
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