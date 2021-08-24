({
    
    ApprovalValidation : function (component, helper){
        component.set("v.spinner", true);
        var comments = component.find("comments").get("v.value");
        var opportunity = component.get("v.opportunity");
        
        if (opportunity.Approval_Status__c == "Pending")
        {      
            helper.showToast("error",$A.get("$Label.c.Status_Pending_Title"),$A.get("$Label.c.Status_Pending_Error_Msg"));
        }
        /*else if (opportunity.Sales_Organization_User_Code__c != 'RU01')
        {
            helper.showToast("error",$A.get("$Label.c.Sales_Org_Code_Title"),$A.get("$Label.c.Sales_Org_Code_Error_Msg"));
        }*/
        else if (opportunity.Sales_Organization_User_Code__c == 'IN01')
        {
            helper.showToast("error",$A.get("$Label.c.Sales_Org_Code_Title"),"The approval process is not available for IN01");
        }
        else if (opportunity.Attachment_Attached__c == false)
        {
            helper.showToast("error",$A.get("$Label.c.Attachment_Attached_Title"),$A.get("$Label.c.Attachment_Attached_Error_Msg"));
        }
        else if (opportunity.Approver_1__c == null)
        {
            helper.showToast("error",$A.get("$Label.c.Approver_1_Title"),$A.get("$Label.c.Approver_1_Error_Msg"));
        }
		else
        {
            if(opportunity.Approval_Status__c == 'Approved' || opportunity.Approval_Status__c == 'Revision'){
                opportunity.Approval_1_Approved__c = false;
                opportunity.Approval_2_Approved__c = false;
                opportunity.Approval_3_Approved__c = false;
                opportunity.Approval_4_Approved__c = false;
                opportunity.Approval_5_Approved__c = false;
                opportunity.Approval_6_Approved__c = false;
                opportunity.Approval_7_Approved__c = false;
                opportunity.Approval_8_Approved__c = false;
                opportunity.Approval_9_Approved__c = false;
                opportunity.Approval_10_Approved__c = false;
                
                component.find("record").saveRecord($A.getCallback(function(saveResult) {
                    if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {}
                }));
            }
            var action = component.get("c.SubmitForApproval");
            action.setParams({ "opp" : opportunity,
                              "comments" : comments});
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.spinner", false);
                    if(response.getReturnValue() == true)
                        helper.showToast("success","Success","Submit for Approval sucessfully");
                    else 
                        helper.showToast("error","Error","Submit for Approval Error");
                    $A.get("e.force:closeQuickAction").fire();
                    $A.get('e.force:refreshView').fire();
                    
                }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + errors[0].message);
                            component.set("v.spinner", false);
                            helper.showToast("error","Error","Cannot submit for Approval. Please contact System Administrator");
                        }
                    }
                }
            });
            $A.enqueueAction(action);
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
    }
})