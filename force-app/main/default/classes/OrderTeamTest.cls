@isTest
public class OrderTeamTest 
{
	static final String TEST_USERNAME = 'testuser@mail.weir.invalid';    
    static final String Order_NAME = 'Test';
    static final String SHARING_REASON = 'Manual';
    static final String TEAM_ACCESS_EDIT = 'Edit';
    static final String TEAM_ROLE_ACCOUNT_MANAGER = 'Account Manager';
    static final String TEAM_ROLE_CHANNEL_MANAGER = 'Channel Manager';
    
    @testSetup
    static void setupData()
    {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User user = new User(Alias = 'standt', Email='standarduser@example.com', EmailEncodingKey='UTF-8', 
                          LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = profile.Id,
        				  TimeZoneSidKey='America/Los_Angeles', UserName = TEST_USERNAME);
        insert user;
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        Order order = new Order();
        order.AccountId = acc.Id;
        order.EffectiveDate = System.today();
        order.Status = 'Draft';
        insert Order; 
    }
    
    @isTest
    static void testInsertOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT);
        
        Test.startTest();
        insert OrderTeam;
        Test.stopTest();
        
        List<OrderShare> OrderShares = [SELECT Id FROM OrderShare WHERE OrderId = :Order.Id AND UserOrGroupId = :user.Id AND RowCause = :SHARING_REASON];
        System.assertEquals(1, OrderShares.size());
    }
    
    @isTest
    static void testUpdateOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT);
        
        Test.startTest();
        insert OrderTeam;        
        update OrderTeam;
        Test.stopTest();
        
        List<OrderShare> OrderShares = [SELECT Id FROM OrderShare WHERE OrderId = :Order.Id AND UserOrGroupId = :user.Id AND RowCause = :SHARING_REASON];
        System.assertEquals(1, OrderShares.size());
    }

    @isTest
    static void testDeleteOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT);
        
        Test.startTest();
        insert OrderTeam;        
        delete OrderTeam;
        Test.stopTest();
        
        List<OrderShare> OrderShares = [SELECT Id FROM OrderShare WHERE OrderId = :Order.Id AND UserOrGroupId = :user.Id AND RowCause = :SHARING_REASON];
        System.assertEquals(0, OrderShares.size());
    }

	@isTest
	static void testDeleteDefaultOrderTeam()
    {
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
        insert defaultOrderTeam;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(defaultOrderTeam);
        DeleteDefaultOrderTeamController ctrl = new DeleteDefaultOrderTeamController(sc);
        ctrl.deleteRecord();
        Test.stopTest();
        
        List<Default_Order_Team__c> defaultOrderTeams = [SELECT Id FROM Default_Order_Team__c WHERE Id = :defaultOrderTeam.Id];
        System.assertEquals(0, defaultOrderTeams.size());        
    }
    
	@isTest
	static void testDeleteDefaultOrderTeam_WithDeleteOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
        insert defaultOrderTeam;        
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT);
        insert OrderTeam;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(defaultOrderTeam);
        DeleteDefaultOrderTeamController ctrl = new DeleteDefaultOrderTeamController(sc);
        ctrl.deleteOrderTeam = true;
        ctrl.deleteRecord();
        ctrl.cancel();
        Test.stopTest();
        
        List<Default_Order_Team__c> defaultOrderTeams = [SELECT Id FROM Default_Order_Team__c WHERE Id = :defaultOrderTeam.Id];
        System.assertEquals(0, defaultOrderTeams.size()); 
        List<Order_Team__c> OrderTeams = [SELECT Id FROM Order_Team__c WHERE Order__c = :Order.Id];
        System.assertEquals(0, OrderTeams.size());          
    } 
    
	@isTest
	static void testCreateDefaultOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);        		        
        
        Test.startTest();
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultOrderTeams);
        CreateDefaultOrderTeamController ctrl = new CreateDefaultOrderTeamController(sc);    
        ctrl.defaultOrderTeams.add(defaultOrderTeam);        
        ctrl.save();        
        Test.stopTest();
        
        List<Default_Order_Team__c> defaultOrderTeamsInDB = [SELECT Id FROM Default_Order_Team__c WHERE OwnerId = :System.UserInfo.getUserId()];
        System.assertEquals(1, defaultOrderTeamsInDB.size());        
    }

	@isTest
	static void testCreateDefaultOrderTeam_WithUpdateOrderTeam_ExistingOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);        		          
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT);
        insert OrderTeam;       
        
        Test.startTest();
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultOrderTeams);
        CreateDefaultOrderTeamController ctrl = new CreateDefaultOrderTeamController(sc);    
        ctrl.defaultOrderTeams.add(defaultOrderTeam);
		ctrl.updateOrderTeam = true;        
        ctrl.saveAndMore();
		ctrl.cancel();        
        Test.stopTest();
        
        List<Order_Team__c> OrderTeamsInDB = [SELECT Id FROM Order_Team__c WHERE Order__c = :Order.Id];
        System.assertEquals(1, OrderTeamsInDB.size());        
    }
    
	@isTest
	static void testCreateDefaultOrderTeam_WithUpdateOrderTeam_NewOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);  		                  
        
        Test.startTest();
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultOrderTeams);
        CreateDefaultOrderTeamController ctrl = new CreateDefaultOrderTeamController(sc);    
        ctrl.defaultOrderTeams.add(defaultOrderTeam);
		ctrl.updateOrderTeam = true;        
        ctrl.saveAndMore();
		ctrl.cancel();        
        Test.stopTest();
        
        List<Order_Team__c> OrderTeamsInDB = [SELECT Id FROM Order_Team__c WHERE Order__c = :Order.Id];
        System.assertEquals(1, OrderTeamsInDB.size());        
    }    
    
	@isTest
	static void testCreateDefaultOrderTeam_ExistingDefaultOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
		insert defaultOrderTeam;     
        
        Test.startTest();
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultOrderTeams);
        CreateDefaultOrderTeamController ctrl = new CreateDefaultOrderTeamController(sc);    
        defaultOrderTeam.Id = null;
        defaultOrderTeam.Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER;
        ctrl.defaultOrderTeams.add(defaultOrderTeam);		        
        ctrl.save();		
        Test.stopTest();
        
        List<Default_Order_Team__c> defaultOrderTeamsInDB = [SELECT Team_Role__c FROM Default_Order_Team__c WHERE OwnerId = :System.UserInfo.getUserId()];
        System.assertEquals(1, defaultOrderTeamsInDB.size()); 
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, defaultOrderTeamsInDB.get(0).Team_Role__c); 
    }
    
	static void testCreateDefaultOrderTeam_ExistingOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);		        		          
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER);
        insert OrderTeam;       
        
        Test.startTest();
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultOrderTeams);
        CreateDefaultOrderTeamController ctrl = new CreateDefaultOrderTeamController(sc);    
        ctrl.updateOrderTeam = true;
        defaultOrderTeam.Id = null;        
        ctrl.defaultOrderTeams.add(defaultOrderTeam);		        
        ctrl.save();		
        Test.stopTest();
        
        List<Order_Team__c> OrderTeamsInDB = [SELECT Team_Role__c FROM Order_Team__c WHERE Order__c = :Order.Id];
        System.assertEquals(1, OrderTeamsInDB.size());  
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, OrderTeamsInDB.get(0).Team_Role__c);
    }
    
	@isTest
	static void testEditDefaultOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Order_Team__c defaultOrderTeam = new Default_Order_Team__c(Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);        		        
        insert defaultOrderTeam;
        
        Test.startTest();
        List<Default_Order_Team__c> defaultOrderTeams = new List<Default_Order_Team__c>();
        ApexPages.StandardController sc = new ApexPages.StandardController(defaultOrderTeam);
        EditDefaultOrderTeamController ctrl = new EditDefaultOrderTeamController(sc);  
        defaultOrderTeam.Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER;
        ctrl.defaultOrderTeam = defaultOrderTeam;
        ctrl.save();     
        ctrl.cancel();
        Test.stopTest();
        
        List<Default_Order_Team__c> defaultOrderTeamsInDB = [SELECT Team_Role__c FROM Default_Order_Team__c WHERE OwnerId = :System.UserInfo.getUserId()];
        System.assertEquals(1, defaultOrderTeamsInDB.size()); 
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, defaultOrderTeamsInDB.get(0).Team_Role__c);
    }

    @isTest
    static void testCreateOrUpdateOrderTeam_NewOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT);
        List<Order_Team__c> OrderTeams = new List<Order_Team__c>();
        OrderTeams.add(OrderTeam);
        
        Test.startTest();
        OrderTeamController.createOrUpdateOrderTeam(OrderTeams);
        Test.stopTest();
        
        List<Order_Team__c> OrderTeamsInDB = [SELECT Id FROM Order_Team__c WHERE Order__c = :Order.Id];
        System.assertEquals(1, OrderTeamsInDB.size());
    } 
    
    @isTest
    static void testCreateOrUpdateOrderTeam_ExistingOrderTeam()
    {
        Order Order = [SELECT Id FROM Order];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Order_Team__c OrderTeam = new Order_Team__c(Order__c = Order.Id, Team_Member__c = user.Id, Order_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
        insert OrderTeam;
        List<Order_Team__c> OrderTeams = new List<Order_Team__c>();
        OrderTeams.add(OrderTeam);
        
        Test.startTest();
        OrderTeam.Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER;
        OrderTeamController.createOrUpdateOrderTeam(OrderTeams);
        Test.stopTest();
        
        List<Order_Team__c> OrderTeamsInDB = [SELECT Team_Role__c FROM Order_Team__c WHERE Order__c = :Order.Id];
        System.assertEquals(1, OrderTeamsInDB.size());
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, OrderTeamsInDB.get(0).Team_Role__c);
    }     
}