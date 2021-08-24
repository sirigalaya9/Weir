public class CreateQuoteController {
    
    public static void SyncQuoteOpportunity(List<QuoteLineItem> QuoteLineItems)
    {
        system.debug('QuoteLineItems '+QuoteLineItems.size());
        Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>();
        for(QuoteLineItem q : QuoteLineItems)
        {
            system.debug('item '+q);
            if(q.OpportunityLineItemId != null && q.Material_Number__c != null)
                oppLineItemsMap.put(q.OpportunityLineItemId, new OpportunityLineItem(id = q.OpportunityLineItemId, 
                                                                                     Material_Number__c = q.Material_Number__c));
            
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
    
    @AuraEnabled
    public static Boolean PushQuoteToSAP(Id quoteId)
    {
        Boolean quoteToSAPSuccess = PushToSAPController.PushQuoteToSAP(quoteId);
        System.debug('quoteToSAPSuccess '+quoteToSAPSuccess);
        return quoteToSAPSuccess;
        
    }
    

}