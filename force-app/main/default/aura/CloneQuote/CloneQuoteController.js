({
    doInit : function(component, event, helper) {
        var quoteId = component.get("v.recordId");
        var record = component.get("v.quoteRecord");
        var oppList = {};
        var ErrorMessage = '';
        var MessageRequiredField = '';
        //component.set("v.spinner", true);
        
        if (typeof record.Shipping_Address__c == 'undefined')
        {
            helper.showToast("error","Error","Shipping Address is Empty");
        }
        /*else if (typeof record.Division__c == 'undefined')
        {
            helper.showToast("error","Error","Division is Empty");
        }
        else if (typeof record.Distribution_Channel__c == 'undefined')
        {
            helper.showToast("error","Error","Distribution Channel is Empty");
        }*/
        else if (record.ExpirationDate == null)
        {
            helper.showToast("error","Error","ExpirationDate Date is Empty");
        }
        else if (record.Expected_Delivery_Date__c == null)
        {
            helper.showToast("error","Error","Expected Delivery Date is Empty");
        }
        else if (record.Application__c == null)
        {
            helper.showToast("error","Error","Application is Empty");
        }
        else
        {
            var action = component.get("c.getQuoteItems");
            action.setParams({"objId": component.get("v.recordId")});
            action.setCallback(this, function(response)
                               {
                                   var status = response.getState();
                                   if(status == "SUCCESS")
                                   {
                                       var quoteItems = response.getReturnValue();
                                       //alert(oppItems.length);
                                       if(quoteItems.length > 0)
                                       {
                                           var allProductHasMaterial = true;
                                           for(var i=0; i<quoteItems.length; i++)
                                           {  
                                               var itemNo = i+1;
                                               if(typeof quoteItems[i].Material_Number__c == 'undefined')
                                               {
                                                   allProductHasMaterial = false;
                                                   helper.showToast("error","Material Number!","Quote Item No."+itemNo+" has no Material Number");
                                                   break;
                                               }
                                           }
                                           if(allProductHasMaterial == true)
                                           {
                                               var flow = component.find("flowData");
                                               var inputVariables = [{ name : "recordId", type : "String", value: component.get("v.recordId")}];
                                               flow.startFlow("Clone_Quote_and_Sync_to_SAP", inputVariables);
                                               
                                           }
                                       }
                                   }
                               });
            $A.enqueueAction(action);

        }
        
    },
    
    statusChange : function (component, event) {
        console.log(event.getParam('status'));
        if (event.getParam('status') === "FINISHED_SCREEN") {
            var quoteID;
            var successQuoteItems = [];
            var outputVariables = event.getParam("outputVariables");
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                //console.log(outputVar);
                if(outputVar.name === "Var_QuoteID") {
                    quoteID = outputVar.value;
                    console.log('quoteID : '+quoteID);
                }
            }
            
            component.set("v.spinner", true);
            var action = component.get("c.PushQuoteToSAP");
            action.setParams({"quoteId": quoteID});
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
                                           //component.set("v.spinner", false);
                                           window.setTimeout($A.getCallback(function() {
                                               var redirect = $A.get("e.force:navigateToSObject");
                                               redirect.setParams({
                                                   "recordId": quoteID
                                               });
                                               redirect.fire();
                                           }), 4000);
                                       }
                                       else
                                           {
                                               component.set("v.quoteCreated", false);
                                           }
                                           
                                           component.set("v.spinner", false);
                                           /*window.setTimeout($A.getCallback(function() {
                                               $A.get("e.force:closeQuickAction").fire()
                                               $A.get('e.force:refreshView').fire();
                                           }), 4000);*/
                                       }
                                   });                    
            $A.enqueueAction(action);
        }
    }
})