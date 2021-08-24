({
    linkToProduct: function (component, event, helper) {
        var orderItem = component.get("v.orderItem");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            recordId: orderItem.Product2Id,
            slideDevName: "detail"
        });
        navEvt.fire();
    },
    
    linkToMaterial: function (component, event, helper) {
        var orderItem = component.get("v.orderItem");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            recordId: orderItem.Material_Number__c, 
            slideDevName: "detail"
        });
        navEvt.fire();
    } 
})