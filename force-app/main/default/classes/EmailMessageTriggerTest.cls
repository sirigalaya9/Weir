@isTest
public class EmailMessageTriggerTest 
{
	@testSetup
    static void testSetup()
    {
		Id STDPriceBookId = TestUtility.createSTDPriceBookRecords(); 
        List<Account> mAccounts = TestUtility.createAccountRecords1(1, null, True, True);        
        List<Address__c> mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True); 
        List<Sales_Organization__c> mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
        List<Sales_Organization_User__c> mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgs[0].id, True);
        List<Opportunity> mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
    }
    
    @isTest
    static void testInsertEmailMessage()
    {        
        Opportunity opp = [SELECT Id FROM Opportunity Limit 1];
        EmailMessage emailMessage = new EmailMessage();
        emailMessage.status = '3'; // email was sent
        emailMessage.relatedToId = opp.Id; // related to record e.g. an opportunity
        emailMessage.fromAddress = 'sender@example.com'; // from address
        emailMessage.toAddress = 'test@kliqxe.com';
        emailMessage.fromName = 'Test EM5'; // from name
        emailMessage.subject = 'Test EM5'; // email subject
        emailMessage.htmlBody = '<html><body><b>Hello</b></body></html>'; // email body
        Test.startTest();
        insert emailMessage; 
        Test.stopTest();
    }
}