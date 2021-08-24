public without sharing class OrderDeliveryController 
{
    @AuraEnabled
    public static List<Delivery__c> getOrderDetails(Id recordId) 
    {
        Set<Id> DeliveryIds = new Set<Id>();
        List<Delivery_Product__c> deliveryItems = [SELECT Id, Name, Delivery__c FROM Delivery_Product__c WHERE Order_Product__r.OrderId =: recordId];
        for(Delivery_Product__c item : deliveryItems)
        {
            DeliveryIds.add(item.Delivery__c);
        }
        
        List<Delivery__c> delivery = [SELECT Id, SAP_Delivery_Order_No__c, Planned_Good_Issue_Date__c, Status__c, Status_Detail__c,Carrier_Name__c,Tracking_No__c,
                                      (SELECT Id, Name, Delivery_Qty__c, Planned_Goods_Issue_Date__c, Actual_Goods_Issue_Date__c, Order_Product__c, Item_Status__c, 
                                       Item_Status_Detail__c, DO_Item_No__c, Order_Item_No__c, Order_Product__r.Material_Description__c, Product_ID__c, Product_Description__c, 
                                       Delivery_Qty_UOM__c, Order_Product__r.Quantity, Gross_Weight__c,Net_Weight__c
                                       FROM Delivery_Orders__r WHERE Order_Product__r.OrderId =: recordId Order by CreatedDate)
                                      FROM Delivery__c WHERE Id IN: DeliveryIds];
        
        system.debug('delivery '+delivery.size());
        
        //delivery = removeEmptyDelivery(delivery);
        
        return delivery;
        
    }
        
    @AuraEnabled
    public static List<Delivery__c> getOrderItemDetails(Id recordId) 
    {
        
        Set<Id> DeliveryIds = new Set<Id>();
        List<Delivery_Product__c> deliveryItems = [SELECT Id, Name, Delivery__c FROM Delivery_Product__c WHERE Order_Product__c =: recordId];
        for(Delivery_Product__c item : deliveryItems)
        {
            DeliveryIds.add(item.Delivery__c);
        }
        
        List<Delivery__c> delivery = [SELECT Id, SAP_Delivery_Order_No__c, Planned_Good_Issue_Date__c, Status__c, Status_Detail__c,Carrier_Name__c,Tracking_No__c,
                                      (SELECT Id, Name, Delivery_Qty__c, Planned_Goods_Issue_Date__c, Actual_Goods_Issue_Date__c, Order_Product__c, Item_Status__c, 
                                       Item_Status_Detail__c, DO_Item_No__c, Order_Item_No__c, Order_Product__r.Material_Description__c, Product_ID__c, Product_Description__c, 
                                       Delivery_Qty_UOM__c, Order_Product__r.Quantity, Gross_Weight__c,Net_Weight__c
                                       FROM Delivery_Orders__r WHERE Order_Product__c =: recordId Order by CreatedDate)
                                      FROM Delivery__c WHERE Id IN: DeliveryIds];
        
        system.debug('delivery '+delivery.size());
        
        //delivery = removeEmptyDelivery(delivery);
        
        return delivery;
        
    }
    
    /*public static List<Delivery__c> removeEmptyDelivery(List<Delivery__c> delivery)
    {
        List<Delivery__c> newDelivery = new List<Delivery__c>();
        system.debug('Before '+delivery.size());
        for(Delivery__c o : delivery)
        {
            //system.debug(o);
            if(!o.Delivery_Orders__r.isEmpty())
            {
                newDelivery.add(o);
            }
        }
        system.debug('After '+newDelivery.size());
        
        return newDelivery;
    }*/
}