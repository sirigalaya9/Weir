({
    getParameterByName: function(component, event, name)
    {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    
    submitHelper: function(component,event,helper) {
        let res = component.find("recordEditForm");
        var allValid = true;
        var PrimaryContactId = component.get("v.PrimaryContactId");
        console.log("PrimaryContactId "+component.get("v.PrimaryContactId"));
        var ContactField = component.find("ContactField");
        var ContactNameField = component.find("ContactNameField");
        var RoleField = component.find("RoleField");
        var isPrimaryField = component.find("isPrimaryField");
        var IdField = component.find("IdField");
        if (res){
            if (res instanceof Array){
                console.log("Array of "+res.length);
                res.forEach(function(v,i) {
                    var isContactValid = true;
                    isContactValid = ContactField[i].reportValidity();
                    if(isContactValid == false){
                        allValid = false;
                    }
                    console.log("allValid : "+allValid);
                    if(ContactField[i].get("v.value") ==  PrimaryContactId){
                        isPrimaryField[i].set("v.value",true);
                    }
                    else
                        isPrimaryField[i].set("v.value",false);
                    console.log("IdField : "+i+' '+IdField[i].get("v.value"));
                    console.log("ContactField ID : "+i+' '+ContactField[i].get("v.value"));
                    console.log("ContactNameField : "+i+' '+ContactNameField[i].get("v.value"));
                    console.log("Contact ROLE : "+i+' '+RoleField[i].get("v.value"));
                    console.log("isPrimary : "+i+' '+isPrimaryField[i].get("v.value")); 
                });
            }
            else{
                if(ContactField.reportValidity() == false){
                    allValid = false;
                }
                console.log("allValid : "+allValid);
                if(ContactField.get("v.value") ==  PrimaryContactId){
                    isPrimaryField.set("v.value",true);
                }
            }
            
            if(allValid == true){
                var orderContactRoles = [];
                if(res instanceof Array){
                    res.forEach(function(v,i) {
                        var orderContactRole = {}; 
                        orderContactRole.Id = IdField[i].get("v.value");
                        orderContactRole.Contact__c = ContactField[i].get("v.value");
                        orderContactRole.Role__c = RoleField[i].get("v.value");
                        orderContactRole.Is_Primary__c = isPrimaryField[i].get("v.value");
                        orderContactRole.Order__c = component.get("v.parentRecordId");
                        orderContactRoles.push(orderContactRole);
                    }); 
                    
                }
                else{
                    var orderContactRole = {}; 
                    orderContactRole.Id = IdField.get("v.value");
                    orderContactRole.Contact__c = ContactField.get("v.value");
                    orderContactRole.Role__c = RoleField.get("v.value");
                    orderContactRole.Is_Primary__c = isPrimaryField.get("v.value");
                    orderContactRole.Order__c = component.get("v.parentRecordId");
                    orderContactRoles.push(orderContactRole);
                }
                
                
                var action = component.get("c.createOrUpdateOrderContactRole");
                action.setParams({ ordContactRoles : orderContactRoles });
        		action.setCallback(this, function(response)
				{
                    var state = response.getState();
                    var context = component.get("v.UserContext");
                    
                    if (state === "SUCCESS") 
                    {
                        if(context != undefined) 
                        {
                            if(context == 'Theme4t' || context == 'Theme4d') 
                            {
                                console.log('VF in S1 or LEX');
                                sforce.one.showToast({         
                                    "message": "Edit Order Contact Roles Sucessfully",
                                    "type": "success"
                                });                        
                                sforce.one.navigateToSObject(component.get("v.parentRecordId"), "related");
                            } 
                            else 
                            {
                                console.log('VF in Classic'); 
                                //var contactId = component.get("v.contact").Id;
                                //window.location.assign('/'+contactId);
                            }
                        } 
                        else 
                        {
                            console.log('standalone Lightning Component');
                            helper.showToast("success","Success","Edit Order Contact Roles Sucessfully");
                            var viewRecordEvent = $A.get("e.force:navigateToURL");
                            viewRecordEvent.setParams({
                                "url": "/" + component.get("v.parentRecordId")
                            });
                            viewRecordEvent.fire();
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
                            if (errors[0] && errors[0].pageErrors[0]) 
                            {
                                console.log("Error message: " + errors[0].pageErrors[0].message);
                                if(context != undefined) 
                                {
                                    if(context == 'Theme4t' || context == 'Theme4d') 
                                    {
                                        console.log('VF in S1 or LEX');
                                        sforce.one.showToast({         
                                            "message": errors[0].pageErrors[0].message,
                                            "type": "error"
                                        });                                                                
                                    } 
                                    else 
                                    {
                                        console.log('VF in Classic');
                                    }
                                }
                                else 
                                {
                                    console.log('standalone Lightning Component');
                                    helper.showToast("error","Error",errors[0].pageErrors[0].message);
                                }                                
                            }
                        } 
                        else 
                        {
                            console.log("Unknown error");
                        }
                    }
                });       	
                $A.enqueueAction(action);
                
                /*if (res instanceof Array){
                res.forEach(function(v,i){
                    v.submit();
                });
            }
            else{
                res.submit();
            }
            helper.showToast("success","Success","Add Order Contact Roles Sucessfully");
            var viewRecordEvent = $A.get("e.force:navigateToURL");
            viewRecordEvent.setParams({
                "url": "/" + component.get("v.parentRecordId")
            });
            viewRecordEvent.fire(); */
            }
        }
    },
    
    showToast : function (type, title, message) {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "type": type,
            "title": title,
            "message": message});
        resultsToast.fire();
    },
    
    getOrderContactRoles: function(component, event) 
    {
        component.set("v.isLoading", true);
        var parentRecordId = component.get("v.parentRecordId");
        
        var action = component.get("c.getOrderContactRoles");
        action.setParams({ 
            'parentId' : parentRecordId });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records = response.getReturnValue();
                console.log('records '+records);
                component.set("v.searchRecords",records);
                component.set("v.recordEditRecords",records);
                var ContactField = component.find("ContactField");
                var RoleField = component.find("RoleField");
                var ContactNameField = component.find("ContactNameField");
                var AccountNameField = component.find("AccountNameField");
                var IdField = component.find("IdField");
                if(records.length > 0) {
                    if(records.length > 1)
                    {
                        var found = false;
                        //records.forEach(function(record){
                        for (var i = 0; i < records.length; i++){
                            ContactField[i].set("v.value",records[i].Contact__c);
                            ContactNameField[i].set("v.value",records[i].ContactName__c);
                            AccountNameField[i].set("v.value",records[i].AccountName__c);
                            IdField[i].set("v.value",records[i].Id);
                            RoleField[i].set("v.value",records[i].Role__c);
                            if(records[i].Is_Primary__c == true && found == false){
                                console.log('Primary : '+records[i].Contact__r.Name);
                                //component.find("userinput").set("v.value", records[i].Contact__c);
                                component.set("v.PrimaryContactName", records[i].Contact__r.Name);
                                component.set("v.PrimaryContactId", records[i].Contact__c); 
                                found = true;
                            }
                        } 
                    }
                    else
                    {
                        ContactField.set("v.value",records[0].Contact__c);
                        ContactNameField.set("v.value",records[0].ContactName__c);
                        AccountNameField.set("v.value",records[0].AccountName__c);
                        IdField.set("v.value",records[0].Id);
                        RoleField.set("v.value",records[0].Role__c);
                        if(records[0].Is_Primary__c == true){
                            component.set("v.PrimaryContactName", records[0].Contact__r.Name);
                            component.set("v.PrimaryContactId", records[0].Contact__c); 
                        }
                    }
                }
                else{
                    console.log('No searchRecords');
                }
                component.set("v.isLoading", false);
            }
        });
        $A.enqueueAction(action);
    },
    
    /*getParameterByName: function(component, event, name)
    {
        name = name.replace(/[\[\]]/g, "\\$&");
        var url = window.location.href;
        var regex = new RegExp("[?&]" + name + "(=1\.([^&#]*)|&|#|$)");
        var results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, " "));
    },
    fetchData: function(component, event) 
    {
        component.set("v.isLoading", true);
        var currentText = event.getSource().get("v.value");
        var parentRecordId = component.get("v.parentRecordId");
        var action = component.get("c.fetchData");
        action.setParams({ 
            'searchKeyWord': currentText,
            'parentId' : parentRecordId });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records = response.getReturnValue();
                component.set("v.searchRecords", records);
                if(component.get("v.searchRecords").length == 0) {
                    console.log('No searchRecords');
                }
                records.forEach(function(record){
                    record.NameLink = '/'+record.Id;
                    record.AccountNameLink = '/'+record.AccountId;
                    record.AccountName = record.Account.Name;
                    record.OwnerAliasName = record.Owner.Alias;
                });
                component.set("v.data", records);
            }
            component.set("v.isLoading", false);
        });
	 	$A.enqueueAction(action);
    },
    getColumnDefinitions: function()
    {
        var columns = [
            { label: 'Name', fieldName: 'NameLink', type: 'url', typeAttributes: {label: {fieldName: "Name"}}},
            {
                label: 'Account Name',
                fieldName: 'AccountNameLink',
                type: 'url',
                typeAttributes: {label: {fieldName: "AccountName"}}
            },
            { label: 'Phone', fieldName: 'Phone', type: 'text'},
            { label: 'Email', fieldName: 'Email', type: 'text'},
            { label: 'Contact Owner Alias', fieldName: 'OwnerAliasName', type: 'text'},
        ];
		return columns;
    }*/
})