({
	doInit : function(component, event, helper) 
    { 
        var parentRecordId = component.get('v.parentRecordId');
        if(parentRecordId != null && typeof parentRecordId != 'undefined'){
            component.set("v.parentRecordId", parentRecordId);	
        }
        else{
            var value = helper.getParameterByName(component, event, 'inContextOfRef');
            var context = JSON.parse(window.atob(value));
            component.set("v.parentRecordId", context.attributes.recordId);	  
        }
        component.set('v.columns', helper.getColumnDefinitions());  
        helper.fetchData(component, event);
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
        helper.fetchData(component, event);  
    },
    
    updateRowSelected : function(component, event, helper) {
        var rowsSelected = component.get("v.rowsSelected");
        var tempRows = [];
        for (var i = 0; i < rowsSelected.length; i++){
            tempRows.push(rowsSelected[i]);
        }
        var isFetchData = component.get("v.isFetchData");
        //var uncheckedArray = component.get("v.rowsSelected");
        var selectedRows = event.getParam('selectedRows');
        var selectedRowCom = component.get("v.selectedRows");
        var dropdownSelectedRow = component.get('v.dropdownSelectedRow');
        console.log("rowsSelected : "+rowsSelected.length);
        console.log("selectedRows : "+selectedRows.length);
        console.log("selectedRowCom : "+selectedRowCom.length);
        
        if(selectedRows.length < rowsSelected.length && isFetchData == false){
            var uncheckedArray = rowsSelected;
            for (var i = 0; i < selectedRows.length; i++){
                var found = false;
                for (var j = 0; j < uncheckedArray.length; j++){
                    if(selectedRows[i].Id == uncheckedArray[j].Id && found == false)
                    {
                        //uncheckedArray.push(selectedRows[i]);
                        console.log(uncheckedArray[j].Name);
                        uncheckedArray.splice(j,1);
                        found = true;
                    }
                }
                //var temp = uncheckedArray.find(j => j.Id === selectedRows[i].Id))
                    //uncheckedArray.splice(i,1); // Remove Selected from Backup       
            }
            
            for (var i = 0; i < dropdownSelectedRow.length; i++){
                var found = false;
                for (var j = 0; j < uncheckedArray.length; j++){
                    if(dropdownSelectedRow[i].Id == uncheckedArray[j].Id && found == false)
                    {
                        console.log(uncheckedArray[j].Name);
                        uncheckedArray.splice(j,1);
                        found = true;
                    }
                }      
            }
            
            rowsSelected = tempRows;
            for (var i = 0; i < uncheckedArray.length; i++){
                var found = false;
                for (var j = 0; j < rowsSelected.length; j++){
                    if(uncheckedArray[i].Id == rowsSelected[j].Id && found == false)
                    {
                        rowsSelected.splice(j,1);
                        console.log("splice : "+rowsSelected[j].Name);
                        found = true;
                    }
                }      
            }
            //rowsSelected.splice(uncheckedArray,1); // Remove Deselected row from Backup
            //component.set("v.rowsSelected", rowsSelected);
        }

        var mergedRows = rowsSelected.concat(selectedRows);
        var newArray = [];
        var lookupObject  = {};
        for(var i in mergedRows) 
        {
            lookupObject[mergedRows[i]['Id']] = mergedRows[i];
        }
        for(i in lookupObject) 
        {
            newArray.push(lookupObject[i]);
        }
        var setRows = [];
        var setRowsId = [];
        for (var i = 0; i < newArray.length; i++){
            setRowsId.push(newArray[i].Id);
            setRows.push(newArray[i]);
        }

        console.log(setRows);
        component.set("v.selectedRows", setRowsId);
        component.set("v.rowsSelected", setRows);
        component.set('v.selectedRowsCount', setRowsId.length);
        component.set("v.isFetchData", false);
    },  
       
    setSelectedRecord : function(component, event, helper) {
        var resultBox = component.find('resultBox');
        var rowsSelected = component.get("v.rowsSelected");
        var selectedRows = component.get('v.selectedRows');
        var searchRecords = component.get('v.searchRecords');
        var dropdownSelectedRow = component.get('v.dropdownSelectedRow');
        var seletedRow = [];
        var setRows = [];
        var setRowsId = [];
        $A.util.removeClass(resultBox, 'slds-is-open');
        //component.set("v.selectRecordName","");
        //component.set("v.selectRecordId", event.currentTarget.id);
        for (var i = 0; i < searchRecords.length; i++){
            seletedRow = searchRecords.find(j => j.Id === event.currentTarget.id);   
        }
        
        for (var i = 0; i < rowsSelected.length; i++){
            setRows.push(rowsSelected[i]);
        } 
        
        for (var i = 0; i < selectedRows.length; i++){
            setRowsId.push(selectedRows[i]);
        }
        
        dropdownSelectedRow.push(seletedRow);
        
        setRows.push(seletedRow);
        setRowsId.push(event.currentTarget.id);
        console.log(setRows);
        console.log(setRowsId);
        component.set("v.dropdownSelectedRow", dropdownSelectedRow); 
        component.set("v.rowsSelected", setRows); 
        component.set("v.selectedRows", setRowsId); 
        component.set('v.selectedRowsCount', setRows.length);
    },
       
    showSelected :function(component,event,helper){
        var records = [];
        var setRows = [];
        var rowsSelected = component.get('v.rowsSelected');
        records = component.find('ContactsTable').getSelectedRows();
        
        if (typeof records === 'undefined')
        {
            records = [];
        }    
        
        var mergedRows = rowsSelected.concat(records);
        var newArray = [];
        var lookupObject  = {};
        for(var i in mergedRows) 
        {
            lookupObject[mergedRows[i]['Id']] = mergedRows[i];
        }
        for(i in lookupObject) 
        {
            newArray.push(lookupObject[i]);
        }
        var setRows = [];
        var setRowsId = [];
        for (var i = 0; i < newArray.length; i++){
            setRows.push(newArray[i]);
            setRowsId.push(newArray[i].Id);
        }
        
        setRows.forEach(function(record){
            record.NameLink = '/'+record.Id;
            record.AccountNameLink = '/'+record.AccountId;
            record.AccountName = record.Account.Name;
            record.OwnerAliasName = record.Owner.Alias;
        });
        component.set("v.data", setRows);
        component.set("v.selectedRows", setRowsId); 
        component.set("v.isShowResults", true);        
    },
    
    gotoPrimaryContact:function(component,event,helper){
        var evt = $A.get("e.force:navigateToComponent");
        /*
        var records = [];
        var setRows = [];
        var rowsSelected = component.get('v.rowsSelected');
        records = component.find('ContactsTable').getSelectedRows();
        
        if (typeof records === 'undefined')
        {
            records = [];
        }    
        
        var mergedRows = rowsSelected.concat(records);
        var newArray = [];
        var lookupObject  = {};
        for(var i in mergedRows) 
        {
            lookupObject[mergedRows[i]['Id']] = mergedRows[i];
        }
        for(i in lookupObject) 
        {
            newArray.push(lookupObject[i]);
        }
        var setRows = [];
        var setRowsId = [];
        for (var i = 0; i < newArray.length; i++){
            setRows.push(newArray[i]);
            setRowsId.push(newArray[i].Id);
        }		
        console.log('setRows '+setRows);
        */
        evt.setParams({
            componentDef: "c:OrderPrimaryContactRole",
            componentAttributes: {
                searchRecords: component.get("v.dataSelected"),
                parentRecordId: component.get('v.parentRecordId')
            }
        });
        evt.fire();
    },
    
    BacktoResults :function(component,event,helper){
        component.set("v.isShowResults", false);
        component.set("v.isBacktoResults", true);
        helper.fetchData(component, event);  
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
    
    keyCheck : function(component, event, helper){
        if (event.which == 13){
            var resultBox = component.find('resultBox');
            $A.util.removeClass(resultBox, 'slds-is-open');
        }
    },
    contactChanged : function(component, event, helper)
    {
    	var contactId = event.getParam("value")[0];
        console.log('Lookup Selected: ' + contactId);
        var action = component.get("c.fetchDataById");
        action.setParams({ 'recordId': contactId });
        action.setCallback(this, function(response)
        {
            var state = response.getState();
            if (state === "SUCCESS") 
            {
                var record = response.getReturnValue();                
                record.NameLink = '/'+record.Id;
                record.AccountNameLink = '/'+record.AccountId;
                record.AccountName = record.Account.Name;
                record.OwnerAliasName = record.Owner.Alias;   

                helper.mergeResultToSelected(component);
                component.set("v.isShowResults", true);
                
                var selectedRows = component.get("v.dataSelected"); 
                //-- Prevent duplicate record selection from search
                var isRecordSelected = false;
                for (var i = 0; i < selectedRows.length; i++)
                {
                    if (selectedRows[i].Id == record.Id)
                    {
                        isRecordSelected = true;
                        break;
                    }
                }
                if (isRecordSelected == false)
                {
                	selectedRows.push(record);    
                }
                //--
                var selectedRowsId = [];
                for (var i = 0; i < selectedRows.length; i++)
                {
                    selectedRowsId.push(selectedRows[i].Id);
                }
                component.set("v.dataSelected", selectedRows);
                component.set("v.selectedRowsSelected", selectedRowsId);
                component.set('v.selectedRowsCount', selectedRowsId.length); 
                event.getSource().reset(); 

            }
        });
        $A.enqueueAction(action);        
    },
    rowSelected : function(component, event, helper)
    {        
        helper.mergeResultToSelected(component);       
    },
    rowSelectedSelected : function(component, event, helper)
    {                
		var selectedRows = component.find("ContactsTableSelected").getSelectedRows();
        component.set('v.dataSelected', selectedRows);        
		component.set('v.selectedRowsCount', selectedRows.length);        
    },
    showSelectedTable : function(component, event, helper)
    {        
		helper.mergeResultToSelected(component);
        component.set("v.isShowResults", true);
    },
    showResultsTable : function(component, event, helper)
    {
        var selectedRows = component.find("ContactsTableSelected").getSelectedRows();
        var selectedRowsId = [];
        for (var i = 0; i < selectedRows.length; i++)
        {
            selectedRowsId.push(selectedRows[i].Id);
        }                
        component.set("v.selectedRows", selectedRowsId);
        component.set('v.selectedRowsCount', selectedRowsId.length);                 
        component.set("v.isShowResults", false); 
    },
    
     updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
})