@isTest
public class DuplicateJobTest 
{
    @TestSetup
    static void setupData()
    {
        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;        
        Account account1 = new Account(Name = 'Test Duplicate', BillingPostalCode = '1234', Phone = '12345678');
        Database.insert(account1, dml);
        Account account2 = new Account(Name = 'Test Duplicate', BillingPostalCode = '1234', Phone = '12345678');
        Database.insert(account2, dml);     
        Contact contact1 = new Contact(FirstName = 'Test', LastName = 'Test Duplicate 1', Email = 'test@example.com');
        contact1.AccountId = account1.Id;
        Database.insert(contact1, dml);
        Contact contact2 = new Contact(FirstName = 'Test', LastName = 'Test Duplicate 1', Email = 'test@example.com');
        contact2.AccountId = account2.Id;
        Database.insert(contact2, dml);            
    }

    @isTest
    static void testJob() 
    {
        Test.startTest();
        {
            SchedulableContext sc = null;
            DuplicateJob job = new DuplicateJob();
            job.execute(sc);
        }
        Test.stopTest();
        List<DuplicateRecordSet> results = [SELECT Id FROM DuplicateRecordSet WHERE Custom_Duplicate_Job__c = TRUE];
        System.assertEquals(2, results.size(), '2 Duplicate Set has to be recorded.');
    }

    @isTest
    static void testAccountJobController() 
    {
        List<Account> accounts = [SELECT Id FROM Account];
        Test.startTest();
        {
            ApexPages.StandardSetController std = new ApexPages.StandardSetController(accounts);
            AccountDuplicateJobController ctrl = new AccountDuplicateJobController(std);
            ctrl.runJob();           
        }
        Test.stopTest();
        List<DuplicateRecordSet> results = [SELECT Id FROM DuplicateRecordSet WHERE Custom_Duplicate_Job__c = TRUE];
        System.assertEquals(1, results.size(), '1 Duplicate Set has to be recorded.');
    }    

    @isTest
    static void testContactJobController() 
    {
        List<Contact> contacts = [SELECT Id FROM Contact];
        Test.startTest();
        {
            ApexPages.StandardSetController std = new ApexPages.StandardSetController(contacts);
            ContactDuplicateJobController ctrl = new ContactDuplicateJobController(std);
            ctrl.runJob();            
        }
        Test.stopTest();
        List<DuplicateRecordSet> results = [SELECT Id FROM DuplicateRecordSet WHERE Custom_Duplicate_Job__c = TRUE];
        System.assertEquals(1, results.size(), '1 Duplicate Set has to be recorded.');
    }      
}