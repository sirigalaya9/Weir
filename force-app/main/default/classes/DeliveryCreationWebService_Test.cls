@isTest
private class DeliveryCreationWebService_Test {
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
    static List<DeliveryCreationWebService.DeliveryItem> mNewDeliveryItems = new List<DeliveryCreationWebService.DeliveryItem>();
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
                        
            DeliveryCreationWebService.DeliveryItem mNewDeliveryItem = new DeliveryCreationWebService.DeliveryItem();
            mNewDeliveryItem.doLineItemNo = 10;
            mNewDeliveryItem.orderLineItemNo = 10;
            mNewDeliveryItem.orderERPID = 'OR0001';
            mNewDeliveryItem.materialNumber = 'Mat123';
            mNewDeliveryItem.deliveryQuantity = 1;
            mNewDeliveryItem.uom = 'EA';
            mNewDeliveryItem.netWeight = 11;
            mNewDeliveryItem.grossWeight = 100;
            mNewDeliveryItem.weightUnit = 'KGM';
            mNewDeliveryItem.pickingStatus = 'A';
            mNewDeliveryItem.packingStatus = 'A';
            mNewDeliveryItem.materialDescription = 'BEARING';
            mNewDeliveryItems.add(mNewDeliveryItem);
            
        }
        
    }

    @isTest static void DeliveryCreationSuccess()
    {              
        setupTestData();
        Test.startTest();
        DeliveryCreationWebService.Results result = DeliveryCreationWebService.DeliveryCreation(
            'DEV0001','Track001',System.today(),System.today()+1,System.today(),System.today(),System.today(),
            'Street','City','QLD','PostalCode','AU',mAccounts[0].ERP_Id__c, 
            'A','',System.today()+10,System.today()+11,'GB01','carrierName', mShipTos[0].ERP_Id__c,
            mNewDeliveryItems);
        Test.stopTest();
    }
    
    @isTest static void CannotFindOrderItem()
    {              
        setupTestData();
        mNewDeliveryItems[0].orderLineItemNo = 20;
        Test.startTest();
        DeliveryCreationWebService.Results result = DeliveryCreationWebService.DeliveryCreation(
            'DEV0001','Track001',System.today(),System.today()+1,System.today(),System.today(),System.today(),
            'Street','City','QLD','PostalCode','AU',mAccounts[0].ERP_Id__c, 
            'A','',System.today()+10,System.today()+11,'GB01','carrierName', mShipTos[0].ERP_Id__c,
            mNewDeliveryItems);
        Test.stopTest();

    }
    
    @isTest static void CannotFindOrderERPID()
    {              
        setupTestData();
        mNewDeliveryItems[0].orderERPID = 'OR0002';
        
        Test.startTest();
        DeliveryCreationWebService.Results result = DeliveryCreationWebService.DeliveryCreation(
            'DEV0001','Track001',System.today(),System.today()+1,System.today(),System.today(),System.today(),
            'Street','City','QLD','PostalCode','AU',mAccounts[0].ERP_Id__c, 
            'A','',System.today()+10,System.today()+11,'GB01','carrierName', mShipTos[0].ERP_Id__c,
            mNewDeliveryItems);
        Test.stopTest();

    }   
}