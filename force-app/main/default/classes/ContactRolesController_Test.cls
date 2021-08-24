@isTest
public class ContactRolesController_Test 
{
	static final String TEST_USERNAME = 'testuser@mail.weir.invalid';
    static final String ACCOUNT_NAME = 'Test';
    static final String PROJECT_NAME = 'Test';
    static final String SHARING_REASON = 'Team__c';
    static final String TEAM_ACCESS_EDIT = 'Edit';
    static final String TEAM_ROLE_ACCOUNT_MANAGER = 'Account Manager';
    static final String TEAM_ROLE_CHANNEL_MANAGER = 'Channel Manager';
    
    static final String CONTACT_FIRSTNAME = 'TestFirstName';
    static final String CONTACT_LASTNAME = 'TestLastName';
    
    static Account account;
    static Contact contact;
    static Contact newContact;
    static Project__c project;
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
        project = new Project__c(Name = PROJECT_NAME, Account__c = account.Id);
        insert project;
    }
    
    @isTest
    static void testInsertandUpdateProjectContactRoles()
    {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :PROJECT_NAME];
        Contact contact = [SELECT Id FROM Contact WHERE FirstName = :CONTACT_FIRSTNAME];
        Project_Contact_Role__c projectContactRole = new Project_Contact_Role__c(Project__c = project.Id, Contact__c = contact.Id, Role__c = 'Business User');
        List<Project_Contact_Role__c> projectContactRoles = new List<Project_Contact_Role__c>();
        projectContactRoles.add(projectContactRole);
        
        Test.startTest();
        insert projectContactRole;
        ContactRolesController.createOrUpdateProjectContactRole(projectContactRoles);
        Test.stopTest();
        
    }
    
    @isTest
    static void testFetchData()
    {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :PROJECT_NAME];
        Test.startTest();
        ContactRolesController.fetchData('FirstName', project.id);
        Test.stopTest();  
    }
    
    @isTest
    static void testFetchDataBlank()
    {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :PROJECT_NAME];
        Test.startTest();
        ContactRolesController.fetchData('', project.id);
        Test.stopTest();  
    }
    
    @isTest
    static void testFetchDataById()
    {
        Contact contact = [SELECT Id FROM Contact WHERE FirstName = :CONTACT_FIRSTNAME];
        Test.startTest();
        ContactRolesController.fetchDataById(contact.id);
        Test.stopTest();  
    }
    
    @isTest
    static void testGetPrimaryContact()
    {
        Project__c project = [SELECT Id FROM Project__c WHERE Name = :PROJECT_NAME];
        Test.startTest();
        ContactRolesController.getPrimaryContact(project.id);
        ContactRolesController.getProjectContactRoles(project.id);
        
        Test.stopTest();  
    }
    
}