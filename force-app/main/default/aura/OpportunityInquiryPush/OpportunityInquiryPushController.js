({
    doInit : function(component, event, helper) {
        var oppId = component.get("v.recordId");
        var oppList = {};
        var ErrorMessage = '';
        var MessageRequiredField = '';
        component.set("v.spinner", true);
        var action = component.get("c.ValidateSGTProfile");
        action.setParams({"objId":oppId});
        action.setCallback(this, function(response)
                           {
                               helper.ValidateOpportunity(response, component, helper);
                           });                    
        $A.enqueueAction(action);
    }
})