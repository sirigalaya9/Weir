@isTest
public class PushToSAPController_Test {
    static List<Account> mAccounts;
    static User mUser;
    static List<Address__c> mShipTos;
    static List<Sales_Organization__c> mSalesOrgs;
    static List<Sales_Organization_User__c> mSalesOrgUsers;
    static List<Sales_Organization_Material__c> mSalesOrgMaterials;
    static List<Material_Number__c> mMaterials;
    static List<String> materialNumbers = new List<String>();
    static List<Product2> mNewProducts2;
    Static List<PricebookEntry> mNewPricebookEntries;
    static List<OpportunityLineItem> mNewOppLineItems ;
    static List<Opportunity> mOpportunities;
    static Id AccountSGTRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    
    static void setupTestData(){
        
        System.runAs (new User(Id = UserInfo.getUserId())){
            terriType = [SELECT id, DeveloperName from Territory2Type where DeveloperName = 'Managed_Accounts'];
            terrModel = [SELECT id, DeveloperName,State from Territory2Model where DeveloperName = 'Weir_Minerals'];
            insert objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId = terrModel.Id, Name='AM1_AM01_GB01', Territory2TypeId=terriType[0].Id);
        }
        
        STDPriceBookId = TestUtility.createSTDPriceBookRecords();
        mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
        mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgs[0].id, True);
        mMaterials = TestUtility.createMaterialRecords(1, 'Mat123', True);
        mNewProducts2 = TestUtility.createProductRecords(1, 'Z0003S0012CC000001', True);
        mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True); 
        mSalesOrgMaterials = TestUtility.createSalesOrgMaterialRecords(1, mMaterials[0].id, mSalesOrgs[0].id, False, True);
        mOrgStructure = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
    }
    
    @isTest static void CreateProspectAndInquiryToSAP()
    { 
        setupTestData();
        mAccounts = TestUtility.createAccountRecords1(1, null, True, True);
        mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
        mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
        mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
        mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
        mOpportunities = [SELECT Id, Name, SGTProfile__c, StageName, Integration_Status__c, Division__c, Channel__c, CloseDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity_ID__c,
                          Sales_Group__c, Sales_Office__c, Territory2Id,
                          AccountId, Account.CreatedBy.profileId, Account.Name,Account.Type, Account.Industry, Account.Industry_Code__c, Account.Phone, Account.Website,
                          Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingStateCode, Account.BillingPostalCode, Account.BillingCountry,Account.BillingCountryCode, Shipping_Address__r.ERP_ID__c,
                          Account.Account_Status__c, Account.Prospect__c, Account.ERP_Id__c, Account.CurrencyIsoCode, Sales_Organization_User__r.code__c
                          FROM Opportunity WHERE id =: mOpportunities[0].id];

        PushToSAPController.ValidateSGTProfile(mOpportunities[0].id);
        PushToSAPController.CreateProspectAndInquiryToSAP(mOpportunities);
        
        Test.setMock(WebServiceMock.class, new CalloutSAPMock());
        Boolean result  = PushToSAP.CreateProspectAccount(mOpportunities);
        System.debug('result: '+result);
        System.assertEquals(false, result); 
    }
    
    @isTest static void CreateInquiryToSAP()
    { 
        setupTestData();
        mAccounts = TestUtility.createAccountRecords1(1, 'Acc123', True, True);
        mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
        mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
        mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
        mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
        mOpportunities = [SELECT Id, Name, SGTProfile__c, StageName, Integration_Status__c, Division__c, Channel__c, CloseDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity_ID__c,
                          Sales_Group__c, Sales_Office__c, Territory2Id,        
                          AccountId, Account.CreatedBy.profileId, Account.Name,Account.Type, Account.Industry, Account.Industry_Code__c, Account.Phone, Account.Website,
                          Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingStateCode, Account.BillingPostalCode, Account.BillingCountry,Account.BillingCountryCode, Shipping_Address__r.ERP_ID__c,
                          Account.Account_Status__c, Account.Prospect__c, Account.ERP_Id__c, Account.CurrencyIsoCode, Sales_Organization_User__r.code__c
                          FROM Opportunity WHERE id =: mOpportunities[0].id];
        PushToSAPController.ValidateSGTProfile(mOpportunities[0].id);
        PushToSAPController.CreateProspectAndInquiryToSAP(mOpportunities);
    }
    
    @isTest static void CallOutProspectTest()
    { 
        setupTestData();
        mAccounts = TestUtility.createAccountRecords1(1, null, True, True);
        mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
        mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
        mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
        mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
        Test.startTest();
        Test.setMock(WebServiceMock.class, new CalloutSAPMock());
        Boolean result  = PushToSAP.CreateProspectAccount(mOpportunities);
        System.assertEquals(true, result);
        
        Boolean result1  = PushToSAP.CreateInquiry(mOpportunities, mNewOppLineItems);
        System.assertEquals(true, result1);
        
        Test.stopTest();
    }
    
}