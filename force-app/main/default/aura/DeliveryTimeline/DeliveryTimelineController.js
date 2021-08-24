({
    
    doInit : function(component, event, helper) { 
        var delivery = component.get("v.delivery");
        component.set("v.deliveryItem", delivery.Delivery_Orders__r); 
        console.log(delivery);
        console.log(delivery.Delivery_Orders__r);
    },
    
    toggleAcitivity : function(component, event, helper) {
        // toggle 'slds-is-open' class to expand/collapse activity section
        $A.util.toggleClass(component.find('expId'), 'slds-is-open');
    },
    
    linkToRecord: function (component, event, helper) {
        var delivery = component.get("v.delivery");
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            recordId: delivery.Id,
            slideDevName: "detail"
        });
        navEvt.fire();
    },
    
    linkToDeliveryItem: function (component, event, helper) {
        
        var idx = event.target.getAttribute('data-index');
        var deliveryItem = component.get("v.delivery.Delivery_Orders__r")[idx];
        var navEvent = $A.get("e.force:navigateToSObject");
        if(navEvent){
            navEvent.setParams({
                  recordId: deliveryItem.Id,
                  slideDevName: "detail"
            });
            navEvent.fire(); 
        }
    }
    
})