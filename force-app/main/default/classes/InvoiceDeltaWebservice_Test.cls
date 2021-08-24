@isTest
private class InvoiceDeltaWebservice_Test {
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
    static List<InvoiceDeltaWebservice.InvoiceItem> mNewInvoiceItems = new List<InvoiceDeltaWebservice.InvoiceItem>();
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    static List<Sales_Organization_Material__c> mSalesOrgMaterial;

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
            mSalesOrgMaterial = TestUtility.createSalesOrgMaterialRecords(1, mMaterials[0].Id, mSalesOrgs[0].id, false, true);
            
            Order ord = new Order();
            ord.Pricebook2Id = STDPriceBookId;
            ord.CurrencyIsoCode = 'AUD';
            ord.AccountId = mAccounts.get(0).Id;
            ord.Status = 'Draft';
            ord.EffectiveDate = System.today();
            ord.ERP_ID__c = 'OR0001';
            insert ord;
            
            List<OrderItem> mNeworderItems = new List<OrderItem>();
            OrderItem mNewOrderItem = new OrderItem();
            mNewOrderItem.OrderId = ord.Id;
            mNewOrderItem.PricebookEntryId = mNewPricebookEntries.get(0).Id;
            mNewOrderItem.Product2Id = mNewProducts2.get(0).Id;
            mNewOrderItem.Material_Number__c = mMaterials.get(0).Id;
            mNewOrderItem.Quantity = 2;
            mNewOrderItem.UnitPrice = 10;
            mNewOrderItem.Line_Item_No__c = 10;
            mNeworderItems.add(mNewOrderItem);
            insert mNeworderItems;
            
            Delivery__c delivery = new Delivery__c();
            delivery.SAP_Delivery_Order_No__c = '6000020345';
            delivery.Sales_Organization__c = 'GB01';
            delivery.Account__c = mAccounts.get(0).Id;
            delivery.SAP_Delivery_Order_No__c = 'DEV0001';
            insert delivery;
            
            List<Delivery_Product__c> deliveryItems = new List<Delivery_Product__c>();
            Delivery_Product__c deliveryItem = new Delivery_Product__c();
            deliveryItem.DO_Item_No__c = 10;
            deliveryItem.Order_Item_No__c = 10;
            deliveryItem.Order_Product__c = mNeworderItems.get(0).Id;
            deliveryItem.Delivery__c = delivery.Id;
            deliveryItems.add(deliveryItem);
            insert deliveryItems;
            
            InvoiceDeltaWebservice.InvoiceItem mNewInvoiceItem = new InvoiceDeltaWebservice.InvoiceItem();
            mNewInvoiceItem.invoiceLineItemNo = 10;
            mNewInvoiceItem.deliveryERPID = 'DEV0001';
            mNewInvoiceItem.doLineItemNo = 10;
            mNewInvoiceItem.orderERPID = 'OR0001';
            mNewInvoiceItem.orderLineItemNo = 10;
            mNewInvoiceItem.materialNumber = 'Mat123';
            mNewInvoiceItem.materialDescription = 'BEARING';
            mNewInvoiceItem.billedQuantity = 100;
            mNewInvoiceItem.unitPrice = 10;
            mNewInvoiceItem.netValue = 10;
            mNewInvoiceItem.charges = 2;
            mNewInvoiceItem.taxAmount = 7;
            mNewInvoiceItems.add(mNewInvoiceItem);
            
            Invoice__c invoice = new Invoice__c ();
            invoice.Sales_Organization__c  = 'GB01';
            invoice.ERP_ID__c  = 'IN0001';
            insert invoice;
            
        }
        
    }

    @isTest static void InvoiceDeltaSuccess()
    {              
        setupTestData();
        Test.startTest();
        InvoiceDeltaWebservice.Results result = InvoiceDeltaWebservice.InvoiceDelta(
            'DEV0001',mAccounts[0].ERP_Id__c,'IN0001',System.today()+1,1,'GBP','PO000',
            'EXW','Z008',11,900,mNewInvoiceItems);
        Test.stopTest();
    }
    
     @isTest static void InvoiceDeltaFail()
    {              
        setupTestData();
        Test.startTest();
        InvoiceDeltaWebservice.Results result = InvoiceDeltaWebservice.InvoiceDelta(
            'DEV0001',mAccounts[0].ERP_Id__c,'IN0001',System.today()+1,1,'GBP','PO000',
            'EXW','Z00999',11,900,mNewInvoiceItems);
        Test.stopTest();
    }
}