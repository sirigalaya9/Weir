@isTest
public class OppNotificationschedulableBatchTest {
    
    @testsetup
    public static void testData(){
        List<Account> mAccounts;
        List<Address__c> mShipTos;
        List<Sales_Organization__c> mSalesOrgs;
        List<Sales_Organization_User__c> mSalesOrgUsers;
        List<Opportunity> mOpportunities;
        List<Territory2Type> terriType;
        List<Organization_Structure__c> mOrgStructure;
        List<Sales_Area_Detail__c> mSalesArea;
        Opportunity mOpportunity;
        User mUser;
        Territory2Model terrModel;
        Territory2 objTerr;

        Id STDPriceBookId;
        
        Profile mProfile = [SELECT Id FROM Profile WHERE Name = 'Integration']; 
        insert mUser = new User(Alias = 'standt', Email='Integration@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = mProfile.Id, Division = 'ENAR',
                                TimeZoneSidKey='America/Los_Angeles', UserName='Integration@testorg.com', ERP_Id__c = 'user123');
        
        System.runAs (new User(Id = UserInfo.getUserId())){
            terriType = [SELECT id, DeveloperName from Territory2Type where DeveloperName = 'Managed_Accounts'];
            terrModel = [SELECT id, DeveloperName,State from Territory2Model where DeveloperName = 'Weir_Minerals'];
            insert objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId = terrModel.Id, Name='AM1_AM01_GB01', Territory2TypeId=terriType[0].Id);
        }
        
        STDPriceBookId = TestUtility.createSTDPriceBookRecords();
        mAccounts = TestUtility.createAccountRecords(1, True);
        mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
        mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
        mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, mUser.Id, mSalesOrgs[0].id, True);
        mOrgStructure = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
        mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
        insert mOpportunity = new Opportunity(Name='Opportunity Name',StageName='Qualification',
                                              CloseDate=System.today(),AccountId=mAccounts[0].Id, CurrencyISOCode = 'AUD',Division__c = '00', Channel__c = '30',
                                              Sales_Organization_User__c = mSalesOrgUsers[0].id , OwnerId = mUser.Id);
    }
    
    public static testmethod void BatchPopulateTest(){
        Date dateToday = System.today();
        Date dateWeek = System.today() +7 ;
        String stringToday = String.valueOf(dateToday);
        String stringWeek = String.valueOf(dateWeek);
        
        String query = 'SELECT Id, Name, CloseDate, Close_Date_Today__c, Close_Date_Week__c, IsClosed FROM Opportunity '+
            'WHERE (CloseDate ='+ stringToday+ ' OR CloseDate ='+ stringWeek +') AND IsClosed = false';
        
        list<Opportunity> lstOpp  = (List<Opportunity>)Database.query(query);
        system.assertEquals(1, lstOpp.size());
        
        test.startTest();
        OpportunityNotificationschedulableBatch bch = new OpportunityNotificationschedulableBatch();
        Database.executeBatch(bch);
        test.stopTest();   
    }
    
    public static testmethod void SchedulableBatch0Test()
    {
        OpportunityNotificationschedulableBatch.start(0);
    }
    
    public static testmethod void SchedulableBatch1Test()
    {
        OpportunityNotificationschedulableBatch.start(1);    
    }
    
}