public class QuoteTriggerHandler {
    
    /*@future (callout=true)
    public static void SyncDateToSAP_delete(Set<Id> quoteIds) {
        
        List<Quote> quotes = [SELECT Id, Name, Integration_Status__c,ExpirationDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity.Opportunity_ID__c,Opportunity.Date_Received__c,
                              Division__c, Distribution_Channel__c, Sales_Group__c, Sales_Office__c, Sales_Organization__c,Quote_ID__c,ERP_ID__c,
                              Application__c, Integrated_Solution__c, Other_Strategic_Initiatives__c, Important__c, Managed_by_Project_Teams__c,
                              Account.ERP_Id__c,Shipping_Address__r.ERP_ID__c,
                              (SELECT Id, Material_Number__r.Name, Material_Number__r.Quantity_Unit_Of_Measure__c, Product2.Third_Level_Product_Hierarchy__c,UnitPrice, Quantity, Description,Rejected_Reason__c FROM QuoteLineItems)
                              FROM Quote
                              WHERE IsSyncing = True AND Id =:quoteIds];
        
        if(!quotes.isEmpty())
        {
            for(Quote quote : quotes)
            {

            }
            
        }
        else
            system.debug('There is no synced Quotation related');
    }*/
    
    @future (callout=true)
    public static void SyncDateToSAP(Set<Id> quoteIds)
    {
        system.debug('SyncDateToSAP '+quoteIds);
        List<Quote> quotes = [SELECT Id, Name, Integration_Status__c,ExpirationDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity.Opportunity_ID__c,Opportunity.Date_Received__c,
                              Division__c, Distribution_Channel__c, Sales_Group__c, Sales_Office__c, Sales_Organization__c,Quote_ID__c,ERP_ID__c,
                              Application__c, Integrated_Solution__c, Other_Strategic_Initiatives__c, Important__c, Managed_by_Project_Teams__c,
                              Account.ERP_Id__c,Shipping_Address__r.ERP_ID__c,Payment_Term__c,Incoterm_1__c,Incoterm_2__c,
                              (SELECT Id, Material_Number__r.Name, Material_Number__r.Quantity_Unit_Of_Measure__c, Product2.Third_Level_Product_Hierarchy__c,UnitPrice, Quantity, Description,Rejected_Reason__c FROM QuoteLineItems)
                              FROM Quote
                              WHERE IsSyncing = True AND Id =:quoteIds];
        
        Boolean quoteToSAPSuccess = PushToSAP.CreateQuote(quotes, 'Delta');
    }
    
    /*@future
    public static void SyncQuote(Set<Id> quoteIds)
    {
        system.debug('SyncQuote '+quoteIds);
        List<Quote> quotes = [select Id, OpportunityId from Quote where Id in :quoteIds];
        List<Opportunity> opps = new List<Opportunity>();
        for (Quote q : quotes)
        {
            Opportunity opp = new Opportunity();
            opp.Id = q.OpportunityId;
            opp.SyncedQuoteId = q.Id;
            opps.add(opp);
        }
        update opps;
    }
    
    @future
    public static void unSyncQuote(Set<Id> quoteIds)
    {
        system.debug('unSyncQuote '+quoteIds);
        List<Quote> quotes = [select Id, OpportunityId from Quote where Id in :quoteIds];
        List<Opportunity> opps = new List<Opportunity>();
        for (Quote q : quotes)
        {
            Opportunity opp = new Opportunity();
            opp.Id = q.OpportunityId;
            opp.SyncedQuoteId = null;
            opps.add(opp);
        }
        update opps;
    }*/

}