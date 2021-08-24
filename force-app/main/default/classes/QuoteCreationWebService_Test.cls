@isTest
private class QuoteCreationWebService_Test {
    static List<Account> mAccounts;
    static User mUser;
    static List<Address__c> mShipTos;
    static List<Sales_Organization__c> mSalesOrgs;
    static List<Sales_Organization_User__c> mSalesOrgUsers;
    static List<Opportunity> mOpportunities;
    static List<Material_Number__c> mMaterials;
    static List<Product2> mNewProducts2;
    Static List<PricebookEntry> mNewPricebookEntries;
    static List<QuoteCreationWebService.QuoteItems> mNewQuoteItems = new List<QuoteCreationWebService.QuoteItems>();
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    static QuoteCreationWebService.AdditionalInfo mAdditionalInfo = new QuoteCreationWebService.AdditionalInfo();
    
    static void setupTestData(){
        
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
        
        System.runAs(mUser) 
        {
            STDPriceBookId = TestUtility.createSTDPriceBookRecords();
            mAccounts = TestUtility.createAccountRecords(1, True);
            mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
            mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
            mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, mUser.Id, mSalesOrgs[0].id, True);
            mOrgStructure = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
            mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
            mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
            mMaterials = TestUtility.createMaterialRecords(2, 'Mat123', True);
            mNewProducts2 = TestUtility.createProductRecords(1, 'Z0001', True);
            mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
            mNewQuoteItems = TestUtility.createQuoteItemsCreate(1,mMaterials[0].Name,2,5,'Z0001');
            //mAdditionalInfo = new QuoteCreationWebService.AdditionalInfo();
            mAdditionalInfo.application = 'Z07';
            mAdditionalInfo.integratedSolution = 'YES';
            mAdditionalInfo.otherStrategicInitiatives = '01';
            mAdditionalInfo.important = true;
            mAdditionalInfo.managedByProjectTeams =true;

        }
        
    }
    
    
    @isTest static void DefaultOwner()
    {              
        Profile mProfile = [SELECT Id FROM Profile WHERE Name = 'Integration']; 
        User mIntegrationUser = new User(Alias = 'standt', Email='Integration1@testorg.com', 
                                EmailEncodingKey='UTF-8', FirstName = 'Integration', LastName='User', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = mProfile.Id, Division = 'ENAR',
                                TimeZoneSidKey='America/Los_Angeles', UserName='Integration1@testorg.com', ERP_Id__c = 'user1234');
        insert mIntegrationUser;
        
        System.runAs (new User(Id = UserInfo.getUserId())){
            terriType = [SELECT id, DeveloperName from Territory2Type where DeveloperName = 'Managed_Accounts'];
            terrModel = [SELECT id, DeveloperName,State from Territory2Model where DeveloperName = 'Weir_Minerals'];
            insert objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId = terrModel.Id, Name='AM1_AM01_GB01', Territory2TypeId=terriType[0].Id);
        }
        
        System.runAs(mIntegrationUser) 
        {
            STDPriceBookId = TestUtility.createSTDPriceBookRecords();
            mAccounts = TestUtility.createAccountRecords(1, True);
            mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
            mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
            mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, mIntegrationUser.Id, mSalesOrgs[0].id, True);
            mOrgStructure = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
            mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
            mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
            mMaterials = TestUtility.createMaterialRecords(2, 'Mat123', True);
            mNewProducts2 = TestUtility.createProductRecords(1, 'Z0001', True);
            mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
            mNewQuoteItems = TestUtility.createQuoteItemsCreate(1,mMaterials[0].Name,2,5,'Z0001');
            //mAdditionalInfo = new QuoteCreationWebService.AdditionalInfo();
            mAdditionalInfo.application = 'Z07';
            mAdditionalInfo.integratedSolution = 'YES';
            mAdditionalInfo.otherStrategicInitiatives = '01';
            mAdditionalInfo.important = true;
            mAdditionalInfo.managedByProjectTeams =true;

        }
        Test.startTest();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mIntegrationUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c,'GB01','AM01','AM1', System.today(), 
            'US','30','00', System.today(), System.today(),  System.today(), System.today(), 
            'QT0006', 'QT','Y41CLNT331','Active', 'Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QTChangeCurrency()
    {              
        setupTestData();
        Test.startTest();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c,'GB01','AM01','AM1', System.today(), 
            'US','30','00', System.today(), System.today(),  System.today(), System.today(), 
            'QT0006', 'QT','Y41CLNT331','Active', 'Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void ZQTDirectQuoteCreation()
    {              
        setupTestData();
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,null,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(), System.today(), System.today(), 
            'QT0006', 'ZQT','Y41CLNT331','Active', 'Street','Brisbane','QLD','4000','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QTInDirectQuoteCreation()
    {              
        setupTestData();
        Test.startTest();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(),  System.today(), System.today(), 
            'QT0006', 'QT','Y41CLNT331','Active', 'Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QTInDirectQuoteNoOpportunityId()
    {              
        setupTestData();
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, null,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(),  System.today(), System.today(), 
            'QT0006', 'QT','Y41CLNT331','Active', 'Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void OpportunityCreationFail()
    {              
        setupTestData();
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,null,'GB01','AM01','AM1', System.today(), 
            'AUD123','Domestic123','Product123', System.today(), System.today(),System.today(), System.today(), 
            'QT0006', 'ZQT','Y41CLNT331','Active', 'Street','City','QLD','PostalCode','AU', 'user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void ZQTQuoteCreationFail()
    {              
        setupTestData();
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,null,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(), System.today(), System.today(), 
            'QT0006', 'ZQT','Y41CLNT331','Active', 'Street','City','QLD','PostalCode9999999999999999','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void ZQTQuoteStatusNotActive()
    {              
        setupTestData();
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,null,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(), System.today(), System.today(), 
            'QT0006', 'ZQT','Y41CLNT331','Lost','Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void ZQTQuoteItemNotFoundPBEntry()
    {              
        setupTestData();
        mNewQuoteItems = TestUtility.createQuoteItemsCreate(1,mMaterials[0].Name,2,3,'Z0003S0012CC000003');
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,'OppRefId','GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(), System.today(), System.today(), 
            'QT0006', 'ZQT','Y41CLNT331','Lost','Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QTQuoteItemNotFoundPBEntry()
    {              
        setupTestData();
        mNewQuoteItems = TestUtility.createQuoteItemsCreate(1,mMaterials[0].Name,2,3,'Z0003S0012CC000003');
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(), System.today(), System.today(), 
            'QT0006', 'QT','Y41CLNT331','Lost','Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QTQuoteItemFail()
    {              
        setupTestData();
        mNewQuoteItems = TestUtility.createQuoteItemsCreate(1,mMaterials[0].Name,null,3,'Z0003S0012CC000001');
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteCreationWebService.Results result = QuoteCreationWebService.DirectQuoteCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c,'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(), System.today(), System.today(), System.today(), 
            'QT0006', 'QT','Y41CLNT331','Lost','Street','City','QLD','PostalCode','AU','user123','user123',mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
}