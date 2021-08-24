@isTest
public class OpportunityTrigger_Test {
    static List<Account> mAccounts;
    static User mUser;
    static Project__c mProject;
    static List<Address__c> mShipTos;
    static List<Sales_Organization__c> mSalesOrgsGB01;
    static List<Sales_Organization__c> mSalesOrgsAU01;
    static List<Sales_Organization_User__c> mSalesOrgUsers;
    static List<Sales_Organization_User__c> mSalesOrgUsersGB01;
    static List<Sales_Organization_User__c> mSalesOrgUsersAU01;
    static List<Sales_Organization_Material__c> mSalesOrgMaterials;
    static Opportunity mOpportunities;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static Id STDPriceBookId;
    static List<Organization_Structure__c> mOrgStructure00;
    static List<Organization_Structure__c> mOrgStructure01;
    static List<Sales_Area_Detail__c> mSalesArea00;
    static List<Sales_Area_Detail__c> mSalesArea01;
    static List<Territory2Type> terriType;
    static List<Material_Number__c> mMaterials;
    static List<Product2> mNewProducts2;
    Static List<PricebookEntry> mNewPricebookEntries;
    static List<OpportunityLineItem> mNewOppLineItems;
    static List<Quote> mNewQuote;
    static List<QuoteLineItem> mNewQuoteItems;
    static Id OpportunitySGTRecordTypeId;
    static Id OpportunityStandaloneRecordTypeId;
    
    static void setupTestData()
    {
        Profile mProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Person']; 
        insert mUser = new User(Alias = 'standt', Email='Integration@testorg.com', 
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                         LocaleSidKey='en_US', ProfileId = mProfile.Id, 
                         TimeZoneSidKey='America/Los_Angeles', UserName='Integration@testorg.com', ERP_Id__c = 'user123');
        
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
        
        OpportunitySGTRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
        OpportunityStandaloneRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standalone_Record_Type').getRecordTypeId ();

        STDPriceBookId = TestUtility.createSTDPriceBookRecords();
        mAccounts = TestUtility.createAccountRecords(1, True);
        mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
        mSalesOrgsGB01 = TestUtility.createSalesOrgRecords(1, 'GB01', True);
        mSalesOrgsAU01 = TestUtility.createSalesOrgRecords(1, 'AU01', True);
        mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, mUser.Id, mSalesOrgsGB01[0].id, True);
        mOrgStructure00 = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
        mOrgStructure01 = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '01', True, objTerr.Id, True);
        mSalesArea00 = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure00[0].id, True);
        mSalesArea01 = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure01[0].id, True);
        mMaterials = TestUtility.createMaterialRecords(2, 'Mat123', True);
        mNewProducts2 = TestUtility.createProductRecords(1, 'Z0001S0001', True);
        mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
        insert mProject = new Project__c(Name='Project Name', Account__c = mAccounts[0].id, Total_Opportunity_Sum__c = 0, CurrencyISOCode = 'AUD');
        insert mOpportunities = new Opportunity(Name='Opportunity Name',StageName='Qualification', Project__c= mProject.id,Publish_to_Forecast__c = True,
                                         CloseDate=System.today().addMonths(1),AccountId=mAccounts[0].Id, CurrencyISOCode = 'AUD',Division__c = '00', Channel__c = '30',
                                         Sales_Organization_User__c = mSalesOrgUsers[0].id , OwnerId = mUser.Id);
    }
    
    @isTest static void UpdateCloseDate()
    {              
        setupTestData();
        mNewQuote = TestUtility.createQuoteRecords(1, mOpportunities.Id, STDPriceBookId, null, 'ERPID000', True);
        mNewQuoteItems = TestUtility.createQuoteLineItemRecords(1, mNewQuote[0].Id, mNewProducts2[0].Id, mNewPricebookEntries[0].Id, True);
        Test.startTest();
        Test.setMock(WebServiceMock.class, new CalloutSAPMock());
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, SyncedQuoteId = mNewQuote[0].Id, CloseDate = System.today());
            update opp;
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('not found');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateOpportunityOwnerSuccess()
    {              
        setupTestData();
        List<Sales_Organization_User__c> mSalesOrgUsersGB01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsGB01[0].id, True);
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, OwnerId = UserInfo.getUserId());
            update opp;
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('not found');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateOpportunityOwnerError()
    {              
        setupTestData();
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, OwnerId = UserInfo.getUserId());
            update opp;
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('not found');
            System.AssertEquals(expectedExceptionThrown, false);
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateOpportunityOwnerHasMultiSalesOrg()
    {              
        setupTestData();
        mSalesOrgUsersGB01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsGB01[0].id, True);
        mSalesOrgUsersAU01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsAU01[0].id, True);
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, OwnerId = UserInfo.getUserId(), Sales_Organization_User__c = null, ERP_Id__c = '0434324');
            update opp;
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('not found');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateOpportunityOwnerHasMultiSalesOrgWithERPIdNull()
    {              
        setupTestData();
        mSalesOrgUsersGB01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsGB01[0].id, True);
        mSalesOrgUsersAU01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsAU01[0].id, True);
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, OwnerId = UserInfo.getUserId(), Sales_Organization_User__c = null);
            update opp;
        }
        catch(Exception e) 
        {
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateOpportunityOwnerHasOneOrg()
    {              
        setupTestData();
        mSalesOrgUsersAU01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsAU01[0].id, True);
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, OwnerId = UserInfo.getUserId(), Sales_Organization_User__c = null);
            update opp;
        }
        catch(Exception e) 
        {
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateOpportunityClone()
    {              
        setupTestData();
        mSalesOrgUsersGB01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsGB01[0].id, True);
        mSalesOrgUsersAU01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsAU01[0].id, True);
        Test.startTest();
        
        insert mOpportunities = new Opportunity(Name='Opportunity Name1',StageName='Qualification', Project__c= mProject.id,Publish_to_Forecast__c = True,
                                         CloseDate=System.today().addMonths(1),AccountId=mAccounts[0].Id, CurrencyISOCode = 'AUD',Division__c = '00', Channel__c = '30',
                                         Sales_Organization_User__c = null , OwnerId = UserInfo.getUserId());
        
        Opportunity clonedopp = mOpportunities.clone(false, false, false, false);
        insert clonedopp;
        Test.stopTest();
    }
    
    
    /*@isTest static void UpdateSalesOrg()
    {              
        setupTestData();
        mSalesOrgUsersAU01 = TestUtility.createSalesOrgUserRecords(1, UserInfo.getUserId(), mSalesOrgsAU01[0].id, True);
        mMaterials = TestUtility.createMaterialRecords(1, 'Mat123', True);
        mNewProducts2 = TestUtility.createProductRecords(1, 'Z0003S0012CC000001', True);
        mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
        mSalesOrgMaterials = TestUtility.createSalesOrgMaterialRecords(1, mMaterials[0].id, mSalesOrgsGB01[0].id, False, True);
        mNewOppLineItems = TestUtility.createOpportunityItemRecords(1,mOpportunities.id,mNewProducts2[0].id,mNewPricebookEntries[0].id, mMaterials[0].id, True);
        
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, Sales_Organization_User__c = mSalesOrgUsersAU01[0].id);
            update opp;
        }
        catch(Exception e) 
        {
        } 
        Test.stopTest();
    }*/
    
    @isTest static void UpdateOpportunityCurrency()
    {              
        setupTestData();
        Test.startTest();
        Project__c mProject1 = new Project__c(Name='Project1', Account__c = mAccounts[0].id, Total_Opportunity_Sum__c = 0, CurrencyISOCode = 'GBP');
        Opportunity mOpp = [Select Id, Name, CurrencyISOCode, Publish_to_Forecast__c, Amount, Project__c from Opportunity where id =: mOpportunities.id];
        mOpp.CurrencyISOCode = 'GBP';
        update mOpp;
        Test.stopTest();
    }
       
    @isTest static void CreateOpportunitySGTError()
    {              
        setupTestData();
        Test.startTest();
        try
        {
            insert mOpportunities = new Opportunity(Name='Opportunity Name',StageName='Qualification', Project__c= mProject.id,Publish_to_Forecast__c = True,
                                                    CloseDate=System.today().addMonths(1),AccountId=mAccounts[0].Id, CurrencyISOCode = 'AUD',Division__c = '00', Channel__c = '10',
                                                    Sales_Organization_User__c = mSalesOrgUsers[0].id , OwnerId = mUser.Id, RecordTypeId = OpportunitySGTRecordTypeId);
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('not found');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateDivisionError()
    {              
        setupTestData();
        Test.startTest();
        try
        {
            Opportunity Opp = new Opportunity(Id = mOpportunities.id, Division__c = '02');
            update opp;
        }
        catch(Exception e) 
        {
            Boolean expectedExceptionThrown =  e.getMessage().contains('not found');
            System.AssertEquals(expectedExceptionThrown, true);
        } 
        Test.stopTest();
    }
    
    @isTest static void UpdateDivisionSuccessful()
    {              
        setupTestData();
        Test.startTest();
        
        Opportunity Opp = new Opportunity(Id = mOpportunities.id, Division__c = '01');
        update opp;
        
        Test.stopTest();
    }

}