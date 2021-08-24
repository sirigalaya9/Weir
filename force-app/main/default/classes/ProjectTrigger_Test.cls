@isTest
public class ProjectTrigger_Test {
    static List<Account> mAccounts;
    static Project__c mProject;
    
    static void setupTestData()
    {
        mAccounts = TestUtility.createAccountRecords(1, True);
        insert mProject = new Project__c(Name='Project Name', Account__c = mAccounts[0].id, Total_Opportunity_Sum__c = 0, CurrencyISOCode = 'AUD');
    }
    
    @isTest static void UpdateProjectCurrency()
    { 
        setupTestData();
        Test.startTest();
        Project__c QProject = [Select Id, Name, Total_Opportunity_Sum__c  from Project__c Where Name =: mProject.Name];
        update mProject = new Project__c(id = QProject.id, CurrencyISOCode = 'GBP');
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteProject()
    {
        Account account = new Account(Name = 'Test', BillingCity = 'Kuala Lumpur', BillingPostalCode = '12345', BillingCountry = 'Malaysia');
        insert account;
        Project__c project = new Project__c(Name = 'PROJECT_NAME', Account__c = account.Id);
        insert project; 
        Project_Account__c mProjectAccount = new Project_Account__c(Account__c = account.Id , Project__c = project.Id);
        insert mProjectAccount;
        
        Test.startTest();
        delete project;
        Test.stopTest();
    }  

}