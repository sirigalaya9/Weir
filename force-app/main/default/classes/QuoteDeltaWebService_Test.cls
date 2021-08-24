@isTest
private class QuoteDeltaWebService_Test {
    static List<Account> mAccounts;
    static User mUser;
    static List<Address__c> mShipTos;
    static List<Sales_Organization__c> mSalesOrgs;
    static List<Sales_Organization_User__c> mSalesOrgUsers;
    static List<Opportunity> mOpportunities;
    static List<Material_Number__c> mMaterials;
    static List<String> materialNumbers = new List<String>();
    static List<Product2> mNewProducts2;
    Static List<PricebookEntry> mNewPricebookEntries;
    Static List<PricebookEntry> mNewPricebookEntriesUSD;
    static List<Quote> mNewQuotes;
    static List<Quote> mNewQuotes2;
    static List<QuoteLineItem> mNewQuoteLineItems ;
    static List<QuoteDeltaWebService.QuoteItems> mNewQuoteItems;
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    static QuoteDeltaWebService.AdditionalInfo mAdditionalInfo = new QuoteDeltaWebService.AdditionalInfo();
    
    static void setupTestData(){
        
        Profile mProfile = [SELECT Id FROM Profile WHERE Name = 'Integration']; 
        insert mUser = new User(Alias = 'standt', Email='Integration+Weir@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = mProfile.Id, Division = 'ENAR',
                                TimeZoneSidKey='America/Los_Angeles', UserName='Integration+Weir@testorg.com', ERP_Id__c = 'user123');
        
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
            mNewQuotes = TestUtility.createQuoteRecords(1, mOpportunities[0].id, STDPriceBookId, mShipTos[0].id, 'QT1234', True);
            mNewQuoteItems = TestUtility.createQuoteItemsDelta(1,mMaterials[0].Name,2,5,'Z0001');
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
            mNewQuotes = TestUtility.createQuoteRecords(1, mOpportunities[0].id, STDPriceBookId, mShipTos[0].id, 'QT1234', True);
            mNewQuoteItems = TestUtility.createQuoteItemsDelta(1,mMaterials[0].Name,2,5,'Z0001');
            mAdditionalInfo.application = 'Z07';
            mAdditionalInfo.integratedSolution = 'YES';
            mAdditionalInfo.otherStrategicInitiatives = '01';
            mAdditionalInfo.important = true;
            mAdditionalInfo.managedByProjectTeams =true;

        }
        Test.startTest();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mIntegrationUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c, 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteDeltaChangeCurrency()
    {              
        setupTestData();
        Order order = new Order(quoteId = mNewQuotes[0].id,opportunityId = mOpportunities[0].id, accountId = mAccounts[0].Id, EffectiveDate= system.today(), status = 'draft');
        insert order;
        QuoteLineItem mNewQuoteLineItems = new QuoteLineItem(quoteId = mNewQuotes[0].id,Material_Number__c = mMaterials[0].id, quantity =1, UnitPrice = 100, PricebookEntryId = mNewPricebookEntries[0].id);
        insert mNewQuoteLineItems;
        mNewPricebookEntriesUSD = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'USD', True);
        List<Quote> mNewQuotes2 = TestUtility.createQuoteRecords(1, mOpportunities[0].id, STDPriceBookId, mShipTos[0].id, 'QT12345', True);
        QuoteLineItem mNewQuoteLineItems2 = new QuoteLineItem(quoteId = mNewQuotes2[0].id,Material_Number__c = mMaterials[0].id, quantity =1, UnitPrice = 100, PricebookEntryId = mNewPricebookEntries[0].id);
        insert mNewQuoteLineItems2;
        Opportunity oppToUpdate = new Opportunity(Id = mOpportunities[0].id, SyncedQuoteId = mNewQuotes[0].id);
        update oppToUpdate;
        
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c, 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'USD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
        @isTest static void QuoteDeltaChangeCurrencyNotFoundPBEntry()
    {              
        setupTestData();
        QuoteLineItem mNewQuoteLineItems = new QuoteLineItem(quoteId = mNewQuotes[0].id,Material_Number__c = mMaterials[0].id, quantity =1, UnitPrice = 100, PricebookEntryId = mNewPricebookEntries[0].id);
        insert mNewQuoteLineItems;
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c, 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'USD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteDeltaActive()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c, 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteDeltaNotActive()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c , 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Draft','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteNotFound()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c , 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT9999','Draft','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void OpportunityUpdateFail()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c , 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Draft','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteItemNotFoundPBEntry()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        mNewQuoteItems = TestUtility.createQuoteItemsDelta(1,mMaterials[0].Name,2,3,'Z0003S0012CC000003');
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c , 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteItemInsertFail()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        mNewQuoteItems = TestUtility.createQuoteItemsDelta(1,mMaterials[0].Name,null,3,'Z0003S0012CC000001');
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c , 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
    
    @isTest static void QuoteUpdateFail()
    {              
        setupTestData();
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteDeltaWebService.Results result = QuoteDeltaWebService.QuoteDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, opp.Opportunity_ID__c , 'Qualification', 'Not Applicable', 'GB01','AM01','AM1', System.today(), 
            'AUD','30','00', System.today(),System.today(),System.today(),
            'QT1234','Active','Y41CLNT331','Street','City','QLD','PostalCode9999999999999999','AU','user123', mAdditionalInfo,mNewQuoteItems);
        Test.stopTest();
    }
}