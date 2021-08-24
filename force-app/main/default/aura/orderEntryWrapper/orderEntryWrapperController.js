({
    goBack : function(component, event, helper) {
        // Close the action panel
        var action = $A.get("e.force:closeQuickAction");
        action.fire();
    }
})