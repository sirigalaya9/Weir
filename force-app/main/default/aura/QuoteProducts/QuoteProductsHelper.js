({
    
    GetInitialData : function (component, event)
    {
        var allVcRecordTypes = component.get("v.allVcRecordTypes");
        var quoteRecord = component.get("v.quoteRecord");
        var recordId = component.get("v.sourceId");
        var action = component.get("c.getQuoteItems");
        action.setParams({"objId": recordId});
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS")
                               {
                                   var opportunityProducts = response.getReturnValue();
                                   console.log(JSON.stringify(opportunityProducts));
                                   var newQuoteProducts = [];
                                   var VCProducts = [];

                                   if (opportunityProducts.length > 0)
                                   {
                                       
                                       /*for(var i = 0; i < opportunityProducts.length; i++)
                                       {
                                           
                                           if(typeof opportunityProducts[i].Variable_Configurator__c == 'undefined' && 
                                              opportunityProducts[i].Material_Number__c != null && opportunityProducts[i].Material_Number__r.Is_VC__c == true)
                                           {
                                               
                                               for(var j=0; j<allVcRecordTypes.length; j++)
                                               {
                                                   if(opportunityProducts[i].VC_Type__c == allVcRecordTypes[j].DeveloperName)
                                                   {
                                                       opportunityProducts[i].VC_RecordType_Id__c = allVcRecordTypes[j].Id;
                                                       break;
                                                   }
                                               }
                                           }
                                       }*/
                                       
                                       component.set("v.newQuoteProducts", opportunityProducts);
                                   }
                                   else
                                   {
                                       for (var i=0; i<1; i++)
                                       {
                                           var newOpportunityProduct = {};                            
                                           newOpportunityProduct.QuoteId = recordId;
                                           newOpportunityProduct.CreateQuoteSAP_Success__c = false;
                                           newQuoteProducts.push(newOpportunityProduct);                            
                                       }
                                       component.set("v.newQuoteProducts", newQuoteProducts);
                                   }
                                   component.set("v.QuoteProductToDelete", []);
    
                               }
                               else if(state === "ERROR"){
                                   var errors = action.getError();
                                   if (errors) {
                                       if (errors[0] && errors[0].message) {
                                           var toastEvent = $A.get("e.force:showToast");
                                           toastEvent.setParams({
                                               "title": "Error",
                                               "message": errors[0].message,
                                               "type": "error"
                                           });
                                           toastEvent.fire(); 
                                       }
                                   }
                               }else if (status === "INCOMPLETE") {
                                   alert('No response from server or client is offline.');
                               }
                           });                    
        $A.enqueueAction(action);
        component.set("v.spinner", false);
        
    },
    
    
    GetVCRecordTypes : function (component, event)
    {
        var action = component.get("c.getAllVCRecordTypes");
        action.setParams({"objectName": 'Variable_Configurator__c'});
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS")
                               {
                                   var allVcRecordTypes = response.getReturnValue();
                                   component.set("v.allVcRecordTypes", allVcRecordTypes);
                                   //newQuoteProducts[index].VC_RecordType_Id__c = vc_RecordType.Id;
                               }
                           });                    
        $A.enqueueAction(action);
    },
    
    
    showToast : function (type, title, message) {
        $A.get("e.force:closeQuickAction").fire()
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "type": type,
            "title": title,
            "message": message});
        resultsToast.fire();
    },
    
    
    
    
    validate : function(component, event) 
    {
        var newQuoteProductFields = component.find('newQuoteProductFields');
        var allValid = false;
        if (newQuoteProductFields.length > 1)
        {
            allValid = component.find('newQuoteProductFields').reduce(function (validSoFar, inputCmp)
                                                               {
                                                                   inputCmp.reportValidity();
                                                                   return validSoFar && inputCmp.checkValidity();
                                                               }, true);
        }
        else
        {
            newQuoteProductFields.reportValidity();
            allValid = newQuoteProductFields.checkValidity();
        }
        if (allValid) 
        {
            //alert('All form entries look valid. Ready to submit!');
            component.set("v.isValid", true);
        }
        else
        {
            //alert('Please update the invalid form entries and try again.');
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Invalid Form",
                "message": "Please update the invalid form entries and try again.",
                "type": "error"
            });
            toastEvent.fire(); 
            component.set("v.isValid", false);
        }
        return allValid;
    },

    getParameterByName: function(component, event, name)
    {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    }
    
})