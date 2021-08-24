public class DeleteDefaultOrderTeamController 
{
    public User user { get; set; }    
    public Boolean deleteOrderTeam { get; set; }
    public Default_Order_Team__c defaultOrderTeam { get; set; }
    
    public DeleteDefaultOrderTeamController(ApexPages.StandardController stdController)
    {
        defaultOrderTeam = (Default_Order_Team__c) stdController.getRecord();
        init();
    }
    
    public void init()
    {                
        defaultOrderTeam = [SELECT OwnerId, Team_Member__c FROM Default_Order_Team__c WHERE Id =:defaultOrderTeam.Id];
        user = [SELECT Name FROM User WHERE Id = :defaultOrderTeam.OwnerId];        
        deleteOrderTeam = false;
    }

    public PageReference deleteRecord()
    {        
        if (deleteOrderTeam == true)
        {
            List<Order> ownedOrders = [SELECT Id, (SELECT Team_Member__c FROM Order_Teams__r WHERE Team_Member__c = :defaultOrderTeam.Team_Member__c) FROM Order WHERE OwnerId =: user.Id];            
            List<Order_Team__c> existingOrderTeams = new List<Order_Team__c>();            
            for (Order ownedOrder : ownedOrders)
            {      
                for (Order_Team__c existingOrderTeam : ownedOrder.Order_Teams__r)
                {                                           
                    existingOrderTeams.add(existingOrderTeam);                        
                }
            } 
            delete existingOrderTeams;
        }
        delete defaultOrderTeam;        
        return new PageReference('/' + user.Id);
    }  
    
    public PageReference cancel()
    {		       
        return new PageReference('/' + user.Id);
    }
}