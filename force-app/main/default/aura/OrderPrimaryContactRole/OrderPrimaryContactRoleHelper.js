({
    submitHelper: function(component,event,helper) {
        let res = component.find("recordEditForm");
        var allValid = true;
        var PrimaryContactId = component.get("v.PrimaryContactId");
        console.log("PrimaryContactId "+component.get("v.PrimaryContactId"));
        var ContactField = component.find("ContactField");
        var RoleField = component.find("RoleField");
        var isPrimaryField = component.find("isPrimaryField");
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
                console.log("ContactField ID : "+i+' '+ContactField[i].get("v.value"));
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
            if (res instanceof Array){
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
            viewRecordEvent.fire(); 
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
    
    getPrimaryContact: function(component, event) 
    {
        component.set("v.isLoading", true);
        var parentRecordId = component.get("v.parentRecordId");
        var action = component.get("c.getPrimaryContact");
        action.setParams({ 
            'parentId' : parentRecordId });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var records = response.getReturnValue();
                if(records.length > 0) {
                    records.forEach(function(record){
                        if(record.Is_Primary__c == true){
                            console.log('Primary '+record.Contact__r.Name);
                            component.set("v.PrimaryContactName", record.Contact__r.Name);
                            component.set("v.PrimaryContactId", event.Contact__c);
                            component.find("userinput").set("v.disabled", true);
                            
                        }
                    });
                }
                else{
                    component.find("userinput").set("v.type", "search");
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