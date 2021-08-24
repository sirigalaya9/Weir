@isTest
public class OrderEntryTest {

    @testSetup
    static void setupData()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.AccountId = acc.Id;        
        opp.StageName = 'Qualification';
        opp.CloseDate = System.today();
        insert opp;
        Quote quote = new Quote();
        quote.Name = 'Test';
        quote.OpportunityId = opp.Id;
        insert quote;
    }

    @isTest
    static void testGetQuoteLines()
    {
        Id quoteId = [SELECT Id FROM Quote].Id;
        List<QuoteLineItem> items = OrderEntryController.getQuoteLines(quoteId);
        System.assertEquals(0, items.size(), 'x items have to be returned');
    }

    @isTest
    static void testSaveOrderEntry()
    {
        Order_Entry__c orderEntry = new Order_Entry__c();
        orderEntry.Account__c = [SELECT Id FROM Account].Id;
        Order_Entry_Item__c entryItem = new Order_Entry_Item__c();        
        List<Order_Entry_Item__c> entryItems = new List<Order_Entry_Item__c>();
        entryItems.add(entryItem);
        Id orderEntryId = OrderEntryController.saveOrderEntry(orderEntry, entryItems);
        System.assertNotEquals(null, orderEntryId, 'Id should not be null');
    }

}