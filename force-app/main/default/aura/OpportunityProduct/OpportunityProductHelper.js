({
    
    GetInitialData : function (component, event)
    {
        var allVcRecordTypes = component.get("v.allVcRecordTypes");
        var oppRecord = component.get("v.oppRecord");
        var recordId = component.get("v.sourceId");
        var action = component.get("c.getOpportunityLineItems");
        action.setParams({"objId": recordId});
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS")
                               {
                                   
                                   var opportunityProducts = response.getReturnValue();
                                   console.log(JSON.stringify(opportunityProducts));
                                   var newOpportunityProducts = [];
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
                                        component.set("v.headerName", 'Edit Products');
                                       component.set("v.newOpportunityProducts", opportunityProducts);
                                   }
                                   else
                                   {
                                       for (var i=0; i<1; i++)
                                       {
                                           var newOpportunityProduct = {};                            
                                           newOpportunityProduct.OpportunityId = recordId;
                                           newOpportunityProduct.CreateQuoteSAP_Success__c = false;
                                           newOpportunityProducts.push(newOpportunityProduct);                            
                                       }
                                       component.set("v.newOpportunityProducts", newOpportunityProducts);
                                      
                                   }
                                   component.set("v.OpportunityProductToDelete", []);
    
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
                                   //newOpportunityProducts[index].VC_RecordType_Id__c = vc_RecordType.Id;
                               }
                           });                    
        $A.enqueueAction(action);
    },
    
    
    ValidateOpportunity : function (response, component, helper){
        var oppList = {};
        var status = response.getState();
        if(status == "SUCCESS")
        {
            oppList = response.getReturnValue();
            if(oppList != null)
            { 
                if (oppList[0].SGTProfile__c == false)
                {
                    helper.showToast("error","User Profile","Only SGT Profiles can submit inquiry");
                }
                else if (oppList[0].Quote_SAP_Status__c  == 'In Progress')
                {
                    helper.showToast("Warning","Quote SAP Status","Inquiry Creation is In Progress...");
                }
                else if (oppList[0].Quote_SAP_Status__c  == 'Completed')
                {
                    helper.showToast("Warning","Quote SAP Status","Inquiry has been already created in SAP");
                }
                else if (oppList[0].StageName != 'Bid Preparation' && oppList[0].StageName != 'Negotiation')
                {
                    helper.showToast("error","Opportunity Stage","Only Bid Preparation and Negotiation Stage can be submitted");
                }
                else if (typeof oppList[0].Shipping_Address__c == 'undefined')
                {
                    helper.showToast("error","Shipping Address","Shipping Address is Empty");
                }
                else if (typeof oppList[0].Division__c == 'undefined')
                {
                    helper.showToast("error","Division","Division is Empty");
                }
                else if (typeof oppList[0].Channel__c == 'undefined')
                {
                    helper.showToast("error","Distribution Channel","Distribution Channel is Empty");
                }
                else if (typeof oppList[0].Expected_Delivery_Date__c == 'undefined')
                {
                    helper.showToast("error","Expected Delivery Date","Expected Delivery Date is Empty ");
                }
                else if (typeof oppList[0].OpportunityLineItems == 'undefined')
                {
                    helper.showToast("error","Error!","There is no Opportunity Product");
                }
                else if (oppList[0].OpportunityLineItems.length > 0)
                { 
                    //alert("OpportunityLineItems.length "+oppList[0].OpportunityLineItems.length);
                    var allProductHasMaterial = true;
                    var allvcFormCompleted = true;
                    for(var i=0; i<oppList[0].OpportunityLineItems.length; i++)
                    {  
                        var itemNo = i+1;
                        if(typeof oppList[0].OpportunityLineItems[i].Material_Number__c == 'undefined')
                        {
                            allProductHasMaterial = false;
                            helper.showToast("error","Material Number!","Opportunity Product No."+itemNo+" has no Material Number");
                        }
                        
                        if(typeof oppList[0].OpportunityLineItems[i].Variable_Configurator__c != 'undefined' &&
                           oppList[0].OpportunityLineItems[i].VCForm_Completed__c == false &&
                           oppList[0].OpportunityLineItems[i].CreateQuoteSAP_Success__c == false)
                        {
                            allvcFormCompleted = false;
                            helper.showToast("error","VC Products!","Opportunity Product No."+itemNo+" VC Form is not completed");
                        }
                        
                    }
                    
                    if(allProductHasMaterial == true && allvcFormCompleted == true)
                    {
                        var action = component.get("c.SendToSAP");
                        action.setParams({"oppList":oppList});
                        action.setCallback(this, function(response)
                                           {
                                               var status = response.getState();
                                               
                                               if(state === "SUCCESS"){
                                                   var vcSAPStatus = response.getReturnValue();
                                                   alert('VC Success : '+ vcSAPStatus.vcSuccess)
                                                   component.set("v.SendToSAPSuccess",vcSAPStatus.vcSuccess);
                                                   //var SendToSAPSuccess = true;
                                                   if(vcSAPStatus.vcSuccess == true)
                                                   {
                                                       component.set("v.SendToSAPSuccess", true);
                                                       var toastEvent = $A.get("e.force:showToast");
                                                       toastEvent.setParams({
                                                           "title": "Success!",
                                                           "message": "sendToSAP successfully.",
                                                           "type": "success"
                                                       });
                                                       
                                                       toastEvent.fire();
                                                       
                                                       window.setTimeout($A.getCallback(function() {
                                                           $A.get("e.force:closeQuickAction").fire()
                                                           $A.get('e.force:refreshView').fire();
                                                       }), 4000);
                                                   }
                                                   else if(vcSAPStatus.vcSuccess == false)
                                                   {
                                                       //component.set("v.SendToSAPSuccess", true);
                                                       var toastEvent = $A.get("e.force:showToast");
                                                       toastEvent.setParams({
                                                           "title": "Error!",
                                                           "message": "Create Quote in SAP Unsuccessfully.",
                                                           "type": "error"
                                                       });
                                                   }
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
                        
                        
                        /*if(status == "SUCCESS")
                                               {
                                                   var SAPStatus = response.getReturnValue();
                                                   if(SAPStatus.accToSAPSuccess == true)
                                                   {
                                                       component.set("v.accCreated", true);
                                                   }
                                                   if(SAPStatus.oppToSAPSuccess == true)
                                                   {
                                                       component.set("v.oppCreated", true);
                                                   }
                                                   component.set("v.oppSent", true);
                                                   component.set("v.spinner", false);
                                                   window.setTimeout($A.getCallback(function() {
                                                       $A.get("e.force:closeQuickAction").fire()
                                                       $A.get('e.force:refreshView').fire();
                                                   }), 4000);
                                               }
                    });                    
                    $A.enqueueAction(action);*/                }
                }
            }
        }
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
        var totalRemainingItems = component.find('totalRemaining');
        var allValid = false;
        if (totalRemainingItems.length > 1)
        {
            allValid = component.find('totalRemaining').reduce(function (validSoFar, inputCmp)
                                                               {
                                                                   inputCmp.reportValidity();
                                                                   return validSoFar && inputCmp.checkValidity();
                                                               }, true);
        }
        else
        {
            totalRemainingItems.reportValidity();
            allValid = totalRemainingItems.checkValidity();
        }
        if (allValid) 
        {
            component.set("v.isValid", true);
        }
        else
        {
            component.set("v.isValid", false);
        }
        return allValid;
    },
    calculateTotal : function(component, event)
    {
        var contractLineItems = component.get("v.contractLineItems");
        var totalRemainingItems = component.find("totalRemaining");
        for (var i=0; i<totalRemainingItems.length; i++)
        {
            contractLineItems[i].New_Total__c = contractLineItems[i].Sales_Price__c * (1 - contractLineItems[i].Discount__c) * contractLineItems[i].Total_Quantity__c;
        }
        component.set("v.contractLineItems", contractLineItems);
        console.log(contractLineItems);        
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