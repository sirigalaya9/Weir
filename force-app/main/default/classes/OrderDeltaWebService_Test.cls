@isTest
private class OrderDeltaWebService_Test {
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
    static List<Order> mNewOrders;
    static List<OrderItem> mNewOrderItem ;
    static List<OrderDeltaWebService.OrderItems> mNeworderItems = new List<OrderDeltaWebService.OrderItems>();
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    static OrderDeltaWebService.AdditionalInfo mAdditionalInfo = new OrderDeltaWebService.AdditionalInfo();

    
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
            mNewOrders = TestUtility.createOrderRecords(1, mAccounts[0].id, mOpportunities[0].id, STDPriceBookId, mShipTos[0].id, 'OR1234', True);
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
            mAdditionalInfo.saleOrgCode = 'GB01';
            
            mNewOrders[0].CurrencyIsoCode = 'AUD';
            update mNewOrders;
            
            OrderItem mNewOrderItem = new OrderItem();
            mNewOrderItem.OrderId = mNewOrders.get(0).Id;
            mNewOrderItem.PricebookEntryId = mNewPricebookEntries.get(0).Id;
            mNewOrderItem.Product2Id = mNewProducts2.get(0).Id;
            mNewOrderItem.Material_Number__c = mMaterials.get(0).Id;
            mNewOrderItem.Quantity = 2;
            mNewOrderItem.UnitPrice = 10;
            mNewOrderItem.Line_Item_No__c = 10;
            insert mNeworderItem;
            
            Delivery__c delivery = new Delivery__c();
            delivery.SAP_Delivery_Order_No__c = '6000020345';
            delivery.Sales_Organization__c = 'GB01';
            delivery.Account__c = mAccounts.get(0).Id;
            delivery.SAP_Delivery_Order_No__c = 'DEV0001';
            insert delivery;
            

            Delivery_Product__c deliveryItem = new Delivery_Product__c();
            deliveryItem.DO_Item_No__c = 10;
            deliveryItem.Order_Item_No__c = 10;
            deliveryItem.Order_Product__c = mNeworderItem.Id;
            deliveryItem.Delivery__c = delivery.Id;
            insert deliveryItem;
            
            Invoice__c invoice = new Invoice__c ();
            invoice.Sales_Organization__c  = 'GB01';
            invoice.ERP_ID__c  = 'IN0001';
            insert invoice;
            
            Invoice_Item__c invoiceItem = new Invoice_Item__c();
            invoiceItem.Invoice__c = invoice.Id;
            invoiceItem.Invoice_Item_No__c = 10;
            invoiceItem.Delivery_Item__c = deliveryItem.Id;
            invoiceItem.Order_Item__c = mNeworderItem.Id;
            insert invoiceItem;
        }
        
    }
    @isTest static void OrderDeltaSuccess()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsDelta(1,mMaterials[0].Name,2,3,'Z0001S0001');
        mNeworderItems[0].lineItemNo = 10;
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderDeltaNo3rdLevel()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsDelta(1,mMaterials[0].Name,2,3,null);
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderDeltaDeleteAllItems()
    {              
        setupTestData();
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderDeltaShipToNotValidated()
    {              
        setupTestData();
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            null, mUser.ERP_Id__c, 'mShipTos[0].ERP_Id__c', System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderFail()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsDelta(1,mMaterials[0].Name,2,3,'Z0003S0012CC000003');
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode9999999999999999','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderItemNotFoundPBEntry()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsDelta(1,mMaterials[0].Name,2,3,'Z0003S0012CC000003');
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, System.today(), 
            'AUD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
    
    @isTest static void OrderItemFail()
    {              
        setupTestData();
        mNeworderItems = TestUtility.createOrderItemsDelta(1,mMaterials[0].Name,null,3,'Z0001S0001');
        Test.startTest();
        OrderDeltaWebService.Results result = OrderDeltaWebService.OrderDelta(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c, System.today(), 
            'USD','Order Description','OR1234','Y41CLNT331',
            'Street','City','QLD','PostalCode','AU', 'user123','user123',
            mAdditionalInfo,
            mNeworderItems);
        Test.stopTest();
    }
}