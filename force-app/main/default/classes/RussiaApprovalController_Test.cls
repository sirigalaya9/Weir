@isTest
public class RussiaApprovalController_Test {
    static List<Account> mAccounts;
    static List<Address__c> mShipTos;
    static List<Sales_Organization__c> mSalesOrgs;
    static List<Sales_Organization_User__c> mSalesOrgUsers;
    static List<Opportunity> mOpportunities;
    
    static void setupTestData(){
        Id STDPriceBookId = TestUtility.createSTDPriceBookRecords();
        mAccounts = TestUtility.createAccountRecords(1, True);
        mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
        mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'RU01', True);
        mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgs[0].id, True);
        mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);     
       
    }
    
    @isTest static void SubmitToApproval()
    { 
        setupTestData();
        mOpportunities[0].Attachment_Attached__c = true;
        update mOpportunities;
        Opportunity mOpp = [Select Id, Attachment_Attached__c, Sales_Organization_User_Code__c from Opportunity where id =: mOpportunities[0].id];
        Boolean Success = RussiaApprovalController.SubmitForApproval(mOpp,'Comment');
    } 
}