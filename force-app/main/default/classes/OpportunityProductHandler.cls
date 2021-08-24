global with sharing class OpportunityProductHandler {
    
    public static List<Opportunity> oppList {get; set;}
    public static List<OpportunityLineItem> oliList {get; set;}
    public static List<vcOppItemsWrapper> vcOppItemsWrapperList{get;set;}
    public static List<OpportunityLineItem> oppItemList {get; set;}
    public static vcSAPResponse vcSAPStatus {get; set;}
    public class vcSAPResponse
    {
        @AuraEnabled public Boolean vcSuccess {get; set;}
        @AuraEnabled public List<OpportunityLineItem> OppLineItems {get; set;}
        @AuraEnabled public Id quoteERPId{get; set;}
    }
    
    public class vcOppItemsWrapper
    {
        @AuraEnabled public OpportunityLineItem oppLineItemData {get; set;}
        //@AuraEnabled public Variable_Configurator__c vcData {get; set;}
    }
    
    
    @AuraEnabled
    Public static List<OpportunityLineItem> getOpportunityLineItems (Id objId)
    {
        List<OpportunityLineItem> oppItemList =  [SELECT Id, Name, OpportunityId, Opportunity.AccountId, PricebookEntryId, Product2Id, Quantity, UnitPrice, Material_Number__c, MaterialHierarchy__c, 
                                                  ProductHierarchy__c, Material_Description__c, Product_Name__c 
                                                  //Variable_Configurator__c, Is_VC_Material__c,Line_Item_Text__c, Item_Number__c, Material_Description1__c
                                                  //Material_VC__c, Material_Number__r.Is_VC__c, CreateQuoteSAP_Success__c, VC_RecordType_Id__c, VC_Type__c,Variable_Configurator__r.Name,
                                                  //Variable_Configurator__r.Account__c, Variable_Configurator__r.Opportunity__c, Variable_Configurator__r.PU_PUMP_WGR_TYPE__c, Variable_Configurator__r.PU_WGR_GLAND_TYPE__c, 
                                                  //Variable_Configurator__r.PU_WGR_WET_END_TYPE__c, Variable_Configurator__r.PU_WGR_NAMEPLATE__c, Variable_Configurator__r.PU_WGR_GUARD_TYPE__c, 
                                                  //Variable_Configurator__r.PU_WGR_DRIVE_END_TYPE__c, Variable_Configurator__r.Form_Completed__c, Variable_Configurator__r.RecordTypeId
                                                  FROM OpportunityLineItem WHERE OpportunityId =: objId Order By Id];
        system.debug('getOpportunityLineItems '+oppItemList.size());
        
        return oppItemList;
    }
    
    @AuraEnabled
    Public static Material_Number__c getMaterials (Id materialId)
    {
        Material_Number__c material =  [SELECT Id, Name, ERP_ID__c, Material_Status__c, Material_Description__c, Material_Type__c,
        //Is_VC__c,VC_Type__c
                                        Product_Code__c, Quantity_Unit_Of_Measure__c, Third_Level_Material_Hierarchy_Name__c 
                                        FROM Material_Number__c WHERE Id =: materialId];
        
        return material;
    }
    
    @AuraEnabled
    Public static Product2 getProducts (Id productId)
    {
        Product2 product =  [SELECT Id, Name, Description, Third_Level_Product_Hierarchy_Name__c, Third_Level_Product_Hierarchy__c, 
                             Third_Level_Hierarchy__c FROM Product2 WHERE Id =: productId];
        
        return product;
    }
    
    /*
    @AuraEnabled
    Public static Variable_Configurator__c getVC (String vcName)
    {
        system.debug('vcName : '+vcName);
        if (vcName != null)
        {
        	Variable_Configurator__c vc =  [SELECT Id, Name FROM Variable_Configurator__c where Name =: vcName];
            system.debug('VC : '+vc);
            return vc;            
        }
		else //This fix because the solution we did to get VC Name from toast message no longer works :( ! //Manu 06.01.2021
        {
        	Variable_Configurator__c vc =  [SELECT Id, Name FROM Variable_Configurator__c ORDER BY CreatedDate DESC LIMIT 1];
            system.debug('VC : '+vc);
            return vc;               
        }
    }
    */
    
    @AuraEnabled
    Public static List<RecordType> getAllVCRecordTypes (String objectName)
    {
        List<RecordType> allVcRecordTypes =  [SELECT Id, DeveloperName, SobjectType FROM RecordType
                                              WHERE SobjectType =: objectName];
        
        return allVcRecordTypes;
    }
    
    
    
    @AuraEnabled
    Public static void OpportunityProductDML2 (List<OpportunityLineItem> vcOppItemsList, List<OpportunityLineItem> OppLineItemsDelete, String oopCurrency){
        
        Set<Id> productIdSet = new Set<Id>();
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        Map<Integer,OpportunityLineItem> oppItemMap = new Map<Integer,OpportunityLineItem>();
        List<String> thirdLevelList = new List<String>();
        List<OpportunityLineItem> oLineList = new List<OpportunityLineItem>();
        String msg = '';
        Integer itemNo = 0;
        //List<Variable_Configurator__c> vcList = new List<Variable_Configurator__c>();
        List<OpportunityLineItem> vcOppItemList = new List<OpportunityLineItem>();
        List<Integer> oppItemIndex = new List<Integer>();
        Integer no = 0;
        
        if(!vcOppItemsList.isEmpty())
        {
            
            for(OpportunityLineItem item : vcOppItemsList){
                productIdSet.add(item.Product2Id); 
            }
            for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c,Product2Id
                                          FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: oopCurrency
                                          AND Product2Id IN: productIdSet]){
                                              pbEntryMap.put(pbEntry.Product2Id, pbEntry.id); 
                                          }
            
            System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
            
            for(OpportunityLineItem item : vcOppItemsList)
            {
                if (!pbEntryMap.isEmpty())
                {
                    OpportunityLineItem oItem = new OpportunityLineItem();
                    if(pbEntryMap.containsKey(item.Product2Id)) oItem.PricebookEntryId = pbEntryMap.get(item.Product2Id);
                    if(item.Id != null){
                        oItem.Id = item.Id;
                    }
                    else oItem.OpportunityId = item.OpportunityId;
                    oItem.Material_Number__c = item.Material_Number__c;
                    oItem.quantity = item.Quantity;
                    oItem.UnitPrice = item.UnitPrice;
                    //oItem.Line_Item_Text__c = item.Line_Item_Text__c ;
                    //oItem.Variable_Configurator__c = item.Variable_Configurator__c;
                    //oItem.Is_VC_Material__c = item.Is_VC_Material__c;
                    oLineList.add(oItem);
                    system.debug('oItem: '+itemNo+' '+item);
                    itemNo = itemNo+1;
                }
            }
        }
        
        Integer item = 1;
        Boolean error = false;
        Database.UpsertResult [] oppItemResult = Database.upsert(oLineList, OpportunityLineItem.Fields.Id, false);
        for (Database.UpsertResult sr : oppItemResult)
        {
            if (!sr.isSuccess())
            {
                error = true;
                for(Database.Error err : sr.getErrors())
                {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    throw new AuraHandledException('Item No.'+item+ ': '+ err.getMessage());
                }
            }
            else item = item+1;                    
        }
        
        if(!OppLineItemsDelete.isEmpty() && error == false)
        {
            System.debug('OppLineItemsDelete : '+OppLineItemsDelete);
            try{
                delete OppLineItemsDelete;
            }catch(DmlException e){
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    //Get Validation Rule & Trigger Error Messages
                    msg =+ e.getDmlMessage(i) +  '\n' ;
                }
                //throw DML exception message
                throw new AuraHandledException(msg);
                
            }catch(Exception e){
                //throw all other exception message
                throw new AuraHandledException(e.getMessage());
            }
            
        }
    }
    
    
    @AuraEnabled
    Public static void OpportunityProductDML (List<vcOppItemsWrapper> vcOppItemsWrapList, List<OpportunityLineItem> OppLineItemsDelete, String oopCurrency){
        //List<OpportunityLineItem> vcOppItemsList = (List<OpportunityLineItem>)JSON.deserialize(vcOppItemsString, List<OpportunityLineItem>.class);
        List<OpportunityLineItem> vcOppItemsList = new List<OpportunityLineItem>();
        Set<Id> productIdSet = new Set<Id>();
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        //Map<Integer,Variable_Configurator__c> VCMap = new Map<Integer,Variable_Configurator__c>();
        Map<Integer,OpportunityLineItem> oppItemMap = new Map<Integer,OpportunityLineItem>();
        List<String> thirdLevelList = new List<String>();
        List<OpportunityLineItem> oLineList = new List<OpportunityLineItem>();
        String msg = '';
        Integer itemNo = 0;
        //List<Variable_Configurator__c> vcList = new List<Variable_Configurator__c>();
        List<OpportunityLineItem> vcOppItemList = new List<OpportunityLineItem>();
        List<Integer> oppItemIndex = new List<Integer>();
        Integer no = 0;
        /*
        for(Integer i=0; i<vcOppItemsWrapList.size(); i++)
        {
            system.debug('vcOppItemsWrapList  '+i+ ' : '+vcOppItemsWrapList[i]);
            if(vcOppItemsWrapList[i].oppLineItemData.Is_VC__c == true && vcOppItemsWrapList[i].vcData != null)
            {
                vcList.add(vcOppItemsWrapList[i].vcData);
                system.debug(i+' : '+vcOppItemsWrapList[i].vcData);
                oppItemIndex.add(i); 
            }
        }
        */
        system.debug('oppItemIndex : '+oppItemIndex);
        Iterator<Integer> oppItemIndexIter = oppItemIndex.iterator();
        
        /*
        Integer vcIndex ;
        Database.UpsertResult [] vcResult = Database.upsert(vcList, Variable_Configurator__c.Fields.Id, false);
        for (Database.UpsertResult sr : vcResult)
        { 
            if (sr.isSuccess())
            {
                Id vcSuccessId = sr.getId();
                if(oppItemIndexIter.hasNext())
                {
                    vcIndex = oppItemIndexIter.next();
                    system.debug(vcIndex);
                }
                system.debug('vcSuccessId  '+vcIndex+ ' : '+vcSuccessId);
                vcOppItemsWrapList[vcIndex].oppLineItemData.Variable_Configurator__c = vcSuccessId;
                system.debug('Variable_Configurator__c  '+vcIndex+ ' : '+vcOppItemsWrapList[vcIndex].oppLineItemData.Variable_Configurator__c);
                
            }
            else
            {               
                //error = true;
                for(Database.Error err : sr.getErrors())
                {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    throw new AuraHandledException('Item No.'+vcIndex+ ': '+ err.getMessage());
                }
            }
            
        }
        */
        
        for(Integer i=0; i<vcOppItemsWrapList.size(); i++)
        {
            vcOppItemsList.add(vcOppItemsWrapList[i].oppLineItemData);
        }
        
        if(!vcOppItemsList.isEmpty())
        {
            
            for(OpportunityLineItem item : vcOppItemsList){
                productIdSet.add(item.Product2Id); 
            }
            for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c,Product2Id
                                          FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: oopCurrency
                                          AND Product2Id IN: productIdSet]){
                                              pbEntryMap.put(pbEntry.Product2Id, pbEntry.id); 
                                          }
            
            System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
            
            for(OpportunityLineItem item : vcOppItemsList)
            {
                if (!pbEntryMap.isEmpty())
                {
                    OpportunityLineItem oItem = new OpportunityLineItem();
                    if(pbEntryMap.containsKey(item.Product2Id)) oItem.PricebookEntryId = pbEntryMap.get(item.Product2Id);
                    if(item.Id != null){
                        oItem.Id = item.Id;
                    }
                    else oItem.OpportunityId = item.OpportunityId;
                    oItem.Material_Number__c = item.Material_Number__c;
                    oItem.quantity = item.Quantity;
                    oItem.UnitPrice = item.UnitPrice;
                    oItem.Description = item.Description;
                    //oItem.Variable_Configurator__c = item.Variable_Configurator__c;
                    //oItem.Is_VC_Material__c = item.Is_VC_Material__c;
                    oLineList.add(oItem);
                    system.debug('oItem: '+itemNo+' '+item);
                    itemNo = itemNo+1;
                }
            }
        }
        
        Integer item = 1;
        Boolean error = false;
        Database.UpsertResult [] oppItemResult = Database.upsert(oLineList, OpportunityLineItem.Fields.Id, false);
        for (Database.UpsertResult sr : oppItemResult)
        {
            if (!sr.isSuccess())
            {
                error = true;
                for(Database.Error err : sr.getErrors())
                {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    throw new AuraHandledException('Item No.'+item+ ': '+ err.getMessage());
                }
            }
            else item = item+1;                    
        }
        
        if(!OppLineItemsDelete.isEmpty() && error == false)
        {
            System.debug('OppLineItemsDelete : '+OppLineItemsDelete);
            try{
                delete OppLineItemsDelete;
            }catch(DmlException e){
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    //Get Validation Rule & Trigger Error Messages
                    msg =+ e.getDmlMessage(i) +  '\n' ;
                }
                //throw DML exception message
                throw new AuraHandledException(msg);
                
            }catch(Exception e){
                //throw all other exception message
                throw new AuraHandledException(e.getMessage());
            }
            
        }
    }
    
    
    /*
    @AuraEnabled
    public static List<Opportunity> ValidateSGTProfile(Id objId)
    {
        Boolean allowInquiry = false;
        oppList = [SELECT Id, Name, SGTProfile__c, StageName, Integration_Status__c,CloseDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity_ID__c,
                   Division__c, Channel__c, Sales_Group__c, Sales_Office__c, Territory2Id, Sales_Organization_User__r.code__c,Quote_SAP_Status__c,
                   AccountId, Account.CreatedBy.profileId, Account.Name,Account.Type, Account.Industry, Account.Industry_Code__c, Account.Phone, Account.Website,
                   Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingStateCode, Account.BillingPostalCode, Account.BillingCountry, Account.BillingCountryCode,
                   Shipping_Address__r.ERP_ID__c, Account.Account_Status__c, Account.Prospect__c, Account.ERP_Id__c, Account.CurrencyIsoCode, 
                   (SELECT Id, Name, Material_Number__r.Name, Variable_Configurator__c, VCForm_Completed__c, CreateQuoteSAP_Success__c,Is_VC_Material__c FROM OpportunityLineItems ORDER BY Id)
                   FROM Opportunity WHERE id =:objId ];
        
        if(!oppList.isEmpty())
        {
            oppList[0].SGTProfile__c = false;
            Id accProfileId = oppList[0].Account.CreatedBy.profileId;
            Id userProfileId = userinfo.getProfileId();
            String accprofileName = [Select Id, Name from Profile WHERE Id=:accProfileId].Name;
            String userprofileName = [Select Id, Name from Profile WHERE Id=:userProfileId].Name;
            system.debug('accProfileName: '+accprofileName+' accProfileID: '+accprofileId+' userProfileName: '+userprofileName+' userProfileID: '+userprofileId);
            HCI_SAP__c accMC = HCI_SAP__c.getInstance(accprofileId);
            HCI_SAP__c userMC = HCI_SAP__c.getInstance(userprofileId);
            system.debug('accMC: '+accMC+' userMC: '+userMC);
            if(accMC.Allow_Push_to_SAP__c == true && userMC.Allow_Push_to_SAP__c == true)
            {    
                oppList[0].SGTProfile__c = true;
                system.debug('----You are SGT Profile----');
            }
            else {system.debug('----You are not SGT Profile----');}
        }
        return oppList;
    }
    */

    /*
    @AuraEnabled
    Public static vcSAPResponse SendToSAP (Id objId)
    {
        system.debug('objId : '+objId);
        Set<Id> vcIdSet = new Set<Id>();
        Map<Id, OpportunityLineItem> oppItemsVCMap = new Map<Id, OpportunityLineItem>();
        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        vcSAPStatus = new VCSAPResponse();
        Opportunity opp;
        
        weirComB2bFolderRfq.Record_element[] response = new List<weirComB2bFolderRfq.Record_element>();
        weirComB2bFolderRfq.SI_X_RFQ_OBinding reqPort = new weirComB2bFolderRfq.SI_X_RFQ_OBinding();
        weirComB2bFolderRfq.Record_element[] recordList = new List<weirComB2bFolderRfq.Record_element>();
        
        List<OpportunityLineItem>  oliList = [SELECT Id, OpportunityId, Opportunity.Opportunity_ID__c,
                                              Opportunity.Division__c, Opportunity.Channel__c, Opportunity.Sales_Group__c,
                                              Opportunity.Sales_Office__c, Opportunity.Sales_Organization_User__r.code__c,
                                              Opportunity.Expected_Delivery_Date__c,Opportunity.Account.ERP_Id__c,
                                              Name, Material_Number__c, Material_Number__r.Name, Material_Number__r.Quantity_Unit_Of_Measure__c, 
                                              UnitPrice, Quantity, Description,Item_No__c,Opportunity.Plant__c,
                                              Variable_Configurator__c, VCForm_Completed__c, CreateQuoteSAP_Success__c, Is_VC_Material__c
                                              FROM OpportunityLineItem WHERE OpportunityId =: objId];
        
        system.debug('oliList : '+oliList);
        
        //for(OpportunityLineItem oItem : OppLineItems)
        if(!oliList.isEmpty())
        {
            for(OpportunityLineItem oItem : oliList)
            {
                if(oItem.Variable_Configurator__c != null && oItem.CreateQuoteSAP_Success__c == false)
                {
                    vcIdSet.add(oItem.Variable_Configurator__c);        
                    if(!oppItemsVCMap.containsKey(oItem.Variable_Configurator__c))
                        oppItemsVCMap.put(oItem.Variable_Configurator__c , oItem);
                }     
            }
        }
        
        if(!vcIdSet.isEmpty())
        {
            //Integer drawingNo = 10;
            

            
            
            for(Variable_Configurator__c vc :  [SELECT Id, IsDeleted, Name, CurrencyIsoCode, RecordTypeId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, LastViewedDate,
                                                LastReferencedDate, Absorbed_Power_kW__c, Ancil_Config__c, Bareshaft__c, Certification__c, Consolidate_Order_In__c, Coupling__c, Currency__c, Customer_Required_Date__c,
                                                Date__c, Duty_Known__c, Fitted_By__c, Flow_Rate_L_S_m3_hr__c, Fluid_Type__c, Fluid_pH__c, Frame__c, Gearbox__c, Gemex__c, Heaters__c, INCO_Terms__c, Impeller__c, Managed__c, 
                                                Max_Working_Pressure_Bar__c, Model__c, Motor_Efficiency__c, Motor_Known__c, Motor_Manufacturer__c, Motor_Mounting__c, Motor_kW__c, PS_HZ_PUMP_MODEL__c, PT100_Bearings__c, 
                                                PT100_Windings__c, Paint_Colour__c, Paint_System__c, Pumpset__c, Quantity__c, Sales_Organization__c, Size__c, Sold_to_Party__c, Supplied_By__c, Test_Pressure_Bar__c, Thermistors__c,
                                                Throatbush__c, Total_Selling_Price2__c, Total_Selling_Price__c, Unit_Selling_Price__c, VFD_Driven__c, Account__c, Opportunity__c, PU_PUMP_WGR_TYPE__c, PU_WGR_GLAND_TYPE__c, 
                                                PU_WGR_WET_END_TYPE__c, PU_WGR_NAMEPLATE__c, PU_WGR_GUARD_TYPE__c, PU_WGR_DRIVE_END_TYPE__c, PS_HZ_CONFIG_TYPE__c, Form_Completed__c, PS_HZ_DRIVE_TYPE__c, PS_HZ_PUMP_SIZE_FRAME_TYPE__c, 
                                                PS_HZ_PUMP_VARIANT__c, PS_HZ_PUMP_TYPE__c, PS_HZ_DRIVE_END_TYPE__c, PS_HZ_SEALING_TYPE_STANDARD__c, PS_HZ_GUARDING_TYPE__c, PS_HZ_PUMP_ROTATION__c, PS_HZ_IMPELLER_MATERIAL__c, PS_HZ_IMPELLER_TYPE__c, 
                                                PS_HZ_VOLUTE_MATERIAL__c, PS_HZ_VOLUTE_TYPE__c, PS_HZ_THROATBUSH_MATERIAL__c, PS_HZ_THROATBUSH_ADJUSTMENT__c, PS_HZ_THROATBUSH_TYPE__c, PS_HZ_EXPELLER_MATERIAL__c, PS_HZ_EXPELLER_RING_MATERIAL__c, 
                                                PS_HZ_STUFFING_BOX_MATERIAL__c, PS_HZ_FRAME_PLATE_TYPE__c, PS_HZ_FRAME_PLATE_INSERT_MAT__c, PS_HZ_MOTOR_REQ__c, PS_HZ_PULLEY_REQ__c, PS_HZ_ACCESSORIES_REQ__c, PS_HZ_FLANGE_REQ__c, PS_HZ_DISCHARGE_POSITION__c,
                                                PS_HZ_MOTOR_MAKE__c, PS_HZ_PULLEY_MAKE__c, PS_HZ_PULLEY_SPL_REQ__c, MOTOR_FRAME_STANDARD__c, MOTOR_FRAME_MOC__c, PS_CH_MOTOR_FREQUENCY__c, MOTOR_OUTPUT_POWER__c, MOTOR_POLES__c, MOTOR_VOLTAGE__c, MOTOR_FRAME_NUMBER__c, 
                                                PS_HZ_DRIVE_CATEGORY__c, MOTOR_MOUNTING_TYPE__c, MOTOR_MOUNTING_ORIENTATION__c, MOTOR_TERMINAL_BOX__c, MOTOR_INGRESS_PROTECTION__c, Pump_Size_Dummy__c, Wet_End_Type_Standard__c, Wet_End_Type_WRT1__c, Sealing_Type_WRT1__c, 
                                                PS_HZ_PUMP_SPEED__c, Pump_Size_Backend__c, Pump_Frame_Type_Backend__c, Pump_Type_Backend__c, Wet_End_Type_Backend__c, Drive_End_Type_Backend__c,RecordType.DeveloperName, Foundation_Bolt__c
                                                FROM Variable_Configurator__c
                                                WHERE Id IN: vcIdSet])
            {
                
                system.debug('RecordType.DeveloperName: '+vc.RecordType.DeveloperName);
                weirComB2bFolderRfq.Record_element record = new weirComB2bFolderRfq.Record_element();
                if(vc.RecordType.DeveloperName == 'WGR_PUMP')
                {
                    record = map_WGR_Pump(vc, oppItemsVCMap);
                }
                else if(vc.RecordType.DeveloperName == 'WMI_Horizontal_Pumps')
                {
                    record = map_WMI_Horizontal_Pumps(vc, oppItemsVCMap);
                }
                else if(vc.RecordType.DeveloperName == 'NATCA_Pumpset')
                {
                    
                }
                else if(vc.RecordType.DeveloperName == 'Rubber_Liners')
                {
                    
                }
                
                
                recordList.add(record);
                system.debug('vc recordList: '+recordList);
                
                //drawingNo =+ 10;
            }
        }
        
        Boolean resSuccess = false;
        
        if(!recordList.isEmpty())
        {
            system.debug('recordList : '+recordList);
            try
            {

                
                vcSAPStatus.vcSuccess = true;
                response = reqPort.SI_X_RFQ_O(recordList);
                if(!response.isEmpty())
                {
                    system.debug(response);
                    //if(response.quoteId != null)
                    //system.debug('response.quoteId : '+response.quoteId);
                    //vcSAPStatus.quoteERPId = response.quoteId
                    vcSAPStatus.vcSuccess = true;
                    opp = new Opportunity(Id = objId, Quote_SAP_Status__c = 'In Progress');
                    for(OpportunityLineItem oItem : oliList)
                    {
                        if(oItem.Variable_Configurator__c != null)
                        {
                            oItem.CreateQuoteSAP_Success__c = true;
                        }     
                    }
                    
                }
                else
                {
                    vcSAPStatus.vcSuccess = false; 
                }
                
                update oliList;
                update opp;
                vcSAPStatus.OppLineItems = oliList;
                
                system.debug('vcSAPStatus vcSuccess: '+vcSAPStatus.vcSuccess);
            } 
            catch(Exception e)
            {
                System.debug(e.getMessage() + ' ' + e.getLineNumber());
                throw new AuraHandledException(e.getMessage());
                
            } 
        }
        return vcSAPStatus;
    }
    */

    /*
    @AuraEnabled
    public static ContentVersion getDrawingId(Id parentId)
    {
        ContentVersion cv = null;
        List<ContentDocumentLink> links = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :parentId];        
        if (links != NULL && links.size() > 0)
        {
            Set<Id> contentDocumentIds = new Set<Id>();
            List<ContentVersion> versions = [SELECT ContentDocumentId, ContentSize FROM ContentVersion WHERE File_Type__c = 'Drawing' ORDER BY CreatedDate DESC LIMIT 1];
            if (versions != NULL && versions.size() > 0)
            {
                cv = versions.get(0); 
            }
        }
        return cv;
    }
    */
    
    /*
    public static weirComB2bFolderRfq.Record_element map_WGR_Pump(Variable_Configurator__c vc, Map<Id, OpportunityLineItem> oppItemsVCMap)
    { 
        weirComB2bFolderRfq.Record_element record = new weirComB2bFolderRfq.Record_element();
        record.CUSTOMER_NUMBER = 'ICY-GB10';
        //record.CUSTOMER_NUMBER = oppItemsVCMap.get(vc.Id).Opportunity.Account.ERP_Id__c;
        record.DIST_CHANNEL = oppItemsVCMap.get(vc.Id).Opportunity.Channel__c;
        record.DIVISION = oppItemsVCMap.get(vc.Id).Opportunity.Division__c;
        record.DRAWING_Number = oppItemsVCMap.get(vc.Id).Opportunity.Opportunity_ID__c + oppItemsVCMap.get(vc.Id).Item_No__c;
        record.PLANT = oppItemsVCMap.get(vc.Id).Opportunity.Plant__c;
        record.PRODUCT_LINE = 'STRAIGHT';
        record.QUANTITY = String.valueOf(oppItemsVCMap.get(vc.Id).Quantity);
        record.QUOTATION_FileName = oppItemsVCMap.get(vc.Id).Opportunity.Opportunity_ID__c;
        record.REQ_DATE_H = String.valueOf(oppItemsVCMap.get(vc.Id).Opportunity.Expected_Delivery_Date__c).replaceall('-','');
        record.SALES_ORG = oppItemsVCMap.get(vc.Id).Opportunity.Sales_Organization_User__r.code__c;
        //record.SALES_ORG = 'MY01';
        record.MaterialName = oppItemsVCMap.get(vc.Id).Material_Number__r.Name;
        record.PU_WGR_GUARD_TYPE = vc.PU_WGR_GUARD_TYPE__c;
        record.PU_WGR_NAMEPLATE = vc.PU_WGR_NAMEPLATE__c;
        record.PU_WGR_NAMEPLATE = 'NPE';
        record.PU_WGR_WET_END_TYPE = vc.PU_WGR_WET_END_TYPE__c;
        record.PU_PUMP_WGR_TYPE = vc.PU_PUMP_WGR_TYPE__c;
        record.PU_WGR_DRIVE_END_TYPE = vc.PU_WGR_DRIVE_END_TYPE__c;
        record.PU_WGR_GLAND_TYPE = vc.PU_WGR_GLAND_TYPE__c;
        record.PU_WGR_ORDER_TYPE = 'NONSPARE';
        
        system.debug('record.CUSTOMER_NUMBER : '+record.CUSTOMER_NUMBER);
        system.debug('record.DIST_CHANNEL : '+record.DIST_CHANNEL);
        system.debug('record.DIVISION : '+record.DIVISION);
        system.debug('record.DRAWING_Number : '+record.DRAWING_Number);
        system.debug('record.PLANT : '+record.PLANT);
        system.debug('record.QUANTITY : '+record.QUANTITY);
        system.debug('record.QUOTATION_FileName : '+record.QUOTATION_FileName);
        system.debug('record.REQ_DATE_H : '+record.REQ_DATE_H);
        system.debug('record.SALES_ORG : '+record.SALES_ORG);
        system.debug('record.MaterialName : '+record.MaterialName);
        system.debug('record.PU_WGR_GUARD_TYPE : '+record.PU_WGR_GUARD_TYPE);
        system.debug('record.PU_WGR_NAMEPLATE : '+record.PU_WGR_NAMEPLATE);
        system.debug('record.PU_WGR_WET_END_TYPE : '+record.PU_WGR_WET_END_TYPE);
        system.debug('record.PU_PUMP_WGR_TYPE : '+record.PU_PUMP_WGR_TYPE);
        system.debug('record.PU_WGR_DRIVE_END_TYPE : '+record.PU_WGR_DRIVE_END_TYPE);
        system.debug('record.PU_WGR_GLAND_TYPE : '+record.PU_WGR_GLAND_TYPE);
        
        return record;
    }
    
    public static weirComB2bFolderRfq.Record_element map_WMI_Horizontal_Pumps(Variable_Configurator__c vc, Map<Id, OpportunityLineItem> oppItemsVCMap)
    { 
        weirComB2bFolderRfq.Record_element record = new weirComB2bFolderRfq.Record_element();
        
        record.CUSTOMER_NAME = 'ICY-AU10';
        record.CUSTOMER_NUMBER = 'ICY-AU10';
        record.DIST_CHANNEL = oppItemsVCMap.get(vc.Id).Opportunity.Channel__c;
        record.DIVISION = oppItemsVCMap.get(vc.Id).Opportunity.Division__c;
        record.HS_HOSE_TYPE = '808';
        record.HS_WALL_TYPE = 'HARD';
        record.MaterialName = oppItemsVCMap.get(vc.Id).Material_Number__r.Name;
        record.MOTOR_EFFICIENCY = vc.MOTOR_EFFICIENCY__c;
        record.MOTOR_FRAME_MOC = vc.MOTOR_FRAME_MOC__c;
        record.MOTOR_FRAME_NUMBER = vc.MOTOR_FRAME_NUMBER__c;
        record.MOTOR_FRAME_STANDARD = vc.MOTOR_FRAME_STANDARD__c;
        record.MOTOR_INGRESS_PROTECTION = vc.MOTOR_INGRESS_PROTECTION__c;
        record.MOTOR_MOUNTING_ORIENTATION = 'IM_1001/IM_B3';/////////
        record.MOTOR_MOUNTING_TYPE = vc.MOTOR_MOUNTING_TYPE__c;
        record.MOTOR_OUTPUT_POWER = vc.MOTOR_OUTPUT_POWER__c;
        record.MOTOR_POLES = vc.MOTOR_POLES__c;
        record.MOTOR_REQUIRED = vc.PS_HZ_MOTOR_REQ__c;
        record.MOTOR_TERMIANAL_BOX = vc.MOTOR_TERMINAL_BOX__c;
        record.MOTOR_VOLTAGE = vc.MOTOR_VOLTAGE__c;
        record.PLANT = oppItemsVCMap.get(vc.Id).Opportunity.Plant__c;
        //record.PLANT = 'IN01';
        record.PRODUCT_LINE  = 'STRAIGHT';
        record.PS_CH_MOTOR_FREQUENCY = vc.PS_CH_MOTOR_FREQUENCY__c;
        record.ACCESSORIES_REQUIRED = vc.PS_HZ_ACCESSORIES_REQ__c;
        record.PS_HZ_CONFIG_TYPE = vc.PS_HZ_CONFIG_TYPE__c;
        record.PS_HZ_DISCHARGE_POSITION = vc.PS_HZ_DISCHARGE_POSITION__c;
        record.PS_HZ_DRIVE_CATEGORY = vc.PS_HZ_DRIVE_CATEGORY__c;
        record.PS_HZ_DRIVE_END_TYPE = vc.Drive_End_Type_Backend__c;
        record.PS_HZ_DRIVE_TYPE = vc.PS_HZ_DRIVE_TYPE__c;
        record.PS_HZ_EXPELLER_MATERIAL = vc.PS_HZ_EXPELLER_MATERIAL__c;
        record.PS_HZ_EXPELLER_RING_MATERIAL = vc.PS_HZ_EXPELLER_RING_MATERIAL__c;
        record.PS_HZ_FLANGE_REQ = vc.PS_HZ_FLANGE_REQ__c;
        record.PS_HZ_FRAME_PLATE_INSERT_MAT = vc.PS_HZ_FRAME_PLATE_INSERT_MAT__c;
        record.PS_HZ_FRAME_PLATE_TYPE = vc.PS_HZ_FRAME_PLATE_TYPE__c;
        record.PS_HZ_GUARDING_TYPE = vc.PS_HZ_GUARDING_TYPE__c;
        record.PS_HZ_IMPELLER_MATERIAL = vc.PS_HZ_IMPELLER_MATERIAL__c;
        record.PS_HZ_IMPELLER_TYPE = vc.PS_HZ_IMPELLER_TYPE__c;
        record.PS_HZ_MOTOR_MAKE = vc.PS_HZ_MOTOR_MAKE__c;
        record.PS_HZ_PULLEY_MAKE = vc.PS_HZ_PULLEY_MAKE__c;
        record.PS_HZ_PULLEY_SPL_REQ = vc.PS_HZ_PULLEY_SPL_REQ__c;
        record.PS_HZ_PUMP_FRAME_TYPE = vc.Pump_Frame_Type_Backend__c;
        record.PS_HZ_PUMP_MODEL = vc.PS_HZ_PUMP_MODEL__c;
        record.PS_HZ_PUMP_ROTATION = vc.PS_HZ_PUMP_ROTATION__c;
        record.PS_HZ_PUMP_SIZE = vc.Pump_Size_Backend__c;
        record.PS_HZ_PUMP_SPEED = String.valueOf(vc.PS_HZ_PUMP_SPEED__c);
        record.PS_HZ_PUMP_TYPE = vc.Pump_Type_Backend__c;
        record.PS_HZ_PUMP_VARIANT = vc.PS_HZ_PUMP_VARIANT__c;
        record.PS_HZ_SEALING_TYPE = vc.Sealing_Type_WRT1__c;
        record.PS_HZ_STUFFING_BOX_MATERIAL = vc.PS_HZ_STUFFING_BOX_MATERIAL__c;
        record.PS_HZ_THROATBUSH_ADJUSTMENT = vc.PS_HZ_THROATBUSH_ADJUSTMENT__c;
        record.PS_HZ_THROATBUSH_MATERIAL = vc.PS_HZ_THROATBUSH_MATERIAL__c;
        record.PS_HZ_THROATBUSH_TYPE = vc.PS_HZ_THROATBUSH_TYPE__c;
        record.PS_HZ_VOLUTE_MATERIAL = vc.PS_HZ_VOLUTE_MATERIAL__c;
        record.PS_HZ_VOLUTE_TYPE = vc.PS_HZ_VOLUTE_TYPE__c;
        record.PS_HZ_WET_END_TYPE = vc.Wet_End_Type_Backend__c;
        record.PULLEYS_BELTS_REQUIRED = vc.PS_HZ_PULLEY_REQ__c;
        record.QUANTITY = String.valueOf(oppItemsVCMap.get(vc.Id).Quantity);
        record.QUOTATION_FileName = oppItemsVCMap.get(vc.Id).Opportunity.Opportunity_ID__c;
        record.REQ_DATE_H = String.valueOf(oppItemsVCMap.get(vc.Id).Opportunity.Expected_Delivery_Date__c).replaceall('-','');
        //record.SALES_ORG = 'IN01';
        record.SALES_ORG = oppItemsVCMap.get(vc.Id).Opportunity.Sales_Organization_User__r.code__c;
        record.SHIP_TO_PARTY = 'ICY-AU10';
        record.PS_HZ_FOUNDATION_BOLT = vc.Foundation_Bolt__c;
        
        system.debug('record.ACCESSORIES_REQUIRED : '  +record.ACCESSORIES_REQUIRED);
        system.debug('record.CUSTOMER_NAME : '  +record.CUSTOMER_NAME);
        system.debug('record.CUSTOMER_NUMBER : '  +record.CUSTOMER_NUMBER);
        system.debug('record.DIST_CHANNEL : '  +record.DIST_CHANNEL);
        system.debug('record.DIVISION : '  +record.DIVISION);
        system.debug('record.HS_HOSE_TYPE : '  +record.HS_HOSE_TYPE);
        system.debug('record.HS_WALL_TYPE : '  +record.HS_WALL_TYPE);
        system.debug('record.MaterialName : '  +record.MaterialName);
        system.debug('record.MOTOR_EFFICIENCY : '  +record.MOTOR_EFFICIENCY);
        system.debug('record.MOTOR_FRAME_MOC : '  +record.MOTOR_FRAME_MOC);
        system.debug('record.MOTOR_FRAME_NUMBER : '  +record.MOTOR_FRAME_NUMBER);
        system.debug('record.MOTOR_FRAME_STANDARD : '  +record.MOTOR_FRAME_STANDARD);
        system.debug('record.MOTOR_INGRESS_PROTECTION : '  +record.MOTOR_INGRESS_PROTECTION);
        system.debug('record.MOTOR_MOUNTING_ORIENTATION : '  +record.MOTOR_MOUNTING_ORIENTATION);
        system.debug('record.MOTOR_MOUNTING_TYPE : '  +record.MOTOR_MOUNTING_TYPE);
        system.debug('record.MOTOR_OUTPUT_POWER : '  +record.MOTOR_OUTPUT_POWER);
        system.debug('record.MOTOR_POLES : '  +record.MOTOR_POLES);
        system.debug('record.MOTOR_REQUIRED : '  +record.MOTOR_REQUIRED);
        system.debug('record.MOTOR_TERMIANAL_BOX : '  +record.MOTOR_TERMIANAL_BOX);
        system.debug('record.MOTOR_VOLTAGE : '  +record.MOTOR_VOLTAGE);
        system.debug('record.PLANT : '  +record.PLANT);
        system.debug('record.PRODUCT_LINE : '  +record.PRODUCT_LINE);
        system.debug('record.PS_CH_MOTOR_FREQUENCY : '  +record.PS_CH_MOTOR_FREQUENCY);
        system.debug('record.PS_HZ_CONFIG_TYPE : '  +record.PS_HZ_CONFIG_TYPE);
        system.debug('record.PS_HZ_DISCHARGE_POSITION : '  +record.PS_HZ_DISCHARGE_POSITION);
        system.debug('record.PS_HZ_DRIVE_CATEGORY : '  +record.PS_HZ_DRIVE_CATEGORY);
        system.debug('record.PS_HZ_DRIVE_END_TYPE : '  +record.PS_HZ_DRIVE_END_TYPE);
        system.debug('record.PS_HZ_DRIVE_TYPE : '  +record.PS_HZ_DRIVE_TYPE);
        system.debug('record.PS_HZ_EXPELLER_MATERIAL : '  +record.PS_HZ_EXPELLER_MATERIAL);
        system.debug('record.PS_HZ_EXPELLER_RING_MATERIAL : '  +record.PS_HZ_EXPELLER_RING_MATERIAL);
        system.debug('record.PS_HZ_FLANGE_REQ : '  +record.PS_HZ_FLANGE_REQ);
        system.debug('record.PS_HZ_FRAME_PLATE_INSERT_MAT : '  +record.PS_HZ_FRAME_PLATE_INSERT_MAT);
        system.debug('record.PS_HZ_FRAME_PLATE_TYPE : '  +record.PS_HZ_FRAME_PLATE_TYPE);
        system.debug('record.PS_HZ_GUARDING_TYPE : '  +record.PS_HZ_GUARDING_TYPE);
        system.debug('record.PS_HZ_IMPELLER_MATERIAL : '  +record.PS_HZ_IMPELLER_MATERIAL);
        system.debug('record.PS_HZ_IMPELLER_TYPE : '  +record.PS_HZ_IMPELLER_TYPE);
        system.debug('record.PS_HZ_MOTOR_MAKE : '  +record.PS_HZ_MOTOR_MAKE);
        system.debug('record.PS_HZ_PULLEY_MAKE : '  +record.PS_HZ_PULLEY_MAKE);
        system.debug('record.PS_HZ_PULLEY_SPL_REQ : '  +record.PS_HZ_PULLEY_SPL_REQ);
        system.debug('record.PS_HZ_PUMP_FRAME_TYPE : '  +record.PS_HZ_PUMP_FRAME_TYPE);
        system.debug('record.PS_HZ_PUMP_MODEL : '  +record.PS_HZ_PUMP_MODEL);
        system.debug('record.PS_HZ_PUMP_ROTATION : '  +record.PS_HZ_PUMP_ROTATION);
        system.debug('record.PS_HZ_PUMP_SIZE : '  +record.PS_HZ_PUMP_SIZE);
        system.debug('record.PS_HZ_PUMP_SPEED : '  +record.PS_HZ_PUMP_SPEED);
        system.debug('record.PS_HZ_PUMP_TYPE : '  +record.PS_HZ_PUMP_TYPE);
        system.debug('record.PS_HZ_PUMP_VARIANT : '  +record.PS_HZ_PUMP_VARIANT);
        system.debug('record.PS_HZ_SEALING_TYPE : '  +record.PS_HZ_SEALING_TYPE);
        system.debug('record.PS_HZ_STUFFING_BOX_MATERIAL : '  +record.PS_HZ_STUFFING_BOX_MATERIAL);
        system.debug('record.PS_HZ_THROATBUSH_ADJUSTMENT : '  +record.PS_HZ_THROATBUSH_ADJUSTMENT);
        system.debug('record.PS_HZ_THROATBUSH_MATERIAL : '  +record.PS_HZ_THROATBUSH_MATERIAL);
        system.debug('record.PS_HZ_THROATBUSH_TYPE : '  +record.PS_HZ_THROATBUSH_TYPE);
        system.debug('record.PS_HZ_VOLUTE_MATERIAL : '  +record.PS_HZ_VOLUTE_MATERIAL);
        system.debug('record.PS_HZ_VOLUTE_TYPE : '  +record.PS_HZ_VOLUTE_TYPE);
        system.debug('record.PS_HZ_WET_END_TYPE : '  +record.PS_HZ_WET_END_TYPE);
        system.debug('record.PULLEYS_BELTS_REQUIRED : '  +record.PULLEYS_BELTS_REQUIRED);
        system.debug('record.QUANTITY : '  +record.QUANTITY);
        system.debug('record.QUOTATION_FileName : '  +record.QUOTATION_FileName);
        system.debug('record.REQ_DATE_H : '  +record.REQ_DATE_H);
        system.debug('record.SALES_ORG : '  +record.SALES_ORG);
        system.debug('record.SHIP_TO_PARTY : '  +record.SHIP_TO_PARTY);
        
        return record;
    }
    */
    
    
}