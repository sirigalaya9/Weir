({
	doInit : function(component, event, helper) {
        /*let res = component.find("recordEditForm");
        var Contacts = component.get("v.searchRecords");
        var ContactField = component.find("ContactField");
        var ContactIds = [];
        for (var i = 0; i < Contacts.length; i++){
            ContactIds.push(Contacts[i].Id);
            console.log("Contact "+i+' '+ContactIds[i]);
            ContactField[i].set("v.value",Contacts[i].Id);
        }*/
        helper.getPrimaryContact(component, event);
    },
    
    handleLoad: function (component, event, helper) {
        var Contacts = component.get("v.searchRecords");
        var ContactField = component.find("ContactField");
        if (ContactField instanceof Array){
            for (var i = 0; i < Contacts.length; i++){
                ContactField[i].set("v.value",Contacts[i].Id);
            } 
        }
        else {
            ContactField.set("v.value",Contacts[0].Id);
        }
    },
    
    saveRecord: function(component, event, helper) {
        helper.submitHelper(component,event,helper);   
    }, 

    cancel : function(component, event, helper) {
        var parentRecordId = component.get("v.parentRecordId");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: parentRecordId,
                actionName: 'view'
            }
        };
		var navService = component.find("navService");  
        navService.navigate(pageReference);
    },

    searchField : function(component, event, helper) {
        var currentText = event.getSource().get("v.value");
        console.log("currentText : "+currentText);
        var resultBox = component.find('resultBox');
        if(currentText.length > 0) {
            $A.util.addClass(resultBox, 'slds-is-open');
        }
        else {
            $A.util.removeClass(resultBox, 'slds-is-open');
        }
        //helper.fetchData(component, event);  
    },
    
    setSelectedRecord : function(component, event, helper) {
        var resultBox = component.find('resultBox');
        $A.util.removeClass(resultBox, 'slds-is-open');
        component.set("v.PrimaryContactName", event.currentTarget.dataset.name);
        component.set("v.PrimaryContactId", event.currentTarget.id);
        console.log("selectRecordId "+event.currentTarget.id);
    }, 
    
    Back : function(component,event,helper){
        console.log('Enter Here');
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:AddContactRoles",
            componentAttributes: {
                dataSelected: component.get('v.searchRecords'),
                parentRecordId: component.get('v.parentRecordId')
            }
        });
       
    evt.fire();
    }
})