public with sharing class OrderController 
{
    @AuraEnabled
    public static List<ATPTimelineWrapper> getATPTimeline(Id recordId) 
    {
        List<OrderItem> orderItems = [SELECT Availability_to_Promise_ATP__c, Availability_to_Promise_ATP_Display__c, Product2.Name, UnitPrice, Quantity,
            Material_Number__r.Name, Material_Number__r.Material_Description__c  
            FROM OrderItem 
            WHERE OrderId = :recordId
            AND Availability_to_Promise_ATP__c != NULL
            ORDER BY Availability_to_Promise_ATP__c ASC];

        Map<Date, ATPTimelineWrapper> atpTimelines = new Map<Date, ATPTimelineWrapper>();
        for (OrderItem item : orderItems)
        {
            Date atpDate = item.Availability_to_Promise_ATP__c;
            if (!atpTimelines.containsKey(atpDate))
            {
                ATPTimelineWrapper atpTimeline = new ATPTimelineWrapper();
                atpTimeline.atpDate = atpDate;
                atpTimeline.atpDateDisplay = item.Availability_to_Promise_ATP_Display__c;
                atpTimeline.products = new List<OrderItem>();
                atpTimelines.put(atpDate, atpTimeline);
            }
            atpTimelines.get(atpDate).products.add(item);
        }
        return atpTimelines.values();
    }

    public class ATPTimelineWrapper
    {
        @AuraEnabled        
        public Date atpDate { get; set; }
        @AuraEnabled        
        public String atpDateDisplay { get; set; }        
        @AuraEnabled
        public List<OrderItem> products { get; set; }
    }
}