@isTest
public class OpportunityLineItemTrigger_Test {
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
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    
    static void setupTestData(){
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Data Administrator'];
        mUser = new User(Alias = 'standt', Email='dataadministrator@testorg.com',
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                         LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',UserName='dataadministrator@testorg.com', ERP_Id__c = 'dataadmin123');
        
        System.runAs (new User(Id = UserInfo.getUserId())){
            terriType = [SELECT id, DeveloperName from Territory2Type where DeveloperName = 'Managed_Accounts'];
            terrModel = [SELECT id, DeveloperName,State from Territory2Model where DeveloperName = 'Weir_Minerals'];
            insert objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId = terrModel.Id, Name='AM1_AM01_GB01', Territory2TypeId=terriType[0].Id);
        }
        
        Opp_Transfer_Owner__c setting = new Opp_Transfer_Owner__c();
        setting.Name = 'Test Setting';
        setting.Non_SGT_Profile__c = true;
        setting.SGT_Profile__c = true;
        insert setting;
        
        System.runAs (mUser)
        {
            STDPriceBookId = TestUtility.createSTDPriceBookRecords();
            mAccounts = TestUtility.createAccountRecords(1, True);
            mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
            mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
            mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgs[0].id, True);
            mOrgStructure = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
            mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
            mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
            mMaterials = TestUtility.createMaterialRecords(1, 'Mat123', True);
            mNewProducts2 = TestUtility.createProductRecords(1, 'Z0001S0001', True);
            mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
            mSalesOrgMaterials = TestUtility.createSalesOrgMaterialRecords(1, mMaterials[0].id, mSalesOrgs[0].id, False, True);
        }
    }
    
    @isTest static void MaterailValidated()
    { 
        setupTestData();
        List<Product2> mNewProducts3 = TestUtility.createProductRecords(1, 'Z0002S0002VA000001', True);
        List<PricebookEntry> mNewPricebookEntries3 = TestUtility.createPricebookEntryRecords(1, mNewProducts3[0].Id, STDPriceBookId,'AUD', True);
        mSalesOrgMaterials[0].Distribution_Channel__c = '30';
        update mSalesOrgMaterials;
        mMaterials[0].X3rd_Level_Product_Hierarchy__c = 'Z0002S0002VA000001';
        mMaterials[0].Material_Status__c = 'Active';
        update mMaterials;
        System.runAs (mUser)
        {
            mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
        }
    }
    
    @isTest static void MaterailDeleted()
    { 
        setupTestData();
        try
        {
            mSalesOrgMaterials[0].Deletion__c = true;
            mSalesOrgMaterials[0].Distribution_Channel__c = '30';
            update mSalesOrgMaterials;
            System.runAs (mUser)
            {
                mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
            }
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('blocked');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    }
    
    @isTest static void MaterailNotExtendtoSalesOrg()
    { 
        setupTestData();
        try
        {
            List<Material_Number__c> mMaterials1 = TestUtility.createMaterialRecords(1, 'Mat1234', True);
            System.runAs (mUser)
            {
                mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials1[0].id, True);
            }
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('is not extended');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    }
    
    @isTest static void SalesOrgUserisEmpty()
    { 
        setupTestData();
        try
        {
            mOpportunities[0].Sales_Organization_User__c = null;
            update mOpportunities;
            mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities[0].id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('Please enter');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
    }
    
}