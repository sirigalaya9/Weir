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
    fetchData: function(component, event) 
    {
        component.set("v.isFetchData", true);
        component.set("v.isLoading", true);
        //var selectedRows = component.get('v.selectedRows');
        var rowsSelected = component.get("v.rowsSelected");
        var selectedRows = component.find('ContactsTable').getSelectedRows();
        var setRows = [];
        var setRowsId = [];
        
        //merge from backup
        if (typeof rowsSelected === 'undefined')
        {
            rowsSelected = [];
        }
        if (typeof selectedRows === 'undefined')
        {
            selectedRows = [];
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
        
        for (var i = 0; i < newArray.length; i++){
            setRows.push(newArray[i]);
            setRowsId.push(newArray[i].Id);
        }        

        if(component.get("v.isBacktoResults") == true) var currentText = "";
        else var currentText = event.getSource().get("v.value");
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
            component.set("v.isFetchData", false);
            component.set("v.rowsSelected", setRows);
            component.set("v.selectedRows", setRowsId);
            component.set('v.selectedRowsCount', setRows.length);

            //--Support Back button
            var dataSelected = component.get("v.dataSelected");
            if (dataSelected.length > 0)
            {
                var selectedRowIds = [];
                for (var i = 0; i < dataSelected.length; i++)
                {
                    selectedRowIds.push(dataSelected[i].Id);
                }
                component.set("v.selectedRows", selectedRowIds);
                component.set('v.selectedRowsCount', selectedRowIds.length);                
            }
            //--           
            //component.set('v.selectedRowsCount', selectedRows.length);
        });
        $A.enqueueAction(action);
    },
    
    comparer : function (otherArray){
        return function(current){
            return otherArray.filter(function(other){
                return other.Id == current.Id
            }).length == 0;
        }
    },
    
    getColumnDefinitions: function()
    {
        var columns = [
            { label: 'Name', fieldName: 'NameLink', type: 'url',sortable: true, typeAttributes: {label: {fieldName: "Name"}}},
            {
                label: 'Account Name',
                fieldName: 'AccountNameLink',
                type: 'url',
                sortable: true,
                typeAttributes: {label: {fieldName: "AccountName"}}
            },
            { label: 'Phone', fieldName: 'Phone', type: 'text',sortable: true},
            { label: 'Email', fieldName: 'Email', type: 'text',sortable: true},
            { label: 'Contact Owner Alias', fieldName: 'OwnerAliasName', type: 'text',sortable: true},
        ];
		return columns;
    },
    
    mergeResultToSelected: function(component)
    {
        var selectedRows = component.get("v.dataSelected");
        var selectedRowsResultsCmp = component.find("ContactsTable");                  
        if (typeof selectedRowsResultsCmp !== 'undefined')
        {                     
            var selectedRowsResults = selectedRowsResultsCmp.getSelectedRows();
            var resultRows = component.get("v.data");            
            var selectedRowsNotFromResults = [];
            for (var i = 0; i < selectedRows.length; i++)
            {
                var isFromResults = false;
                for (var j = 0; j < resultRows.length; j++)
                {
                    if (selectedRows[i].Id == resultRows[j].Id)
                    {
                        isFromResults = true;
                        break;
                    }                            
                } 
                if (isFromResults == false)
                {
                    selectedRowsNotFromResults.push(selectedRows[i]);
                }
            }
            selectedRows = selectedRowsNotFromResults;
            for (var i = 0; i < selectedRowsResults.length; i++)
            {
                selectedRows.push(selectedRowsResults[i]);
            }
        }        
        var selectedRowsId = [];
        for (var i = 0; i < selectedRows.length; i++)
        {
            selectedRowsId.push(selectedRows[i].Id);
        }        
        component.set("v.dataSelected", selectedRows);
        component.set("v.selectedRowsSelected", selectedRowsId);
        component.set('v.selectedRowsCount', selectedRowsId.length);            
    },
        
    sortData: function (component, fieldName, sortDirection) {
        var isShowResults = component.get("v.isShowResults");
        var data = [];
        if(isShowResults == true)
            data = component.get("v.dataSelected");
        else
            data = component.get("v.data");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        if(isShowResults == true)
            component.set("v.dataSelected", data);
        else
            component.set("v.data", data);
        
    },
        
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
            
})