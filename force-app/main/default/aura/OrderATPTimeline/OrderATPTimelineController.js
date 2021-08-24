({
    doInit : function(component, event, helper) {        

        var recordId = component.get("v.recordId");
        var action = component.get("c.getATPTimeline");        
        action.setParams({ "recordId" : recordId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner", false);
            if (state === "SUCCESS") {                
                var value = response.getReturnValue();
                console.log(value);                
                component.set("v.atpTimelines", value);             
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})