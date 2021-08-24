public class QuoteOpportunitySyncing {

    @InvocableMethod(label = 'Sync Quote to Opp' description='Sync custom fields to Opportunity' category='Quote')
    public static void SyncQuoteOpportunity(List<List<QuoteLineItem>> QuoteLineItems)
    {
        system.debug('Trigger flow to Sync Quote custom fields to Opp');
        system.debug('QuoteLineItems '+QuoteLineItems[0].size());
        Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>();
        for(QuoteLineItem q : QuoteLineItems[0])
        {
            system.debug('item '+q);
            if(q.OpportunityLineItemId != null && q.Material_Number__c != null)
                oppLineItemsMap.put(q.OpportunityLineItemId, new OpportunityLineItem(id = q.OpportunityLineItemId, 
                                                                                     Material_Number__c = q.Material_Number__c,
                                                                                     UnitPrice = q.UnitPrice,
                                                                                     Quantity = q.Quantity
                                                                                     ));
            
            System.debug('Map OppLineID+MaterialNumber '+oppLineItemsMap);
            
            if(!oppLineItemsMap.isEmpty())
            {
                try 
                {
                    update oppLineItemsMap.values();
                    System.debug('OpportunityLineItem '+oppLineItemsMap+' has been synced!');
                } 
                catch (DmlException e)
                {
                    System.debug(e.getMessage() + ': ' + e.getLineNumber());
                }
            }
        }
        
    }

}