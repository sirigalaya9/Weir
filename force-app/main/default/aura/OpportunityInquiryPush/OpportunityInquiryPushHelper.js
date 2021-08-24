({
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
                    helper.showToast("error","Error","Only SGT Profiles can submit inquiry");
                }
                else if (oppList[0].Integration_Status__c == 'In Progress')
                {
                    helper.showToast("Warning","Error","Inquiry Creation is In Progress...");
                }
                else if (oppList[0].Integration_Status__c == 'Completed')
                {
                    helper.showToast("Warning","Error","Inquiry has been already created in SAP");
                }
                else if (oppList[0].StageName != 'Bid Preparation' && oppList[0].StageName != 'Negotiation')
                {
                    helper.showToast("error","Error","Only Bid Preparation and Negotiation Stage can be submitted");
                }
                else if (typeof oppList[0].Shipping_Address__c == 'undefined')
                {
                    helper.showToast("error","Error","Shipping Address is Empty");
                }
                else if (typeof oppList[0].Division__c == 'undefined')
                {
                    helper.showToast("error","Error","Division is Empty");
                }
                else if (typeof oppList[0].Channel__c == 'undefined')
                {
                    helper.showToast("error","Error","Distribution Channel is Empty");
                }
                else if (typeof oppList[0].Expected_Delivery_Date__c == 'undefined')
                {
                    helper.showToast("error","Error","Expected Delivery Date is Empty ");
                }
                else if (typeof oppList[0].Application__c == 'undefined')
                {
                    helper.showToast("error","Error","Application is Empty");
                }
                else if (typeof oppList[0].OpportunityLineItems == 'undefined')
                {
                    helper.showToast("error","Error","There is no Opportunity Product");
                }
                else if (oppList[0].OpportunityLineItems.length > 0)
                { 
                    //alert("OpportunityLineItems.length "+oppList[0].OpportunityLineItems.length);
                    var allProductHasMaterial = true;
                    for(var i=0; i<oppList[0].OpportunityLineItems.length; i++)
                    {  
                        var itemNo = i+1;
                        if(typeof oppList[0].OpportunityLineItems[i].Material_Number__c == 'undefined')
                        {
                            allProductHasMaterial = false;
                            helper.showToast("error","Material Number!","Opportunity Product No."+itemNo+" has no Material Number");
                        }
                    }
                    if(allProductHasMaterial == true)
                    {
                        var action = component.get("c.CreateProspectAndInquiryToSAP");
                        action.setParams({"oppList":response.getReturnValue()});
                        action.setCallback(this, function(response)
                                           {
                                               var status = response.getState();
                                               if(status == "SUCCESS")
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
                        $A.enqueueAction(action);
                    }
                }
            }
        }
        else if (state === "ERROR") {
            var errors = response.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    console.log("Error message: " + errors[0].message);
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
})