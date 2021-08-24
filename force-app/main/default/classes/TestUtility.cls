@isTest
public class TestUtility {
    private static Id AccountSGTRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
    private static Id OpportunitySGTRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
    private static Id OpportunityStandaloneRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Standalone_Record_Type').getRecordTypeId ();
    
    public static List<Account> createAccountRecords(Integer mNum, Boolean isInsert)
    {
        List<Account> mNewAccountList = new List<Account>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Account mNewAccount = new Account();
            mNewAccount.Name = 'Test Account 00' + i;
            mNewAccount.ERP_Id__c = 'Acc123'+i;
            mNewAccount.Prospect__c = True;
            mNewAccount.BillingStreet = 'Street';
            mNewAccount.BillingCity = 'KL';
            mNewAccount.BillingStateCode = 'QLD';
            mNewAccount.BillingPostalCode = '12334'; 
            mNewAccount.BillingCountryCode = 'AU';
            mNewAccount.Non_Trading__c = false;
            mNewAccount.RecordTypeId = AccountSGTRecordTypeId;
            mNewAccountList.add(mNewAccount);
        }
        
        if(isInsert == True)
        {
            insert mNewAccountList;
        }
        
        return mNewAccountList;
    }
    
    public static List<Account> createAccountRecords1(Integer mNum, String AccountERPID,Boolean isProspect,Boolean isInsert)
    {
        List<Account> mNewAccountList = new List<Account>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Account mNewAccount = new Account();
            mNewAccount.Name = 'Test 12' + i;
            mNewAccount.ERP_Id__c = AccountERPID;
            mNewAccount.Prospect__c = isProspect;
            mNewAccount.Industry = 'Energy';
            mNewAccount.Industry_Code__c = 'IRON ORES';
            mNewAccount.Type = 'End User';
            mNewAccount.Phone = '00012234044';
            mNewAccount.Website = 'Account@Test.com';
            mNewAccount.CurrencyIsoCode = 'AUD';
            mNewAccount.BillingStreet = 'Street';
            mNewAccount.BillingCity = 'KL';
            mNewAccount.BillingStateCode = 'QLD';
            mNewAccount.BillingPostalCode = '14'; 
            mNewAccount.BillingCountryCode = 'AU';
            mNewAccount.Non_Trading__c = false;
            mNewAccount.RecordTypeId = AccountSGTRecordTypeId;
            mNewAccountList.add(mNewAccount);
        }
        
        if(isInsert == True)
        {
            insert mNewAccountList;
        }
        
        return mNewAccountList;
    }
    
    public static List<Address__c> createShippingRecords(Integer mNum, Id AccountId,Boolean isInsert)
    {
        List<Address__c> mShippingList = new List<Address__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Address__c mNewShipping = new Address__c();
            mNewShipping.Account__c = AccountId;
            mNewShipping.Street__c = 'Street';
            mNewShipping.City__c = 'KL';
            mNewShipping.State_Code__c = 'QLD';
            mNewShipping.PostalCode__c = '10269';
            mNewShipping.Country_Code__c = 'AU';
            mNewShipping.ERP_ID__c = 'ship123'+1;
            mShippingList.add(mNewShipping);
        }
        
        if(isInsert == True)
        {
            insert mShippingList;
        }
        
        return mShippingList;
    }
    
    public static List<Sales_Organization__c> createSalesOrgRecords(Integer mNum, String SalesOrgCode, Boolean isInsert)
    {
        List<Sales_Organization__c> mSalesOrgList = new List<Sales_Organization__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Sales_Organization__c mNewSalesOrg = new Sales_Organization__c();
            mNewSalesOrg.Name = 'WM SalesOrg Name';
            mNewSalesOrg.Code__c = SalesOrgCode;
            mSalesOrgList.add(mNewSalesOrg);
        }
        
        if(isInsert == True)
        {
            insert mSalesOrgList;
        }
        
        return mSalesOrgList;
    }
    
    public static List<Sales_Organization_User__c> createSalesOrgUserRecords(Integer mNum, Id UserId, Id SalesOrgId, Boolean isInsert)
    {
        List<Sales_Organization_User__c> mSalesOrgUserList = new List<Sales_Organization_User__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Sales_Organization_User__c mNewSalesOrgUser = new Sales_Organization_User__c();
            mNewSalesOrgUser.User__c = UserId;
            mNewSalesOrgUser.Sales_Organizationa__c = SalesOrgId;
            mSalesOrgUserList.add(mNewSalesOrgUser);
        }
        
        if(isInsert == True)
        {
            insert mSalesOrgUserList;
        }
        
        return mSalesOrgUserList;
    }
    
    public static List<Opportunity> createOpportunityRecords(Integer mNum, Id AccountId, Id ShipToId, Id SaleOrgUserId, Id pricebookID, String IsoCurrency,String Channel, String Division, Boolean SGT, Boolean isInsert)
    {
        List<Opportunity> mOpportunityList = new List<Opportunity>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Opportunity mNewOpportunity = new Opportunity();
            mNewOpportunity.Name = 'Test Opportunity '+i;
            mNewOpportunity.StageName = 'Qualification';
            mNewOpportunity.AccountId = AccountId;
            mNewOpportunity.Sales_Organization_User__c = SaleOrgUserId;
            mNewOpportunity.Integration_Status__c = 'Not Applicable';
            mNewOpportunity.Shipping_Address__c = ShipToId;
            mNewOpportunity.CloseDate = System.today();
            mNewOpportunity.Expected_Delivery_Date__c = System.today();
            mNewOpportunity.CurrencyIsoCode = IsoCurrency;
            mNewOpportunity.Pricebook2Id = pricebookID;
            If(SGT == True) mNewOpportunity.RecordTypeId = OpportunitySGTRecordTypeId;
            else mNewOpportunity.RecordTypeId = OpportunityStandaloneRecordTypeId;
            mNewOpportunity.Division__c = Division;
            mNewOpportunity.Channel__c =  Channel;
            mOpportunityList.add(mNewOpportunity);
        }
        
        if(isInsert == True)
        {
            insert mOpportunityList;
        }
        
        return mOpportunityList;
    }
    
    public static List<Quote> createQuoteRecords(Integer mNum, Id opportunityId, Id pricebookId, Id ShippingAddress, String quoteERPID, Boolean isInsert)
    {
        List<Quote> mNewQuoteList = new List<Quote>();
        for(Integer i=0; i < mNum; i++)
        {
            Quote mNewQuote = new Quote();
            mNewQuote.Name = 'EEC Quote - '+quoteERPID;
            mNewQuote.Status = 'Active';
            mNewQuote.Pricebook2Id = pricebookId;
            mNewQuote.OpportunityId = opportunityId;
            mNewQuote.ERP_Id__c = quoteERPID;
            mNewQuoteList.add(mNewQuote);
        }
        
        if(isInsert == True)
        {
            insert mNewQuoteList;
        }
        
        return mNewQuoteList;
    }
    
    
    public static List<Product2> createProductRecords(Integer mNum, String thirdLevelHierarchy, Boolean isInsert)
    {
        List<Product2> mNewProductList = new List<Product2>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Product2 mNewProduct = new Product2();
            mNewProduct.Name = 'test product 00' + i;
            mNewProduct.IsActive = True;
            mNewProduct.Third_Level_Product_Hierarchy__c = thirdLevelHierarchy;
            mNewProductList.add(mNewProduct);
        }
        
        if(isInsert == True)
        {
            insert mNewProductList;
        }
        
        return mNewProductList;
    }
    
    public static List<Material_Number__c> createMaterialRecords(Integer mNum, String MaterialERPID, Boolean isInsert)
    {
        List<Material_Number__c> mNewMaterialList = new List<Material_Number__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Material_Number__c mNewMaterial = new Material_Number__c();
            mNewMaterial.Name = MaterialERPID + i;
            mNewMaterial.ERP_Id__c = MaterialERPID + i;
            mNewMaterialList.add(mNewMaterial);
        }
        
        if(isInsert == True)
        {
            insert mNewMaterialList;
        }
        
        return mNewMaterialList;
    }
    
    public static List<Sales_Organization_Material__c> createSalesOrgMaterialRecords(Integer mNum, Id MaterialId, Id SalesOrgId, Boolean Deletion, Boolean isInsert)
    {
        List<Sales_Organization_Material__c> mSalesOrgMaterialList = new List<Sales_Organization_Material__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Sales_Organization_Material__c mNewSalesOrgMaterial = new Sales_Organization_Material__c();
            mNewSalesOrgMaterial.Material_Number__c = MaterialId;
            mNewSalesOrgMaterial.Sales_Organization__c = SalesOrgId;
            mNewSalesOrgMaterial.Deletion__c = Deletion;
            mSalesOrgMaterialList.add(mNewSalesOrgMaterial);
        }
        
        if(isInsert == True)
        {
            insert mSalesOrgMaterialList;
        }
        
        return mSalesOrgMaterialList;
    }

    public static Id createSTDPriceBookRecords()
    {   
        Id pricebookId = Test.getStandardPricebookId();
        return pricebookId;
    }
    
    public static List<PricebookEntry> createPricebookEntryRecords(Integer mNum, Id productID, Id pricebookId, String IsoCurrency, Boolean isInsert)
    {
        List<PricebookEntry> mNewPricebookEntryList = new List<PricebookEntry>();
        
        for(Integer i=0; i < mNum; i++)
        {
            PricebookEntry mNewPBETItem = new PricebookEntry();
            mNewPBETItem.Product2Id = productID;
            mNewPBETItem.Pricebook2Id = pricebookId;
            mNewPBETItem.UnitPrice = 123;
            mNewPBETItem.isActive = true;
            mNewPBETItem.CurrencyIsoCode = IsoCurrency;
            mNewPricebookEntryList.add(mNewPBETItem);
        }
        
        if(isInsert == True)
        {
            insert mNewPricebookEntryList;
        }
        
        return mNewPricebookEntryList;
    }
    
    public static List<OpportunityLineItem> createOpportunityItemRecords(Integer mNum,Id opportunityId,Id productId, Id pricebookEntryID , Id MaterialId, Boolean isInsert)
    {
        List<OpportunityLineItem> mNewOppItemList = new List<OpportunityLineItem>();
        
        for(Integer i=0; i < mNum; i++)
        {
            OpportunityLineItem mNewOppItem = new OpportunityLineItem();
            mNewOppItem.OpportunityId = opportunityId;
            mNewOppItem.PricebookEntryId = pricebookEntryID;
            mNewOppItem.Product2Id = productId;
            mNewOppItem.Material_Number__c = MaterialId;
            mNewOppItem.Quantity = 2;
            mNewOppItem.UnitPrice = 10;
            mNewOppItemList.add(mNewOppItem);
        }
        
        if(isInsert == True)
        {
            insert mNewOppItemList;
        }
        
        return mNewOppItemList;
    } 
    
    public static List<QuoteLineItem> createQuoteLineItemRecords(Integer mNum,Id quoteId,Id productId, Id pricebookEntryID , Boolean isInsert)
    {
        List<QuoteLineItem> mNewQuoteLineItemList = new List<QuoteLineItem>();
        
        for(Integer i=0; i < mNum; i++)
        {
            QuoteLineItem mNewQuoteLineItem = new QuoteLineItem();
            
            mNewQuoteLineItem.QuoteId = quoteId;
            mNewQuoteLineItem.PricebookEntryId = pricebookEntryID;
            mNewQuoteLineItem.Product2Id = productId;
            mNewQuoteLineItem.Quantity = 2;
            mNewQuoteLineItem.UnitPrice = 10;
            mNewQuoteLineItemList.add(mNewQuoteLineItem);
            
        }
        
        if(isInsert == True)
        {
            insert mNewQuoteLineItemList;
        }
        
        return mNewQuoteLineItemList;
    }        
    
    public static List<QuoteCreationWebService.QuoteItems> createQuoteItemsCreate(Integer mNum,String MaterialNumber,Integer Quantity, Integer UnitPrice, String thirdLevelHierarchy)
    {
        QuoteCreationWebService.QuoteItems[] mNewquoteItemsList = new List<QuoteCreationWebService.QuoteItems>();
        
        for(Integer i=0; i < mNum; i++)
        { 
            QuoteCreationWebService.QuoteItems mNewquoteItem = new QuoteCreationWebService.QuoteItems();
            mNewquoteItem.MaterialNumber = MaterialNumber;
            mNewquoteItem.thirdLevelHierarchy = thirdLevelHierarchy;
            mNewquoteItem.Quantity = Quantity;
            mNewquoteItem.UnitPrice = UnitPrice;
            mNewquoteItemsList.add(mNewquoteItem);
            
        }
        return mNewquoteItemsList;
    }
    
    public static List<QuoteDeltaWebService.QuoteItems> createQuoteItemsDelta(Integer mNum,String MaterialNumber,Integer Quantity, Integer UnitPrice, String thirdLevelHierarchy)
    {
        QuoteDeltaWebService.QuoteItems[] mNewquoteItemsList = new List<QuoteDeltaWebService.QuoteItems>();
        
        for(Integer i=0; i < mNum; i++)
        { 
            QuoteDeltaWebService.QuoteItems mNewquoteItem = new QuoteDeltaWebService.QuoteItems();
            mNewquoteItem.MaterialNumber = MaterialNumber;
            mNewquoteItem.thirdLevelHierarchy = thirdLevelHierarchy;
            mNewquoteItem.Quantity = Quantity;
            mNewquoteItem.UnitPrice = UnitPrice;
            mNewquoteItemsList.add(mNewquoteItem);
            
        }
        return mNewquoteItemsList;
    }
    
    public static List<OrderCreationWebService.OrderItems> createOrderItemsCreate(Integer mNum,String MaterialNumber,Integer Quantity, Integer UnitPrice, String thirdLevelHierarchy)
    {
        OrderCreationWebService.OrderItems[] mNeworderItemsList = new List<OrderCreationWebService.OrderItems>();
        
        for(Integer i=0; i < mNum; i++)
        { 
            OrderCreationWebService.OrderItems mNeworderItem = new OrderCreationWebService.OrderItems();
            mNeworderItem.MaterialNumber = MaterialNumber;
            mNeworderItem.thirdLevelHierarchy = thirdLevelHierarchy;
            mNeworderItem.Quantity = Quantity;
            mNeworderItem.UnitPrice = UnitPrice;
            mNeworderItemsList.add(mNeworderItem);
            
        }
        return mNeworderItemsList;
    }
    
        public static List<OrderDeltaWebService.OrderItems> createOrderItemsDelta(Integer mNum,String MaterialNumber,Integer Quantity, Integer UnitPrice, String thirdLevelHierarchy)
    {
        OrderDeltaWebService.OrderItems[] mNeworderItemsList = new List<OrderDeltaWebService.OrderItems>();
        
        for(Integer i=0; i < mNum; i++)
        { 
            OrderDeltaWebService.OrderItems mNeworderItem = new OrderDeltaWebService.OrderItems();
            mNeworderItem.MaterialNumber = MaterialNumber;
            mNeworderItem.thirdLevelHierarchy = thirdLevelHierarchy;
            mNeworderItem.Quantity = Quantity;
            mNeworderItem.UnitPrice = UnitPrice;
            mNeworderItemsList.add(mNeworderItem);
            
        }
        return mNeworderItemsList;
    }
    
    public static List<Order> createOrderRecords(Integer mNum,Id accountId, Id opportunityId, Id pricebookId, Id ShippingAddress, String orderERPID, Boolean isInsert)
    {
        List<Order> mNewOrderList = new List<Order>();
        for(Integer i=0; i < mNum; i++)
        {
            Order mNewOrder = new Order();
            mNewOrder.Name = 'EEC Order - '+orderERPID;
            mNewOrder.Status = 'Draft';
            mNewOrder.EffectiveDate = system.today();
            mNewOrder.Pricebook2Id = pricebookId;
            mNewOrder.OpportunityId = opportunityId;
            mNewOrder.AccountId = accountId;
            mNewOrder.ERP_Id__c = orderERPID;
            mNewOrderList.add(mNewOrder);
        }
        
        if(isInsert == True)
        {
            insert mNewOrderList;
        }
        
        return mNewOrderList;
    }
    
    public static List<OrderItem> createOrderItemRecords(Integer mNum,Id orderId,Id productId, Id pricebookEntryID , Boolean isInsert)
    {
        List<OrderItem> mNewOrderItemList = new List<OrderItem>();
        
        for(Integer i=0; i < mNum; i++)
        {
            OrderItem mNewOrderItem = new OrderItem();
            mNewOrderItem.OrderId = orderId;
            mNewOrderItem.PricebookEntryId = pricebookEntryID;
            mNewOrderItem.Product2Id = productId;
            mNewOrderItem.Quantity = 2;
            mNewOrderItem.UnitPrice = 10;
            mNewOrderItemList.add(mNewOrderItem);
        }
        
        if(isInsert == True)
        {
            insert mNewOrderItemList;
        }
        
        return mNewOrderItemList;
    }
    
    public static List<Organization_Structure__c> createOrgStructureRecords(Integer mNum, String SaleOrg, String SalesOffice, String SalesGroup, String SalesDistrict, String Channel, String Division, Boolean SGT, Id TerritotyId, Boolean isInsert)
    {
        List<Organization_Structure__c> mOrgStructureList = new List<Organization_Structure__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Organization_Structure__c mOrgStructure = new Organization_Structure__c();
            mOrgStructure.Sales_Organization__c = SaleOrg;
            mOrgStructure.Sales_Office__c = SalesOffice;
            mOrgStructure.Sales_Group__c = SalesGroup;
            mOrgStructure.Sales_District__c = SalesDistrict;
            mOrgStructure.Distribution_Channel__c = Channel;
            mOrgStructure.Division__c = Division;
            mOrgStructure.SGT__c = SGT;
            mOrgStructure.Territoty_ID__c = TerritotyId;
            mOrgStructureList.add(mOrgStructure);
        }
        
        if(isInsert == True)
        {
            insert mOrgStructureList;
        }
        
        return mOrgStructureList;
    }
    
    public static List<Sales_Area_Detail__c> createSalesAreaRecords(Integer mNum, Id AccountId, Id OrgStructureId, Boolean isInsert)
    {
        List<Sales_Area_Detail__c> mSalesAreaList = new List<Sales_Area_Detail__c>();
        
        for(Integer i=0; i < mNum; i++)
        {
            Sales_Area_Detail__c mSalesArea = new Sales_Area_Detail__c();
            mSalesArea.Name = 'mSalesArea '+i;
            mSalesArea.Account__c = AccountId;
            mSalesArea.Organization_Structure__c = OrgStructureId;
            mSalesAreaList.add(mSalesArea);
        }
        
        if(isInsert == True)
        {
            insert mSalesAreaList;
        }
        
        return mSalesAreaList;
    }
}