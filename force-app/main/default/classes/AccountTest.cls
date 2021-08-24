@isTest
public class AccountTest 
{
    @testSetup
    static void setupData()
    {
    	Object_Permission__c objectPermission = new Object_Permission__c();
        objectPermission.Account_Delete_Prospect__c = TRUE;
        insert objectPermission;
    }
    
	@isTest
    static void testDeleteProspectAccountWithDeletePermission()
    {
        Account account = new Account(Name = 'Test', BillingCity = 'Kuala Lumpur', BillingPostalCode = '12345', BillingCountry = 'Malaysia');
        account.Prospect__c = true;
        insert account;
        
        Test.startTest();
        delete account;
        Test.stopTest();
        
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test'];
        System.assertEquals(0, accounts.size(), 'Prospect Account should be allowed to be deleted.');
    }
    
	@isTest
    static void testDeleteProspectAccountWithoutDeletePermission()
    {
        Object_Permission__c objectPermission = Object_Permission__c.getInstance();
        objectPermission.Account_Delete_Prospect__c = FALSE;
        upsert objectPermission;
        
        Account account = new Account(Name = 'Test', BillingCity = 'Kuala Lumpur', BillingPostalCode = '12345', BillingCountry = 'Malaysia');
        account.Prospect__c = true;
        insert account;
        
        Test.startTest();
        try
        {
            delete account;
        }
        catch (Exception e)
        {
            System.debug(e);
        }        
        Test.stopTest();
        
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test'];
        System.assertEquals(1, accounts.size(), 'Prospect Account should not be allowed to be deleted.');
    }    
    
	@isTest
    static void testDeleteNonProspectAccountWithoutDeletePermission()
    {
        Account account = new Account(Name = 'Test', BillingCity = 'Kuala Lumpur', BillingPostalCode = '12345', BillingCountry = 'Malaysia');        
        account.Prospect__c = false;
        insert account;
        
        Test.startTest();
        try
        {
        	delete account;
        }
        catch(Exception e)
        {
            System.debug(e);
        }
        Test.stopTest();
        
        List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test'];
        System.assertEquals(1, accounts.size(), 'Non Prospect Account should not be allowed to be deleted.');        
    }
    
    @isTest
    static void testDeleteAccount()
    {
        Account account = new Account(Name = 'Test', BillingCity = 'Kuala Lumpur', BillingPostalCode = '12345', BillingCountry = 'Malaysia');
        insert account;
        Project__c project = new Project__c(Name = 'PROJECT_NAME', Account__c = account.Id);
        insert project; 
        Project_Account__c mProjectAccount = new Project_Account__c(Account__c = account.Id , Project__c = project.Id);
        insert mProjectAccount;
        
        Test.startTest();
        delete account;
        Test.stopTest();
    }    
}