@isTest
public class OrderDeliveryControllerTest 
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
        
        Delivery__c delivery = new Delivery__c();
        delivery.SAP_Delivery_Order_No__c = '6000020345';
        delivery.Sales_Organization__c = 'GB01';
        delivery.Account__c = accounts.get(0).Id;
        insert delivery;
        
        List<OrderItem> mNeworderItems = new List<OrderItem>();
        OrderItem mNewOrderItem = new OrderItem();
        mNewOrderItem.OrderId = ord.Id;
        mNewOrderItem.PricebookEntryId = pbes.get(0).Id;
        mNewOrderItem.Product2Id = products.get(0).Id;
        mNewOrderItem.Material_Number__c = materials.get(0).Id;
        mNewOrderItem.Quantity = 2;
        mNewOrderItem.UnitPrice = 10;
        mNewOrderItem.Line_Item_No__c = 10;
        mNeworderItems.add(mNewOrderItem);
        insert mNeworderItems;
        
        List<Delivery_Product__c> deliveryItems = new List<Delivery_Product__c>();
        Delivery_Product__c deliveryItem = new Delivery_Product__c();
        deliveryItem.Order_Item_No__c = 10;
        deliveryItem.Order_Product__c = mNeworderItems.get(0).Id;
        deliveryItem.Delivery__c = delivery.Id;
        deliveryItems.add(deliveryItem);
        insert deliveryItems;
    }

    @isTest
    static void testGetOrderDeliveryItems() {
      
        Id orderId = [SELECT Id FROM Order].Id;
        Id orderItemId = [SELECT Id FROM OrderItem].Id; 

        
        Test.startTest();
        OrderDeliveryController.getOrderDetails(orderId);
        OrderDeliveryController.getOrderItemDetails(orderItemId);
        Test.stopTest();

    }     
    
}