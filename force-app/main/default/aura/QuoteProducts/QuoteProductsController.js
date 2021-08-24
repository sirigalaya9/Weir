({
    init : function(component, event, helper) 
    {
        component.set("v.spinner", true);

        var recordId = component.get("v.recordId");
        if (typeof recordId === 'undefined')
        {
            var pageReference = component.get("v.pageReference");
            recordId = pageReference.state.c__recordId;
            if (typeof recordId === 'undefined')
            {
                recordId = component.get("v.sourceId");
            }
        }
            
        if (typeof recordId !== 'undefined')
        {            
            component.set("v.sourceId", recordId);
        }
        
        var quoteRecord = component.get("v.quoteRecord");
        
        if (quoteRecord === null)
        {
            var pageReference = component.get("v.pageReference");
            quoteRecord = pageReference.state.c__quoteRecord;
            console.log(typeof quoteRecord);
            console.log('quoteRecord Id '+quoteRecord.Id);
            component.set("v.quoteRecord", quoteRecord);
            component.set("v.quoteCurrency", quoteRecord.CurrencyIsoCode);
            component.set("v.accountId", quoteRecord.AccountId);
 
        }
        
        var allVcRecordTypes = component.get("v.allVcRecordTypes");        
        component.set("v.newQuoteProducts", []);
        component.set("v.QuoteProductToDelete", []);
        component.set("v.currentNewProductIndex", 0);
        
        var action = component.get("c.getAllVCRecordTypes");
        action.setParams({"objectName": 'Variable_Configurator__c'});
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS")
                               {
                                   var VcRecordTypesResponse = response.getReturnValue();
                                   component.set("v.allVcRecordTypes", VcRecordTypesResponse);
                                   helper.GetInitialData(component, event);
                               }
                           });                    
        $A.enqueueAction(action);

    },
    
    sendToSAPjs : function(component, event, helper) {
        var oppId = component.get("v.recordId");
        var oppList = {};
        var ErrorMessage = '';
        var MessageRequiredField = '';
        component.set("v.spinner", true);
        var action = component.get("c.ValidateSGTProfile");
        action.setParams({"objId":oppId});
        action.setCallback(this, function(response)
                           {
                               helper.ValidateOpportunity(response, component, helper);
                           });                    
        $A.enqueueAction(action);
    },
    
    handleCreateOrder : function (component, event) 
    {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED_SCREEN") 
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "Order created successfully.",
                "type": "success"
            });
            toastEvent.fire();            
        }
        else
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Cannot create order. Please contact System Administrator.",
                "type": "error"
            });
            toastEvent.fire();            
        }
        component.set("v.spinner", false);        
        $A.get("e.force:closeQuickAction").fire();
        var recordId = component.get("v.recordId");
        var pageReference = {
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        };
        var navService = component.find("navService");  
        navService.navigate(pageReference);
        
    },
    addProduct : function (component, event, helper)
    {
        var newQuoteProduct = {};
        var newVCProduct = {};
        var newQuoteProducts = component.get("v.newQuoteProducts");
        
        //newQuoteProduct.OpportunityId = component.get("v.sourceId");
        newQuoteProduct.QuoteId = component.get("v.sourceId");
        newQuoteProduct.CreateQuoteSAP_Success__c = false;
        newQuoteProducts.push(newQuoteProduct);
        component.set("v.newQuoteProducts", newQuoteProducts);
        component.set("v.enableQuoteCreation", false);
    },
    productChanged : function (component, event, helper)
    {
        component.set("v.spinner", true);
        var newQuoteProducts = component.get("v.newQuoteProducts");
        var productId = event.getParam("value")[0];
        var index = event.getSource().get("v.class");
        console.log('productId: ' + productId);
        console.log('index: ' + index);
        if (typeof productId !== 'undefined')
        {
            component.set("v.currentNewProductIndex", index);
            var action = component.get("c.getProducts");
            action.setParams({"productId": productId});
            action.setCallback(this, function(response)
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var product = response.getReturnValue();
                                       newQuoteProducts[index].Product2Id = product.Id;
                                       newQuoteProducts[index].Product_Name__c = product.Name;
                                       //newQuoteProducts[index].Description = outputVar.value.Description;
                                   }
                               });
            $A.enqueueAction(action);
            
        }
        else
        {
            newQuoteProducts[index].Product2Id = null;
            newQuoteProducts[index].Product_Name__c = null;   
        }
        component.set("v.newQuoteProducts", newQuoteProducts); 
        component.set("v.spinner", false);
    },
    
    materialChanged : function (component, event, helper)
    {
        component.set("v.spinner", true);
        var newQuoteProducts = component.get("v.newQuoteProducts");
        var materialId = event.getParam("value")[0];
        var index = event.getSource().get("v.class");
        console.log('material: ' + materialId);
        console.log('index: ' + index);
        if (typeof materialId !== 'undefined')
        {
            component.set("v.currentNewProductIndex", index);
            var action = component.get("c.getMaterials");
            action.setParams({"materialId": materialId});
            action.setCallback(this, function(response)
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var material = response.getReturnValue();
                                       if(material != null){
                                           var matName = material.Name;
                                           newQuoteProducts[index].Material_VC__c = matName.substring(0, 2);
                                           newQuoteProducts[index].VC_Type__c = material.VC_Type__c;
                                           newQuoteProducts[index].Is_VC__c = material.Is_VC__c;
                                           newQuoteProducts[index].Variable_Configurator__c = null;
                                           newQuoteProducts[index].Variable_Configurator__r = undefined;
                                           if(typeof newQuoteProducts[index].VC_Type__c !== 'undefined' && newQuoteProducts[index].Is_VC__c === true)
                                           {
                                               newQuoteProducts[index].Is_VC__c = true;
                                               var allVcRecordTypes = component.get("v.allVcRecordTypes");
                                               if(allVcRecordTypes.length > 0){
                                                   for(var i=0; i<allVcRecordTypes.length; i++)
                                                   {
                                                       if(newQuoteProducts[index].VC_Type__c == allVcRecordTypes[i].DeveloperName)
                                                       {
                                                           newQuoteProducts[index].VC_RecordType_Id__c = allVcRecordTypes[i].Id;
                                                           newQuoteProducts[index].Is_VC_Material__c = true;
                                                           break;
                                                       }
                                                   }
                                               }
                                           }
                                           component.set("v.newQuoteProducts", newQuoteProducts);
                                       }
                                   }
                               });                    
            $A.enqueueAction(action);
        }
        else
        {
            //var newQuoteProducts = component.get("v.newQuoteProducts");
            newQuoteProducts[index].Material_Number__c = null;
            newQuoteProducts[index].Material_VC__c = null;
            newQuoteProducts[index].Is_VC__c = false;
            newQuoteProducts[index].Variable_Configurator__c = null;
            newQuoteProducts[index].VCForm_Completed__c = false;
            newQuoteProducts[index].CreateQuoteSAP_Success__c = false;
            newQuoteProducts[index].Is_VC_Material__c = false;
            component.set("v.newQuoteProducts", newQuoteProducts);   
        }
        component.set("v.spinner", false);
        component.set("v.enableQuoteCreation", false);
    },
    
    removeProduct : function(component, event, helper)
    {
        var index = event.getSource().get("v.class");
        var newQuoteProducts = component.get("v.newQuoteProducts");
        var QuoteProductToDelete = component.get("v.QuoteProductToDelete");
        var updatedOpportunityProducts = [];
        if(newQuoteProducts[index].Id != null){
            QuoteProductToDelete.push(newQuoteProducts[index]);
        }
        newQuoteProducts.splice(index, 1);

        component.set("v.newQuoteProducts", newQuoteProducts);
        component.set("v.QuoteProductToDelete", QuoteProductToDelete); 
        component.set("v.enableQuoteCreation", false);
    },

    createProducts : function (component, event, helper)
    {  
        component.set("v.spinner", true);      
        var vcOppItemsWrapList = [];
        
        helper.validate(component, event);
        var isValid = component.get("v.isValid");
        
        if(isValid == true){
        var QuoteProductsForDML = component.get("v.newQuoteProducts");
        var QuoteProductToDelete = component.get("v.QuoteProductToDelete");
        if(QuoteProductsForDML.length > 0)
        {
            /*for(var i=0; i<OpportunityProductsForDML.length; i++)
            {
                var vcOppItemsWrapObj = {};
                if(typeof OpportunityProductsForDML[i].Variable_Configurator__r !== 'undefined'
                   && typeof OpportunityProductsForDML[i].Variable_Configurator__r.Opportunity__c !== 'undefined'
                   && OpportunityProductsForDML[i].CreateQuoteSAP_Success__c !== true)
                { 
                    vcOppItemsWrapObj.vcData = OpportunityProductsForDML[i].Variable_Configurator__r;
                }
                else
                {
                    vcOppItemsWrapObj.vcData = null;
                }
                OpportunityProductsForDML[i].Variable_Configurator__r = undefined;
                vcOppItemsWrapObj.oppLineItemData = OpportunityProductsForDML[i];
                vcOppItemsWrapList.push(vcOppItemsWrapObj);
            }*/
            
            for(var i=0; i<QuoteProductsForDML.length; i++)
            {
                if(QuoteProductsForDML[i].Quantity == null)
                QuoteProductsForDML.splice(i, 1);
            }
        }
        
        if(QuoteProductToDelete.length > 0)
        {
            for(var i=0; i<QuoteProductToDelete.length; i++)
            {
                QuoteProductToDelete[i].Variable_Configurator__r = undefined;
            }
            
        }
        //console.log(JSON.stringify(vcOppItemsWrapList));
        
        var quoteCurrency = component.get("v.quoteCurrency");
        
        var action = component.get("c.QuoteyProductDML2");
        action.setParams({
            'vcQuoteItemsList' : QuoteProductsForDML,
            'QuoteProductToDelete' : QuoteProductToDelete,
            'quoteCurrency' : quoteCurrency
        });
        action.setCallback(this,function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "Product(s) created successfully.",
                    "type": "success"
                });
          
                window.location.href = '/'+component.get("v.sourceId") ;
                
            } else if(state === "ERROR"){
                var errors = action.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error",
                            "message": errors[0].message,
                            "type": "error"
                        });
                        toastEvent.fire(); 
                    }
                }
            }else if (status === "INCOMPLETE") {
                alert('No response from server or client is offline.');
            }
        });       
        $A.enqueueAction(action);
        }
        component.set("v.spinner", false);
        
    },
    
    reInit : function(component, event, helper) {       
        console.log('reInit');     
        var ClickVc = component.get("v.ClickVc");
        
        var pageReference = component.get("v.pageReference");
        var recordId = pageReference.state.c__recordId;
        if (typeof recordId !== 'undefined')
        {
            component.set("v.sourceId", recordId);
            console.log('has recordId: ' + recordId);        
        }
        
        var oppRecord = pageReference.state.c__oppRecord;
        console.log(oppRecord); 
        if (typeof oppRecord === 'object')
        {
            component.set("v.oppRecord", oppRecord);
            console.log(JSON.stringify(oppRecord));
        }
        
        
        if(ClickVc == false)
        {
            var allVcRecordTypes = component.get("v.allVcRecordTypes");
            component.set("v.newQuoteProducts", []);
            component.set("v.vcOppItemsWrap", []);
            component.set("v.QuoteProductToDelete", []);
            component.set("v.currentNewProductIndex", 0);
            
            var action = component.get("c.getAllVCRecordTypes");
            action.setParams({"objectName": 'Variable_Configurator__c'});
            action.setCallback(this, function(response)
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var VcRecordTypesResponse = response.getReturnValue();
                                       component.set("v.allVcRecordTypes", VcRecordTypesResponse);
                                       helper.GetInitialData(component, event);
                                   }
                               });                    
            $A.enqueueAction(action);
        }

        
    },
    
    update : function(component, event, helper) {
        //console.log('url changed');
    },
    toastInfoBackup : function(component, event, helper) {
        console.log('toastInfo: ' +event.getParams().message);
        var str = event.getParams().message;
        var n = str.indexOf("VC");
        if(n >= 0)
        {
            
            var newQuoteProducts = component.get("v.newQuoteProducts");
            var index = component.get("v.currentNewProductIndex");
            var vcName = str.substring(n, 33);
            vcName = vcName.trim();
            console.log('vcName : '+vcName);
            component.set("v.spinner", true);
            
            if (typeof vcName !== 'undefined')
        {
            //component.set("v.currentNewProductIndex", index);
            var action = component.get("c.getVC");
            action.setParams({"vcName": vcName});
            action.setCallback(this, function(response)
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var vcRecord = response.getReturnValue();
                                       console.log('vcRecord : '+vcRecord);
                                       newQuoteProducts[index].Variable_Configurator__c = vcRecord.Id;
                                       component.set("v.newQuoteProducts",newQuoteProducts);
                                       component.set("v.ClickVc", false);
                                   }
                                   else if(state === "ERROR"){
                                       var errors = action.getError();
                                       if (errors) {
                                           if (errors[0] && errors[0].message) {
                                               var toastEvent = $A.get("e.force:showToast");
                                               toastEvent.setParams({
                                                   "title": "Error",
                                                   "message": errors[0].message,
                                                   "type": "error"
                                               });
                                               toastEvent.fire(); 
                                           }
                                       }
                                   }else if (status === "INCOMPLETE") {
                                       alert('No response from server or client is offline.');
                                   }
                               });
            $A.enqueueAction(action);
            //component.set("v.newQuoteProducts", newQuoteProducts);
            
        }
        
        component.set("v.spinner", false);
        }
    },
    closeDrawing : function(component, event, helper) 
    {
        //$A.get("e.force:closeQuickAction").fire();
        component.set("v.showDrawing", false);
    },
    closeViewData : function(component, event, helper) 
    {
        //$A.get("e.force:closeQuickAction").fire();
        component.set("v.viewData", false);
    },
    
    cancelClick : function (component, event, helper)
    {
        
        window.location.href = '/'+component.get("v.sourceId") ;
    },
    
  viewDrawing : function (component, event, helper)
    {
        var drawingType = event.getSource().get("v.title");
        var index = event.getSource().get("v.class");
        var newQuoteProducts = component.get("v.newQuoteProducts");
        var vcId = newQuoteProducts[index].Variable_Configurator__c;
        if(vcId !== null)
        {
            component.set("v.vcId", vcId);
            component.set("v.drawingType", drawingType);
            component.set("v.showDrawing", true);
        }
            
    },
    addVC : function(component, event, helper)
    {
		component.set("v.ClickVc", true);
        var recordId = component.get("v.sourceId");
        var accountId;
        var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
        var newQuoteProducts = component.get("v.newQuoteProducts");
        /*
        var accountId = component.get("v.accountId");
        if(typeof accountId == 'undefined'){
            var oppRecord = component.get("v.oppRecord");
            component.set("v.accountId",oppRecord.AccountId);
            accountId = oppRecord.AccountId;
        }
        */
        
        var popupType;
        var vcRecordId = null;
        
        if(newQuoteProducts[index].VC__c != null)
        {
            //vcRecordId = newQuoteProducts[index].Variable_Configurator__c;
            if(newQuoteProducts[index].CreateQuoteSAP_Success__c == false)
            {
                popupType = 'edit';
                component.set("v.vcId", newQuoteProducts[index].VC__c);
                if (newQuoteProducts[index].VC__r != null && newQuoteProducts[index].VC__r.Form_Config__r != null)
                    component.set("v.vcName", newQuoteProducts[index].VC__r.Form_Config__r.API_Name__c);                
                else
                    component.set("v.vcName", newQuoteProducts[index].VC_Type__c);
            }
            else
            {
                component.set("v.vcId",newQuoteProducts[index].VC__c);
                //component.set("v.vcRecordTypeId", newQuoteProducts[index].VC_RecordType_Id__c);
                if (newQuoteProducts[index].VC__r != null && newQuoteProducts[index].VC__r.Form_Config__r != null)
                    component.set("v.vcName", newQuoteProducts[index].VC__r.Form_Config__r.API_Name__c);                
                else
                    component.set("v.vcName", newQuoteProducts[index].VC_Type__c);
                component.set("v.viewData",true);
    
            }
        }        
        else
        {
            popupType = 'new';
            component.set("v.vcId", newQuoteProducts[index].VC__c);
            component.set("v.vcName", newQuoteProducts[index].VC_Type__c);            
        }
        
        if(popupType == 'edit' || popupType == 'new')
        {
            component.set("v.showVC", true);
        }        
      
    },
    editVC : function(component, event, helper)
    {
		component.set("v.ClickVc", true);
        component.set("v.vcId", 'a0zN0000002zDrPIAU');
        component.set("v.vcName", 'WMI_Horizontal_Pumps');
        component.set("v.showVC", true);      
      
    },    
    saveVC : function(component, event, helper)
    {        
        component.find('cmpVC').saveVC();
    },    
    closeVC : function(component, event, helper)
    {
        component.set("v.showVC", false);
        
        var value = event.getParam('value');
        if (value != null)
        {
            var newQuoteProducts = component.get("v.newQuoteProducts");
            var index = component.get("v.currentNewProductIndex");    
            newQuoteProducts[index].VC__c = value;            
            component.set("v.newQuoteProducts",newQuoteProducts);
            component.set("v.ClickVc", false);                    
        }
            
    },
    addVCTest : function(component, event, helper)
    {        
        var navService = component.find("navService");
        var pageRef = {
            type: "standard__objectPage",
            attributes: {
                recordId: 'a0zN0000003339XIAQ',
                objectApiName: 'VC__c',
                actionName: 'edit'
            },
            /*state: {
                recordTypeId : newQuoteProducts[index].VC_RecordType_Id__c
            } */         
        }
        /*
        var defaultFieldValues = {
            Opportunity__c : recordId,
            Account__c : accountId,
            
        };
        pageRef.state.defaultFieldValues = component.find("pageRefUtils").encodeDefaultFieldValues(defaultFieldValues);
        */
        pageRef.state = { navigationLocation: "RELATED_LIST" };                
        event.preventDefault();
        navService.navigate(pageRef);        
    },

    addVCBackup : function (component, event, helper)
    {
        /*var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
           
        var backupOpportunityProducts = component.get("v.newQuoteProducts");
        component.set("v.backupOpportunityProducts", backupOpportunityProducts); 
        component.set("v.newQuoteProducts", backupOpportunityProducts[index]);
        component.set("v.ClickVc", true);*/

		component.set("v.ClickVc", true);
        var recordId = component.get("v.sourceId");
        var accountId;
        var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
        var newQuoteProducts = component.get("v.newQuoteProducts");
        var accountId = component.get("v.accountId");
        if(typeof accountId == 'undefined'){
            var oppRecord = component.get("v.oppRecord");
            component.set("v.accountId",oppRecord.AccountId);
            accountId = oppRecord.AccountId;
        }
        
        var popupType;
        var vcRecordId = null;
        
        if(newQuoteProducts[index].Variable_Configurator__c != null)
        {
            vcRecordId = newQuoteProducts[index].Variable_Configurator__c;
            if(newQuoteProducts[index].CreateQuoteSAP_Success__c == false)
            {
                popupType = 'edit';
            }
            else
            {
                component.set("v.vcId",newQuoteProducts[index].Variable_Configurator__c);
                component.set("v.vcRecordTypeId", newQuoteProducts[index].VC_RecordType_Id__c);
                component.set("v.vcName", newQuoteProducts[index].Variable_Configurator__r.Name);
                component.set("v.viewData",true);
    
            }
        }        
        else
        {
            popupType = 'new';
        }
        
        if(popupType == 'edit' || popupType == 'new')
        {
            var pageRef = component.get("v.pageReference");
            var navService = component.find("navService");
            pageRef = {
                type: "standard__objectPage",
                attributes: {
                    recordId: vcRecordId,
                    objectApiName: "Variable_Configurator__c",
                    actionName: popupType
                },
                state: {
                    recordTypeId : newQuoteProducts[index].VC_RecordType_Id__c
                }          
            }
            
            var defaultFieldValues = {
                Opportunity__c : recordId,
                Account__c : accountId,
                
            };
            pageRef.state.defaultFieldValues = component.find("pageRefUtils").encodeDefaultFieldValues(defaultFieldValues);
            pageRef.state.navigationLocation="RELATED_LIST";
            //pageRef.state.nooverride=1;    
            //pageRef.state.backgroundContext="/lightning/cmp/c__OpportunityProduct?c__recordId="+recordId;
            component.set("v.pageReference", pageRef);
            var navService = component.find("navService");
            event.preventDefault();
            navService.navigate(pageRef);
        }
        
    },
    cancelVC : function (component, event, helper)
    {

        var index = event.getSource().get("v.class");
        var backupOpportunityProducts = component.get("v.backupOpportunityProducts");
        component.set("v.newQuoteProducts", backupOpportunityProducts);
        console.log(JSON.stringify(backupOpportunityProducts));
        component.set("v.ClickVc", false);  
    },
    submitVC : function (component, event, helper)
    {
        event.preventDefault(); // stop the form from submitting
        var newQuoteProducts = component.get("v.newQuoteProducts");
        var backupOpportunityProducts = component.get("v.backupOpportunityProducts");
        var oppRecord = component.get("v.oppRecord");
        var index = component.get("v.currentNewProductIndex");
        var eventFields = event.getParam("fields");
        console.log(JSON.stringify(eventFields));
        
        if(index !== null)
        {
            var VCProducts = [];
            var newVCProduct = {};
            if(backupOpportunityProducts[index].Variable_Configurator__c != null)
            {
                newVCProduct.Opportunity__c = oppRecord.Id;
                newVCProduct.Account__c = oppRecord.AccountId;
                newVCProduct.Id = backupOpportunityProducts[index].Variable_Configurator__c;
            }
            else
            {
                newVCProduct.Opportunity__c = eventFields.Opportunity__c;
                newVCProduct.Account__c = eventFields.Account__c;  
            }
            
            newVCProduct.RecordTypeId = eventFields.RecordTypeId;
            newVCProduct.PU_PUMP_WGR_TYPE__c = eventFields.PU_PUMP_WGR_TYPE__c;
            newVCProduct.PU_WGR_GLAND_TYPE__c = eventFields.PU_WGR_GLAND_TYPE__c;
            newVCProduct.PU_WGR_WET_END_TYPE__c = eventFields.PU_WGR_WET_END_TYPE__c;
            newVCProduct.PU_WGR_NAMEPLATE__c = eventFields.PU_WGR_NAMEPLATE__c;
            //newVCProduct.Form_Completed__c = eventFields.Form_Completed__c;
            newVCProduct.Form_Completed__c = true;

            backupOpportunityProducts[index].Variable_Configurator__r = newVCProduct;
            component.set("v.newQuoteProducts", backupOpportunityProducts);
            component.set("v.ClickVc", false); 
            
        }
        
    },
    openProductForm : function (component, event, helper)
    {
        console.log('openProductForm');        
        var index = event.getSource().get("v.class");
        var newQuoteProducts = component.get("v.newQuoteProducts");
        let parentId = newQuoteProducts[index].Id;
        let recordId = newQuoteProducts[index].Product_Form_Id__c;
        console.log(parentId);        
        component.set("v.quoteLineId", parentId);
        component.set("v.productFormId", null); //Reset previous
        if (recordId)
            component.set("v.productFormId", recordId);
        component.set("v.showProductForm", true);
        /*        
        console.log(component.get("v.recordId"));
        var navService = component.find("navService");        
        var pageReference = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__quoteProductFormWrapper'
            },
            state: {
                c__parentId: component.get("v.sourceId")
            }
        };
        navService.navigate(pageReference);   
        */
    },
    closeProductForm : function (component, event, helper)
    {
        console.log('closeProductForm');
        component.set("v.showProductForm", false);        
    }
})