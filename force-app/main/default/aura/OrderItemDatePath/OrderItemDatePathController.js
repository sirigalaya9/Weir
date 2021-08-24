({
    recordUpdated : function(component, event, helper) {
        var record = component.get("v.orderItem");
    
        if(typeof record != 'undefined' && record != null)
        {
            var PlannedGoodsIssueDate; 
            
            if(record.X1st_Planned_Goods_Issue_Date__c != null)
                PlannedGoodsIssueDate = new Date(record.X1st_Planned_Goods_Issue_Date__c);
            else
                PlannedGoodsIssueDate = new Date(record.Good_Issue_Date__c);
            
            var estimatedShippingTime = record.Estimated_Shipping_Time__c;
            var Lead_Time_Balance;
            
            if(record.Actual_Goods_Issue_Date__c != null && typeof record.Actual_Goods_Issue_Date__c != 'undefined')
            {
                var actualGoodsIssueDate = new Date(record.Actual_Goods_Issue_Date__c);
                Lead_Time_Balance = (PlannedGoodsIssueDate - actualGoodsIssueDate) /8.64e7;
            }
            else if(record.Good_Issue_Date__c != null && typeof record.Good_Issue_Date__c != 'undefined')
            {
				var estimatedDeliveryDate = new Date(record.Good_Issue_Date__c);
                Lead_Time_Balance = (PlannedGoodsIssueDate - estimatedDeliveryDate) /8.64e7;
            }
            console.log('Lead_Time_Balance '+Lead_Time_Balance);
            
            var cmpTarget = component.find('changeColor');
            if(Lead_Time_Balance >= 0)
            { 
                $A.util.addClass(cmpTarget, 'green');
            }
            else if (Lead_Time_Balance >= -7)
            {
                $A.util.addClass(cmpTarget, 'red');
            }
            else (Lead_Time_Balance > -7)
            {
                $A.util.addClass(cmpTarget, 'red');
            }
            
            /*record.Delivery_Date_Calculated__c = Delivery_Date_Calculated;
            component.find("recordEdit").saveRecord($A.getCallback(function(saveResult) {
                if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                    console.log('Updated Delivery_Date_Calculated');
                }}));*/
            
            //component.set("v.Delivery_Date_Calculated",Delivery_Date_Calculated.toISOString());
            component.set("v.Lead_Time_Balance", Lead_Time_Balance);
            
            
        }
	}
})