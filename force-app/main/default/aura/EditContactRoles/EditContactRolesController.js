({
	doInit : function(component, event, helper) {
        var parentRecordId = component.get('v.parentRecordId');
        if(parentRecordId != null && typeof parentRecordId != 'undefined'){
            component.set("v.parentRecordId", parentRecordId);	
        }
        else{
            var value = helper.getParameterByName(component, event, 'inContextOfRef');
            var context = JSON.parse(window.atob(value));
            component.set("v.parentRecordId", context.attributes.recordId);	  
        }
        helper.getProjectContactRoles(component, event);
    },
    
    
    doAdd : function(component, event, helper) {
        
        var projectContactRoles = component.get("v.recordEditRecords");
        var newProjectContactRole ='{"sobjectType": "Project_Contact_Role__c"}';
        var newrojectContactRolParsed = JSON.parse(newProjectContactRole);
        
        projectContactRoles.push(newrojectContactRolParsed);
        
        component.set("v.recordEditRecords", projectContactRoles);
        console.log("projectContactRoles "+projectContactRoles);
        
    },
    
    saveRecord: function(component, event, helper) {
        helper.submitHelper(component,event,helper);   
    }, 

    cancel : function(component, event, helper) {
        var context = component.get("v.UserContext");
        
        if(context != undefined) 
        {
            if(context == 'Theme4t' || context == 'Theme4d') 
            {
                console.log('VF in S1 or LEX');
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
            var viewRecordEvent = $A.get("e.force:navigateToURL");
            viewRecordEvent.setParams({
                "url": "/" + component.get("v.parentRecordId")
            });
            viewRecordEvent.fire();
        }         
        
        /*var parentRecordId = component.get("v.parentRecordId");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: parentRecordId,
                actionName: 'view'
            }
        };
		var navService = component.find("navService");  
        navService.navigate(pageReference);*/
    },
    
    contactChanged : function(component, event, helper)
    {
        var PrimaryContactId = event.getParam("value")[0];
        component.set("v.PrimaryContactId", PrimaryContactId);
        console.log('PrimaryContactId: ' + PrimaryContactId);
    },

    searchField : function(component, event, helper) {
        var currentText = event.getSource().get("v.value");
        console.log("currentText : "+currentText);
        let res = component.find("recordEditForm");
        var ContactField = component.find("ContactField");
        var RoleField = component.find("RoleField");
        var isPrimaryField = component.find("isPrimaryField");
        var ContactNameField = component.find("ContactNameField");
        var AccountNameField = component.find("AccountNameField");
        var IdField = component.find("IdField");
        var projectContactRoles = [];
        //var projectContactRoles = component.get("v.projectContactRoles");
        res.forEach(function(v,i) {
            if(IdField[i].get("v.value") != null){
                var projectContactRole = {}; 
                projectContactRole.Id = IdField[i].get("v.value");
                projectContactRole.Contact__c = ContactField[i].get("v.value");
                projectContactRole.ContactName__c = ContactNameField[i].get("v.value");
                projectContactRole.AccountName__c = AccountNameField[i].get("v.value");
                projectContactRole.Role__c = RoleField[i].get("v.value");
                projectContactRole.Is_Primary__c = isPrimaryField[i].get("v.value");
                projectContactRole.Project__c = component.get("v.parentRecordId");
                projectContactRoles.push(projectContactRole);
            }
        }); 
        
        console.log('projectContactRoles '+projectContactRoles);
        component.set("v.searchRecords",projectContactRoles);
        
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
        var selected = component.get("v.recordEditRecords").find(record => record.Id === event.currentTarget.id);
        component.set("v.PrimaryContactName", selected.ContactName__c);
        component.set("v.PrimaryContactId", selected.Contact__c);
        console.log("selectRecordName "+selected.ContactName__c);
        console.log("selectRecordId "+selected.Contact__c);
    }, 
    
    Back : function(component,event,helper){
        console.log('Enter Here');
        var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef: "c:AddContactRoles",
            componentAttributes: {
                rowsSelected: component.get('v.searchRecords'),
                parentRecordId: component.get('v.parentRecordId')
            }
        });
       
    evt.fire();
    }
})