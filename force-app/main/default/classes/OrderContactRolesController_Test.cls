@isTest
public class OrderContactRolesController_Test 
{
	static final String TEST_USERNAME = 'testuser@mail.weir.invalid';
    static final String ACCOUNT_NAME = 'Test';
    static final String ORDER_NAME = 'Test';
    static final String SHARING_REASON = 'Team__c';
    static final String TEAM_ACCESS_EDIT = 'Edit';
    static final String TEAM_ROLE_ACCOUNT_MANAGER = 'Account Manager';
    static final String TEAM_ROLE_CHANNEL_MANAGER = 'Channel Manager';
    
    static final String CONTACT_FIRSTNAME = 'TestFirstName';
    static final String CONTACT_LASTNAME = 'TestLastName';
    
    static Account account;
    static Contact contact;
    static Contact newContact;
    static Order ord;
    static User user;
    
    @testSetup
    static void setupData()
    {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User user = new User(Alias = 'standt', Email='standarduser@example.com', EmailEncodingKey='UTF-8', 
                          LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = profile.Id,
        				  TimeZoneSidKey='America/Los_Angeles', UserName = TEST_USERNAME);
        insert user;
        account = new Account(Name = ACCOUNT_NAME, BillingCity = 'Kuala Lumpur', BillingPostalCode = '12345', BillingCountry = 'Malaysia');
        insert account;
        contact = new contact(FirstName = CONTACT_FIRSTNAME ,LastName = CONTACT_LASTNAME, AccountId  = account.Id);
        insert contact;
        ord = new Order(Name = ORDER_NAME, AccountId = account.Id, EffectiveDate = System.today(), Status = 'Draft');
        insert ord;
    }
    
    @isTest
    static void testInsertandUpdateOrderContactRoles()
    {
        Order ord = [SELECT Id FROM Order WHERE Name = :ORDER_NAME];
        Contact contact = [SELECT Id FROM Contact WHERE FirstName = :CONTACT_FIRSTNAME];
        Order_Contact_Role__c OrderContactRole = new Order_Contact_Role__c(Order__c = ord.id, Contact__c = contact.Id, Role__c = 'Business User');
        List<Order_Contact_Role__c> OrderContactRoles = new List<Order_Contact_Role__c>();
        OrderContactRoles.add(OrderContactRole);
        
        Test.startTest();
        insert OrderContactRole;
        OrderContactRolesController.createOrUpdateOrderContactRole(OrderContactRoles);
        Test.stopTest();
        
    }
    
    @isTest
    static void testFetchData()
    {
        Order ord = [SELECT Id FROM Order WHERE Name = :ORDER_NAME];
        Test.startTest();
        OrderContactRolesController.fetchData('FirstName', ord.id);
        Test.stopTest();  
    }
    
    @isTest
    static void testFetchDataBlank()
    {
        Order ord = [SELECT Id FROM Order WHERE Name = :ORDER_NAME];
        Test.startTest();
        OrderContactRolesController.fetchData('', ord.id);
        Test.stopTest();  
    }
    
    @isTest
    static void testFetchDataById()
    {
        Contact contact = [SELECT Id FROM Contact WHERE FirstName = :CONTACT_FIRSTNAME];
        Test.startTest();
        OrderContactRolesController.fetchDataById(contact.id);
        Test.stopTest();  
    }
    
    @isTest
    static void testGetPrimaryContact()
    {
        Order ord = [SELECT Id FROM Order WHERE Name = :ORDER_NAME];
        Test.startTest();
        OrderContactRolesController.getPrimaryContact(ord.id);
        OrderContactRolesController.getOrderContactRoles(ord.id);
        
        Test.stopTest();  
    }
    
}