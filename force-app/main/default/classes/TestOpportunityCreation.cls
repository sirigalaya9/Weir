@isTest
public class TestOpportunityCreation {
    
    static testmethod void SetupData()
    {
        Account acct = new Account(Name='Test Account',BillingCity='BillingCity',BillingPostalCode='BillingPostalCode',BillingCountry ='BillingCountry');
        insert acct;
        Sales_Organization__c SaleOrg = new Sales_Organization__c(Name='Asia Commercial',Code__c='MY03');
        insert SaleOrg;
        Sales_Organization_User__c SaleOrgUser = new Sales_Organization_User__c(Name='TestSalesOrgUser',User__c=UserInfo.getUserId(),Sales_Organizationa__c=SaleOrg.id);
        insert SaleOrgUser;
        Opportunity opp = new Opportunity(Name='Opportunity Name',OwnerId = UserInfo.getUserId(), StageName='Qualification',CloseDate=System.today().addMonths(1),AccountId=acct.Id);
        insert opp;
    }
}