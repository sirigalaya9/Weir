@isTest
public class OrderTest 
{
    @TestSetup
    static void setupData()
    {
        Id STDPriceBookId = TestUtility.createSTDPriceBookRecords();
        List<Product2> products = TestUtility.createProductRecords(1, 'Z0001S0001', True);
        List<PricebookEntry> pbes = TestUtility.createPricebookEntryRecords(1, products[0].Id, STDPriceBookId,'AUD', True);
        List<Material_Number__c> materials = TestUtility.createMaterialRecords(1, 'Mat123', True);
        List<Account> accounts = TestUtility.createAccountRecords(1, TRUE);
        Order ord = new Order();
        ord.Pricebook2Id = STDPriceBookId;
        ord.CurrencyIsoCode = 'AUD';
        ord.AccountId = accounts.get(0).Id;
        ord.Status = 'Draft';
        ord.EffectiveDate = System.today();      
        insert ord;      
    }

    @isTest
    static void testGetATPTimeline_NoProducts() {

        Id ordId = [SELECT Id FROM Order].Id;
        Test.startTest();
        List<OrderController.ATPTimelineWrapper> results = OrderController.getATPTimeline(ordId);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'No results as no order lines were created.');
    }    

    @isTest
    static void testGetATPTimeline_WithProducts() {
        
        Id ordId = [SELECT Id FROM Order].Id;      
        OrderItem oi = new OrderItem();
        oi.PricebookEntryId = [SELECT Id FROM PricebookEntry].Id;
        oi.Quantity = 1;  
        oi.OrderId = ordId;
        oi.UnitPrice = 1;
        oi.Availability_to_Promise_ATP__c = System.today();
        oi.Material_Number__c = [SELECT Id FROM Material_Number__c].Id;
        insert oi;  

        Test.startTest();
        List<OrderController.ATPTimelineWrapper> results = OrderController.getATPTimeline(ordId);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'One Order Line has to be returned.');

    }     
    
}