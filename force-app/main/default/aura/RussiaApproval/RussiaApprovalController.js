({
    
    Submit: function(component, event, helper) {
        helper.ApprovalValidation(component, helper);
    },
    
    Clear: function(component, event, helper) {
        component.set("v.spinner", true);
        component.find("comments").set("v.value", "");
        component.set("v.spinner", false);
    },
    
    Cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})