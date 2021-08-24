({
    doInit : function(component, event, helper) {
        var oppId = component.get("v.recordId");
        var record = component.get("v.oppRecord");
        var ErrorMessage = '';
        var MessageRequiredField = '';
        //component.set("v.spinner", true);
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        /*if (record.Shipping_Address__c == null)
        {
            helper.showToast("error","Error","Shipping Address is Empty");
        }
        else if (typeof record.Division__c == 'undefined')
        {
            helper.showToast("error","Error","Division is Empty");
        }
        else if (typeof record.Channel__c == 'undefined')
        {
            helper.showToast("error","Error","Distribution Channel is Empty");
        }*/
        if (record.CloseDate < today)
        {
            helper.showToast("error","Error","CloseDate cannot be in the past");
        }
        else if (record.Expected_Delivery_Date__c == null)
        {
            helper.showToast("error","Error","Expected Delivery Date is Empty");
        }
        else if (record.Application__c == null)
        {
            helper.showToast("error","Error","Application is Empty");
        }
        else if (record.Number_of_Quotations__c > 0)
        {
            helper.showToast("error","Error","An existing Quote been created. Please use the existing Quote.");
        }
        else if (record.Number_of_Products__c == 0)
        {
            helper.showToast("error","Error","Please add at least one product before creating a budget quote.");
        }
        else
        {
            var action = component.get("c.getOpportunityItems");
            action.setParams({"objId":component.get("v.recordId")});
            action.setCallback(this, function(response)
                               {
                                   var status = response.getState();
                                   if(status == "SUCCESS")
                                   {
                                       var oppItems = response.getReturnValue();
                                       //alert(oppItems.length);
                                       if(oppItems.length > 0)
                                       {
                                           var allProductHasMaterial = true;
                                           for(var i=0; i<oppItems.length; i++)
                                           {  
                                               var itemNo = i+1;
                                               if(typeof oppItems[i].Material_Number__c == 'undefined')
                                               {
                                                   allProductHasMaterial = false;
                                                   helper.showToast("error","Material Number!","Opportunity Item No."+itemNo+" has no Material Number");
                                                   break;
                                               }
                                           }
                                           if(allProductHasMaterial == true)
                                           {
                                               var flow = component.find("flowData");
                                               var inputVariables = [{ name : "recordId", type : "String", value: component.get("v.recordId")}];
                                               flow.startFlow("Create_Quote", inputVariables);
                                               
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
                else if(outputVar.name === "Var_Success_QuoteItems") {
                    successQuoteItems = outputVar.value;
                    console.log('successQuoteItems : '+successQuoteItems);
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
            
            //component.set("v.quoteCreated", true);
            
            
            
            //var cmpTarget = component.find('flowData');
            //$A.util.addClass(cmpTarget, 'changeMe');
        }
    }
})