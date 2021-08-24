@isTest
private class OrderCreationWebService_Test {
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
    static List<Quote> mNewQuotes;
    static List<QuoteLineItem> mNewQuoteLineItems ;
    static List<OrderCreationWebService.OrderItems> mNeworderItems = new List<OrderCreationWebService.OrderItems>();
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    static List<Sales_Organization_Material__c> mSalesOrgMaterial;
    static OrderCreationWebService.AdditionalInfo mAdditionalInfo = new OrderCreationWebService.AdditionalInfo();

    
    static void setupTestData(){
        
        Profile mProfile = [SELECT Id FROM Profile WHERE Name = 'Integration']; 
        insert mUser = new User(Alias = 'standt', Email='Integration@testorg.com', 
                         EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                         LocaleSidKey='en_US', ProfileId = mProfile.Id, 
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
            mNewProducts2 = TestUtility.createProductRecords(1, 'Z0001S0001', True);
            mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
            mNewQuotes = TestUtility.createQuoteRecords(1, mOpportunities[0].id, STDPriceBookId, mShipTos[0].id, 'QT1234', True);
            mNeworderItems = TestUtility.createOrderItemsCreate(1,mMaterials[0].Name,2,5,'Z0001S0001');
            mSalesOrgMaterial = TestUtility.createSalesOrgMaterialRecords(1, mMaterials[0].Id, mSalesOrgs[0].id, false, true);
            mAdditionalInfo.orderType = 'OR';
            mAdditionalInfo.saleOrgCode = 'GB01';
            mAdditionalInfo.salesOffice = 'AM01';
            mAdditionalInfo.salesGroup = 'AM1';
            mAdditionalInfo.oppCloseDate = System.today();
            mAdditionalInfo.oppCurrency = 'AUD';
            mAdditionalInfo.oppDistributionChannel = '30';
            mAdditionalInfo.division = '00';
            mAdditionalInfo.oppBidDueDate = System.today();
            mAdditionalInfo.expectedDeliveryDate = System.today();
            mAdditionalInfo.inquiryReceivedDate = System.today();
            mAdditionalInfo.quotedDate = System.today();
            mAdditionalInfo.shippingCondition = '01';
            mAdditionalInfo.incoterm1 = 'AIR';
            mAdditionalInfo.incoterm2 = 'Test';
            mAdditionalInfo.paymentTerm = '0001';
            mAdditionalInfo.quotedMargin = 1;
            mAdditionalInfo.application = 'Z07';
            mAdditionalInfo.integratedSolution = 'YES';
            mAdditionalInfo.otherStrategicInitiatives = '01';
            mAdditionalInfo.important = true;
            mAdditionalInfo.managedByProjectTeams = true;
            mAdditionalInfo.orderCreatedDate = System.today();
            mAdditionalInfo.orderReceptionDate = System.today();
            mAdditionalInfo.requestedDeliveryDate = System.today();
            mAdditionalInfo.customerPONumber = '12334';
            mAdditionalInfo.onHold = true;
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
            mNewProducts2 = TestUtility.createProductRecords(1, 'Z0001S0001', True);
            mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
            mNewQuotes = TestUtility.createQuoteRecords(1, mOpportunities[0].id, STDPriceBookId, mShipTos[0].id, 'QT1234', True);
            mNeworderItems = TestUtility.createOrderItemsCreate(1,mMaterials[0].Name,2,5,'Z0001S0001');
            mSalesOrgMaterial = TestUtility.createSalesOrgMaterialRecords(1, mMaterials[0].Id, mSalesOrgs[0].id, false, true);
            mAdditionalInfo.orderType = 'OR';
            mAdditionalInfo.saleOrgCode = 'GB01';
            mAdditionalInfo.salesOffice = 'AM01';
            mAdditionalInfo.salesGroup = 'AM1';
            mAdditionalInfo.oppCloseDate = System.today();
            mAdditionalInfo.oppCurrency = 'AUD';
            mAdditionalInfo.oppDistributionChannel = '30';
            mAdditionalInfo.division = '00';
            mAdditionalInfo.oppBidDueDate = System.today();
            mAdditionalInfo.expectedDeliveryDate = System.today();
            mAdditionalInfo.inquiryReceivedDate = System.today();
            mAdditionalInfo.quotedDate = System.today();
            mAdditionalInfo.shippingCondition = '01';
            mAdditionalInfo.incoterm1 = 'AIR';
            mAdditionalInfo.incoterm2 = 'Test';
            mAdditionalInfo.paymentTerm = '0001';
            mAdditionalInfo.quotedMargin = 1;
            mAdditionalInfo.application = 'Z07';
            mAdditionalInfo.integratedSolution = 'YES';
            mAdditionalInfo.otherStrategicInitiatives = '01';
            mAdditionalInfo.important = true;
            mAdditionalInfo.managedByProjectTeams = true;
            mAdditionalInfo.orderCreatedDate = System.today();
            mAdditionalInfo.orderReceptionDate = System.today();
            mAdditionalInfo.requestedDeliveryDate = System.today();
            mAdditionalInfo.customerPONumber = '12334';

        }
        Test.startTest();
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mIntegrationUser.ERP_Id__c, mShipTos[0].ERP_Id__c,qt.Quote_ID__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU','user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
        
    @isTest static void OrderItemNotFoundPBEntry()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsCreate(1,mMaterials[0].Name,2,3,'Z0003S0012CC000003');
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        Test.startTest();
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,qt.Quote_ID__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderItemFail()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsCreate(1,mMaterials[0].Name,null,3,'Z0001S0001');
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        Test.startTest();
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,qt.Quote_ID__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }

    @isTest static void ZOR_OrderCreationSuccess()
    {              
        setupTestData();
        mAdditionalInfo.orderType = 'ZOR';
        Test.startTest();
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, null, System.today()+1, 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name = 'ECC - OR1234'];
        //System.assertEquals(0, opps.size(), '0 Opp has to be created');
    }
    
    @isTest static void OR_OrderCreationSuccess()
    {              
        setupTestData();
        mAdditionalInfo.orderType = 'OR';
        //mAdditionalInfo.oppCurrency = 'AUDXXXX';
        Test.startTest();
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,qt.Quote_ID__c, System.today()+1, 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name = 'ECC - OR1234'];
        //System.assertEquals(0, opps.size(), '0 Opp has to be created');
    }
    
    @isTest static void OR_OrderCreationFail()
    {              
        setupTestData();
        mAdditionalInfo.orderType = 'OR';
        Test.startTest();
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,qt.Quote_ID__c, System.today()-1, 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name = 'ECC - OR1234'];
        //System.assertEquals(0, opps.size(), '0 Opp has to be created');
    }
    
    @isTest static void UpdatePH()
    {              
        setupTestData();
        mAdditionalInfo.orderType = 'ZOR';
        mNeworderItems[0].thirdLevelHierarchy = null;
        Test.startTest();
        Quote qt = [SELECT Id, Quote_ID__c FROM Quote Where id =: mNewQuotes[0].id];
        OrderCreationWebService.Results result = OrderCreationWebService.OrderCreation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c,qt.Quote_ID__c, System.today()-1, 
            'AUD','Order Description','OR1234','Y41CLNT331', 'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE Name = 'ECC - OR1234'];
        //System.assertEquals(0, opps.size(), '0 Opp has to be created');
    }    
}