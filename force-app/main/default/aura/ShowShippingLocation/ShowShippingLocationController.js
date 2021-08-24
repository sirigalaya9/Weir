({
    init: function (cmp, event, helper) {       
        var action = cmp.get("c.getShippingLocation");
        action.setParams({
            "arecordId": cmp.get("v.recordId")
        });
        
        action.setCallback(this, function(response) {           
            var state = response.getState();
            if (state == "SUCCESS") {
                var obj = response.getReturnValue() ;
                cmp.set('v.mapMarkers', obj);
                cmp.set('v.zoomLevel', 16);
            }
        });
        
        $A.enqueueAction(action);
    }
})