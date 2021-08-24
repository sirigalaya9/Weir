({
    doInit : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED")
        {
            var quoteId = component.get("v.recordId");
            var quoteRecord = component.get("v.quoteRecord");
            //alert(quoteRecord.Integration_Status__c);
            //alert(quoteRecord.Opportunity.StageName);
            var oppList = {};
            var ErrorMessage = '';
            var MessageRequiredField = '';
            component.set("v.spinner", true);
            
            
            if (quoteRecord.Integration_Status__c == 'In Progress')
            {
                helper.showToast("Warning","Error","Quote Creation is In Progress...");
            }
            else if (quoteRecord.Integration_Status__c == 'Completed')
            {
                helper.showToast("Warning","Error","Quote has been already created in SAP");
            }
            else if (quoteRecord.Number_of_Products__c == 0)
            {
                helper.showToast("error","Error","Please at least 1 product before sending to SAP.");
            }
            else if (quoteRecord.Opportunity.StageName != 'Bid Preparation' && quoteRecord.Opportunity.StageName != 'Negotiation')
            {
                helper.showToast("error","Error","Only Bid Preparation and Negotiation Stage can create quote in SAP");
            }
            else
            {
                var action = component.get("c.PushQuoteToSAP");
                action.setParams({"quoteId": quoteId});
                action.setCallback(this, function(response)
                                   {
                                       var status = response.getState();
                                       if(status == "SUCCESS")
                                       {
                                           var quoteToSAPSuccess = response.getReturnValue();
                                           component.set("v.quoteSent", true);
                                           if(quoteToSAPSuccess == true)
                                           {
                                               component.set("v.quoteCreated", true);
                                           }
                                           
                                           component.set("v.spinner", false);
                                           window.setTimeout($A.getCallback(function() {
                                               $A.get("e.force:closeQuickAction").fire()
                                               $A.get('e.force:refreshView').fire();
                                           }), 4000);
                                       }
                                   });                    
                $A.enqueueAction(action);
            }
        }
        
        
    }
})