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
        

        var oppRecord = component.get("v.oppRecord");
        
        if (oppRecord === null)
        {
            var pageReference = component.get("v.pageReference");
            oppRecord = pageReference.state.c__oppRecord;
            console.log(typeof oppRecord);
            console.log('oppRecord Id '+oppRecord.Id);
            component.set("v.oppRecord", oppRecord);
            component.set("v.oppCurrency", oppRecord.CurrencyIsoCode);
            component.set("v.accountId", oppRecord.AccountId);
 
        }
        
        var allVcRecordTypes = component.get("v.allVcRecordTypes");        
        component.set("v.newOpportunityProducts", []);
        component.set("v.vcOppItemsWrap", []);
        component.set("v.OpportunityProductToDelete", []);
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
                                   //$A.enqueueAction(component.get('c.addProduct'));
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
        var newOpportunityProduct = {};
        var newVCProduct = {};
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
        
        newOpportunityProduct.OpportunityId = component.get("v.sourceId");
        newOpportunityProduct.CreateQuoteSAP_Success__c = false;
        newOpportunityProducts.push(newOpportunityProduct);
        component.set("v.newOpportunityProducts", newOpportunityProducts);
        component.set("v.enableQuoteCreation", false);
    },
    productChanged : function (component, event, helper)
    {
        component.set("v.spinner", true);
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
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
                                       newOpportunityProducts[index].Product2Id = product.Id;
                                       newOpportunityProducts[index].Product_Name__c = product.Name;
                                       //newOpportunityProducts[index].Description = outputVar.value.Description;
                                   }
                               });
            $A.enqueueAction(action);
            
        }
        else
        {
            newOpportunityProducts[index].Product2Id = null;
            newOpportunityProducts[index].Product_Name__c = null;   
        }
        component.set("v.newOpportunityProducts", newOpportunityProducts); 
        component.set("v.spinner", false);
    },
    
    materialChanged : function (component, event, helper)
    {
        component.set("v.spinner", true);
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
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
                                           newOpportunityProducts[index].Material_VC__c = matName.substring(0, 2);
                                           newOpportunityProducts[index].VC_Type__c = material.VC_Type__c;
                                           newOpportunityProducts[index].Is_VC__c = material.Is_VC__c;
                                           newOpportunityProducts[index].Variable_Configurator__c = null;
                                           newOpportunityProducts[index].Variable_Configurator__r = undefined;
                                           if(typeof newOpportunityProducts[index].VC_Type__c !== 'undefined' && newOpportunityProducts[index].Is_VC__c === true)
                                           {
                                               newOpportunityProducts[index].Is_VC__c = true;
                                               var allVcRecordTypes = component.get("v.allVcRecordTypes");
                                               if(allVcRecordTypes.length > 0){
                                                   for(var i=0; i<allVcRecordTypes.length; i++)
                                                   {
                                                       if(newOpportunityProducts[index].VC_Type__c == allVcRecordTypes[i].DeveloperName)
                                                       {
                                                           newOpportunityProducts[index].VC_RecordType_Id__c = allVcRecordTypes[i].Id;
                                                           newOpportunityProducts[index].Is_VC_Material__c = true;
                                                           break;
                                                       }
                                                   }
                                               }
                                           }
                                           component.set("v.newOpportunityProducts", newOpportunityProducts);
                                       }
                                   }
                               });                    
            $A.enqueueAction(action);
        }
        else
        {
            //var newOpportunityProducts = component.get("v.newOpportunityProducts");
            newOpportunityProducts[index].Material_Number__c = null;
            newOpportunityProducts[index].Material_VC__c = null;
            newOpportunityProducts[index].Is_VC__c = false;
            newOpportunityProducts[index].Variable_Configurator__c = null;
            newOpportunityProducts[index].VCForm_Completed__c = false;
            newOpportunityProducts[index].CreateQuoteSAP_Success__c = false;
            newOpportunityProducts[index].Is_VC_Material__c = false;
            component.set("v.newOpportunityProducts", newOpportunityProducts);   
        }
        component.set("v.spinner", false);
        component.set("v.enableQuoteCreation", false);
    },
    
    removeProduct : function(component, event, helper)
    {
        var index = event.getSource().get("v.class");
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
        var OpportunityProductToDelete = component.get("v.OpportunityProductToDelete");
        var updatedOpportunityProducts = [];
        if(newOpportunityProducts[index].Id != null){
            OpportunityProductToDelete.push(newOpportunityProducts[index]);
        }
        newOpportunityProducts.splice(index, 1);

        component.set("v.newOpportunityProducts", newOpportunityProducts);
        component.set("v.OpportunityProductToDelete", OpportunityProductToDelete); 
        component.set("v.enableQuoteCreation", false);
    },

    createProducts : function (component, event, helper)
    {  
        component.set("v.spinner", true);      
        var vcOppItemsWrapList = [];
        
        var OpportunityProductsForDML = component.get("v.newOpportunityProducts");
        var OpportunityProductToDelete = component.get("v.OpportunityProductToDelete");
        if(OpportunityProductsForDML.length > 0)
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
            
            for(var i=0; i<OpportunityProductsForDML.length; i++)
            {
                if(OpportunityProductsForDML[i].Quantity == null)
                OpportunityProductsForDML.splice(i, 1);
            }
        }
        
        if(OpportunityProductToDelete.length > 0)
        {
            for(var i=0; i<OpportunityProductToDelete.length; i++)
            {
                OpportunityProductToDelete[i].Variable_Configurator__r = undefined;
            }
            
        }
        //console.log(JSON.stringify(vcOppItemsWrapList));
        
        var oppCurrency = component.get("v.oppCurrency");
        
        var action = component.get("c.OpportunityProductDML2");
        action.setParams({
            'vcOppItemsList' : OpportunityProductsForDML,
            'OppLineItemsDelete' : OpportunityProductToDelete,
            'oopCurrency' : oppCurrency
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
          		component.set("v.spinner", false);
                window.location.href = '/'+component.get("v.sourceId") ;
                
            } else if(state === "ERROR"){
                var errors = action.getError();
                if (errors) {
                    component.set("v.spinner", false);
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
            component.set("v.newOpportunityProducts", []);
            component.set("v.vcOppItemsWrap", []);
            component.set("v.OpportunityProductToDelete", []);
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
	//This fix because the solution we did to get VC Name from toast message no longer works :( //Manu 06.01.2021
    toastInfo : function(component, event, helper) {
        console.log('toastInfo: ' +event.getParams().message);
        var str = event.getParams().message;
        var n = str.indexOf("VC");
        //if(n >= 0)
        {
            
            var newOpportunityProducts = component.get("v.newOpportunityProducts");
            var index = component.get("v.currentNewProductIndex");
            //var vcName = str.substring(n, 33);
            //vcName = vcName.trim();
            //console.log('vcName : '+vcName);
            //component.set("v.spinner", true);
            
            //if (typeof vcName !== 'undefined')
        {
            //component.set("v.currentNewProductIndex", index);
            
            /* Comment 30-07-2021 because no VC
            var action = component.get("c.getVC");
            action.setParams({"vcName": null});
            action.setCallback(this, function(response)
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var vcRecord = response.getReturnValue();
                                       console.log('vcRecord : '+vcRecord);
                                       newOpportunityProducts[index].Variable_Configurator__c = vcRecord.Id;
                                       component.set("v.newOpportunityProducts",newOpportunityProducts);
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
                                           component.set("v.spinner", false);
                                       }
                                   }else if (status === "INCOMPLETE") {
                                       alert('No response from server or client is offline.');
                                   }
                               });
            $A.enqueueAction(action);
            Comment 30-07-2021 because no VC*/
            
            
            //component.set("v.newOpportunityProducts", newOpportunityProducts);
            
        }
        
        component.set("v.spinner", false);
        }
    }, 
    //This fix because the solution we did to get VC Name from toast message no longer works :( //Manu 06.01.2021
    toastInfoNOTWORKING : function(component, event, helper) {
        console.log('toastInfo: ' +event.getParams().message);
        var str = event.getParams().message;
        var n = str.indexOf("VC");
        if(n >= 0)
        {
            
            var newOpportunityProducts = component.get("v.newOpportunityProducts");
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
                                       newOpportunityProducts[index].Variable_Configurator__c = vcRecord.Id;
                                       component.set("v.newOpportunityProducts",newOpportunityProducts);
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
            //component.set("v.newOpportunityProducts", newOpportunityProducts);
            
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
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
        var vcId = newOpportunityProducts[index].Variable_Configurator__c;
        if(vcId !== null)
        {
            component.set("v.vcId", vcId);
            component.set("v.drawingType", drawingType);
            component.set("v.showDrawing", true);
        }
            
    },
    addVCNew: function(component, event, helper)
    {
        /*var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
           
        var backupOpportunityProducts = component.get("v.newOpportunityProducts");
        component.set("v.backupOpportunityProducts", backupOpportunityProducts); 
        component.set("v.newOpportunityProducts", backupOpportunityProducts[index]);
        component.set("v.ClickVc", true);*/

		component.set("v.ClickVc", true);
        var recordId = component.get("v.sourceId");
        var accountId;
        var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
        var accountId = component.get("v.accountId");
        if(typeof accountId == 'undefined'){
            var oppRecord = component.get("v.oppRecord");
            component.set("v.accountId",oppRecord.AccountId);
            accountId = oppRecord.AccountId;
        }
        
        var popupType;
        var vcRecordId = null;
        
        if(newOpportunityProducts[index].Variable_Configurator__c != null)
        {
            vcRecordId = newOpportunityProducts[index].Variable_Configurator__c;
            if(newOpportunityProducts[index].CreateQuoteSAP_Success__c == false)
            {
                popupType = 'edit';
            }
            else
            {
                component.set("v.vcId",newOpportunityProducts[index].Variable_Configurator__c);
                component.set("v.vcRecordTypeId", newOpportunityProducts[index].VC_RecordType_Id__c);
                component.set("v.vcName", newOpportunityProducts[index].Variable_Configurator__r.Name);
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

    addVC : function (component, event, helper)
    {
        /*var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
           
        var backupOpportunityProducts = component.get("v.newOpportunityProducts");
        component.set("v.backupOpportunityProducts", backupOpportunityProducts); 
        component.set("v.newOpportunityProducts", backupOpportunityProducts[index]);
        component.set("v.ClickVc", true);*/

		component.set("v.ClickVc", true);
        var recordId = component.get("v.sourceId");
        var accountId;
        var index = event.getSource().get("v.class");
        component.set("v.currentNewProductIndex", index);
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
        var accountId = component.get("v.accountId");
        if(typeof accountId == 'undefined'){
            var oppRecord = component.get("v.oppRecord");
            component.set("v.accountId",oppRecord.AccountId);
            accountId = oppRecord.AccountId;
        }
        
        var popupType;
        var vcRecordId = null;
        
        if(newOpportunityProducts[index].Variable_Configurator__c != null)
        {
            vcRecordId = newOpportunityProducts[index].Variable_Configurator__c;
            if(newOpportunityProducts[index].CreateQuoteSAP_Success__c == false)
            {
                popupType = 'edit';
            }
            else
            {
                component.set("v.vcId",newOpportunityProducts[index].Variable_Configurator__c);
                component.set("v.vcRecordTypeId", newOpportunityProducts[index].VC_RecordType_Id__c);
                component.set("v.vcName", newOpportunityProducts[index].Variable_Configurator__r.Name);
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
                    recordTypeId : newOpportunityProducts[index].VC_RecordType_Id__c
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
        component.set("v.newOpportunityProducts", backupOpportunityProducts);
        console.log(JSON.stringify(backupOpportunityProducts));
        component.set("v.ClickVc", false);  
    },
    submitVC : function (component, event, helper)
    {
        event.preventDefault(); // stop the form from submitting
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
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
            component.set("v.newOpportunityProducts", backupOpportunityProducts);
            component.set("v.ClickVc", false); 
            
        }
        
    },
    
    handleSuccessVC : function (component, event, helper)
    {
        var index = component.get("v.currentNewProductIndex");
        var newOpportunityProducts = component.get("v.newOpportunityProducts");  
        var param = event.getParams();
        newOpportunityProducts[index].Variable_Configurator__c = param.response.id;
        console.log('VC ID : '+newOpportunityProducts[index].Variable_Configurator__c)
        component.set("v.newOpportunityProducts", newOpportunityProducts);
        
        component.find('notifLib').showToast({
            "variant": "success",
            "title": "Vc Created Successfully",
            "message": "Record ID: " + param.response.Name
        });
        
        console.log(JSON.stringify(event.getParams()));
        component.set("v.ClickVc", false);
        var opportunityProductsForm = component.find("opportunityProductsForm");
        $A.util.toggleClass(opportunityProductsForm, "slds-show");
    },
    
    handleErrorVC: function (component, event, helper)
    {
        event.preventDefault();
        //event.stopImmediatePropagation();
        console.log(JSON.stringify(event.getParams()));
        component.find('notifLib').showToast({
            "variant": "error",
            "title": "Vc Error",
            "message": "Error Msg: " + event.getParam("message")
        });
    },
    
    onLoadVC: function(component, event, helper){
        var newOpportunityProducts = component.get("v.newOpportunityProducts");
        var oppRecord = component.get("v.oppRecord");
        var index = component.get("v.currentNewProductIndex");
        var ClickVc = component.get("v.ClickVc");
        
        if(newOpportunityProducts[index] !== null && typeof newOpportunityProducts[index] !== 'undefined' && ClickVc == true)
        {
            if(newOpportunityProducts[index].Variable_Configurator__c != null)
                component.set("v.VCrecordId", newOpportunityProducts[index].Variable_Configurator__c);
            else
                component.set("v.VCrecordId", null);
            
            if(newOpportunityProducts[index].VC_RecordType_Id__c != null && 
               typeof newOpportunityProducts[index].VC_RecordType_Id__c !== 'undefined'){
                component.set("v.vcRecordTypeId", newOpportunityProducts[index].VC_RecordType_Id__c);
                component.set("v.vcTypes", newOpportunityProducts[index].VC_Type__c);
                
            }
            
            component.set("v.newOpportunityProducts", newOpportunityProducts[index]);
            
            console.log('VCrecordId : '+newOpportunityProducts[index].Variable_Configurator__c);
            console.log('vcRecordTypeId : '+newOpportunityProducts[index].VC_RecordType_Id__c);
            console.log('vcRecordType : '+newOpportunityProducts[index].VC_Type__c);
        }
        
    },
    handleCreateProducts : function (component, event, helper)
    {
        console.log(event.getParam("status"));
        if(event.getParam("status") === "FINISHED_SCREEN") 
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "message": "Products created successfully.",
                "type": "success"
            });
            toastEvent.fire();
            
        }
        else
        {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error",
                "message": "Cannot create Products. Please contact System Administrator.",
                "type": "error"
            });
            toastEvent.fire();            
        }
        component.set("v.spinner", false);        
        //$A.get("e.force:closeQuickAction").fire();
    }
    
})