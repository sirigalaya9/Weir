public with sharing class OrderEntryController 
{
    @AuraEnabled
    public static List<QuoteLineItem> getQuoteLines(Id quoteId) 
    {
        List<QuoteLineItem> quoteLines = [SELECT Product2Id, Product_Name__c, Quantity, UnitPrice FROM QuoteLineItem WHERE QuoteId = :quoteId];
        return quoteLines;
    }

    @AuraEnabled
    public static string saveOrderEntry(Order_Entry__c orderEntry, List<Order_Entry_Item__c> entryItems){
        insert orderEntry;
        for (Order_Entry_Item__c entryItem : entryItems) {
            entryItem.Order_Entry__c = orderEntry.Id;
        }
        insert entryItems;
        return orderEntry.Id;
    }
}