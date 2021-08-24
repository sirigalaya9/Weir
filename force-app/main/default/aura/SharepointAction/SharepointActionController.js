({
    doInit : function(component, event, helper) 
    {              
    },
    handleRecordUpdated :function(component, event, helper) 
    {
    	console.log('handleRecordUpdated');
        var changeType = event.getParams().changeType;
        console.log(changeType);
        var eventParams = event.getParams();
		if (changeType === "ERROR") { /* handle error; do this first! */ }
    	else if (changeType === "LOADED") 
        {
            $A.enqueueAction(component.get('c.doLoadRecord'));
        }
    	else if (changeType === "REMOVED") { /* handle record removal */ }
    	else if (changeType === "CHANGED") 
        {
            // get the fields that changed for this record
            var changedFields = eventParams.changedFields;
            console.log('Fields that are changed: ' + JSON.stringify(changedFields));
            // record is changed, so refresh the component (or other component logic)
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Initiated",
                "message": "Sharepoint folder creation has been initiated. Please try again in a while.",
                "type": "info"
            });
            resultsToast.fire();
			// Close the action panel
            var dismissActionPanel = $A.get("e.force:closeQuickAction");
            dismissActionPanel.fire();              
        }        
       
    },
    doLoadRecord : function(component, event, helper) 
    {
        var action = component.get("c.userHasAccess");
        action.setParams({ recordId : component.get("v.recordId") });
        action.setCallback(this, function(response) 
        {
            var state = response.getState();
            if (state === "SUCCESS") 
            {                    
                var result = response.getReturnValue();
                console.log("From server: " + result);
                if (result == true) //If user has access to click the button
                {
                    let simpleRecord = component.get("v.simpleRecord");
                    console.log(simpleRecord.Name);
                    console.log(simpleRecord.Enable_Sharepoint__c);
                    console.log(simpleRecord.Sharepoint_URL__c);
                    if (simpleRecord.Enable_Sharepoint__c == false)
                    {
                        component.set("v.simpleRecord.Enable_Sharepoint__c", true);                
                        $A.enqueueAction(component.get('c.doSaveRecord'));
                    }
                    else
                    {
                        if (simpleRecord.Sharepoint_URL__c == null)
                        {
                            var resultsToast = $A.get("e.force:showToast");
                            resultsToast.setParams({
                                "title": "In Progress",
                                "message": "Sharepoint folders are being created. Please try again in a while.",
                                "type": "info"
                            });
                            resultsToast.fire();                       
                        }
                        else
                        {
                            var urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                              "url": simpleRecord.Sharepoint_URL__c
                            });
                            urlEvent.fire();                    
                        }
                        // Close the action panel
                        var dismissActionPanel = $A.get("e.force:closeQuickAction");
                        dismissActionPanel.fire();                  
                    }          
                }
                else  //If user DOES NOT have access to click the button
                {
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Permission Denied",
                        "message": "You do not have the permission for this. Please contact System Admin.",
                        "type": "error"
                    });
                    resultsToast.fire(); 
                    // Close the action panel
                    var dismissActionPanel = $A.get("e.force:closeQuickAction");
                    dismissActionPanel.fire();                        
                }
            }
            else if (state === "INCOMPLETE") 
            {
                // do something
            }
            else if (state === "ERROR") 
            {
                var errors = response.getError();
                if (errors) 
                {
                    if (errors[0] && errors[0].message) 
                    {
                        console.log("Error message: " + errors[0].message);
                    }
                }
                else
                {
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
    doSaveRecord : function(component, event, helper) 
    {        
        component.find("recordHandler").saveRecord($A.getCallback(function(saveResult) 
        {
            // use the recordUpdated event handler to handle generic logic when record is changed
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") 
            {
                // handle component related logic in event handler
            } 
            else if (saveResult.state === "INCOMPLETE") 
            {
                console.log("User is offline, device doesn't support drafts.");
            } 
            else if (saveResult.state === "ERROR") 
            {
                console.log('Problem saving record, error: ' + JSON.stringify(saveResult.error));
            } 
            else 
            {
                console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
            }
        }));
    },    
})