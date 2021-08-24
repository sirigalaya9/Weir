@istest
public with sharing class OpportunityAfterUpdateTriggerTest {
    
    static Account testAccount;
    static Opportunity testOpp;
    static Project__c testProj;
        
    static Product2 testProduct;
    //static Product2 testProduct2;
    
    static Id standardPriceBookId;
    static PricebookEntry testProductPriceBookEntry;
    //static PricebookEntry testProductPriceBookEntry2;
        
    static testmethod void TestOppAmountUpdate() {
    
        createAccount();
        createProduct();
        createProject();
        
        createOpp();
        
        Test.startTest();
        
        CreateOppLineItem();        
        
        Test.stopTest();
        
    }
    
    static testmethod void TestProjectCurrencyChange() {
    
        createAccount();
        createProduct();
        createProject();
        
        createOpp();
        
        CreateOppLineItem(); 
        
        Test.startTest();
        
        testProj.CurrencyISOCode = 'MYR';       
        update testProj;
        Test.stopTest();
        
    }
    
    
    static void CreateAccount() {

        testAccount = new Account(
            Name = 'Test Account', 
            Type = 'End User', 
            Phone = '012299999',
            BillingCountry = 'Malaysia',
            BillingPostalCode = '47100',
            BillingCity= 'Kuala Lumpur'
        );
        insert testAccount;

    }
   
    static void createProduct() {
    
        List<RecordType> rtList = [SELECT Id, DeveloperName FROM RecordType 
                                   WHERE SObjectType = 'Product2' 
                                   AND DeveloperName IN ('Standalone_Record_Type') 
                                   AND isActive = true ORDER BY DeveloperName ASC];
      
        Id rt1Id;
        Id rt2Id;
        
        for (RecordType rt : rtList) {
            if (rt.DeveloperName == 'Standalone_Record_Type') {
                rt1Id = rt.Id;
            } else {
                rt2Id = rt.Id;
            }
        }
           
        //create first centre   
        Product2 testProduct = new Product2(
            Name = 'Test Centre Product',
            //Parent_Product__c = null, 
            isActive = true//,
           // recordTypeId = rt1Id//,
            //Asset_type__c = 'Shophouse'
        );
               /*
        testSuite = new Product2(
            Name = 'Test Suite Product',
            Parent_Product__c = testCentre.Id, 
            isActive = true,
            recordTypeId = rtSuiteId//,
            //room_type__c = 'Bedroom'
        );
        
        //create 2nd centre
        Product2 testCentre2 = new Product2(
            Name = 'Test Centre Product',
            Parent_Product__c = null, 
            isActive = true,
            recordTypeId = rtCentreId//,
            //Asset_type__c = 'Shophouse'
        );
        
        testSuite2 = new Product2(
            Name = 'Test Suite Product 2',
            Parent_Product__c = testCentre2.Id,
            isActive = true,
            recordTypeId = rtSuiteId//,
            //room_type__c = 'Bedroom'
        );
        */
        //create all the products
        List<Product2> testProducts = new List<Product2>();
        testProducts.add(testProduct);        
        //testCentres.add(testCentre2);        
        insert testProducts; 
        
        /*List<Product2> testSuites = new List<Product2>();
        testSuites.add(testSuite);        
        testSuites.add(testSuite2);        
        insert testSuites; 
        */
        standardPriceBookId = Test.getStandardPricebookId();
        
        testProductPriceBookEntry = new PricebookEntry();
        testProductPriceBookEntry.pricebook2Id = standardPriceBookId;
        testProductPriceBookEntry.product2id = testProduct.id;
        testProductPriceBookEntry.unitprice = 1249.0;
        testProductPriceBookEntry.CurrencyISOCode = 'AUD';
        testProductPriceBookEntry.isactive = true;
      /*  
        testSuitePriceBookEntry2 = new PricebookEntry();
        testSuitePriceBookEntry2.pricebook2Id = standardPriceBookId;
        testSuitePriceBookEntry2.product2id = testSuite2.id;
        testSuitePriceBookEntry2.unitprice = 1249.0;
        testSuitePriceBookEntry2.isactive = true;
         */
        List<PriceBookEntry> pBEntryList = new List<PriceBookEntry>();
        pBEntryList.add(testProductPriceBookEntry);
        //pBEntryLIst.add(testSuitePriceBookEntry2);
        insert pBEntryList;
                
    }
    
    static void CreateProject(){
    
        testProj = new Project__c (
                            Name = 'Test Project',
                            CurrencyISOCode = 'AUD'
            );
        insert testProj;
                                
    }
    
    static void CreateOpp(){
            
        testOpp = new Opportunity( 
                            Name ='Test Opp', 
                            AccountId = testAccount.Id,
                            StageName = 'Qualification',
                            CloseDate = Date.today(),
                            priceBook2Id = standardPriceBookId ,
                            Publish_to_Forecast__c = TRUE ,
                            Project__c = testProj.Id ,
                            CurrencyISOCode = 'AUD'                   
                );
                       
        insert testOpp;   
        
    }
    
    static void CreateOppLineItem(){       
        
        OpportunityLineItem testOppLineItem = new OpportunityLineItem(
                                        OpportunityId = testOpp.Id,
                                        Quantity = 1,
                                        TotalPrice = 100,
                                        PriceBookEntryId = testProductPriceBookEntry.Id
                                        //Product2Id = testSuite.Id
                                       );     
        insert testOppLineItem;    
    
    }
    
    
    
}