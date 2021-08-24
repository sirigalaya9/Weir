global with sharing class QuoteProductHandler {
    
    public static List<Quote> quoteList {get; set;}
    public static List<QuoteLineItem> oliList {get; set;}
    public static List<vcOppItemsWrapper> vcOppItemsWrapperList{get;set;}
    public static List<QuoteLineItem> quoteItemList {get; set;}
    public static vcSAPResponse vcSAPStatus {get; set;}
    public class vcSAPResponse
    {
        @AuraEnabled public Boolean vcSuccess {get; set;}
        @AuraEnabled public List<QuoteLineItem> QuoteLineItems {get; set;}
        @AuraEnabled public Id quoteERPId{get; set;}
    }
    
    public class vcOppItemsWrapper
    {
        @AuraEnabled public OpportunityLineItem oppLineItemData {get; set;}
        //@AuraEnabled public Variable_Configurator__c vcData {get; set;}
    }
    
    @AuraEnabled
    public static List<Quote> ValidateSGTProfile(Id objId)
    {
        Boolean allowInquiry = false;
        quoteList = [SELECT Id, Opportunity.SGTProfile__c, Opportunity.StageName, Opportunity.CloseDate, Opportunity.Expected_Delivery_Date__c,Opportunity.CurrencyIsoCode,
                     Opportunity.Opportunity_ID__c,Opportunity.Division__c, Opportunity.Channel__c, Opportunity.Sales_Organization_User__r.code__c,
                     //Opportunity.Quote_SAP_Status__c,Opportunity.Quote_ERP_Id__c, Variable_Configurator__c, CreateQuoteSAP_Success__c,Is_VC_Material__c
                     AccountId, Account.CreatedBy.profileId, Account.Name,Account.Type, 
                     (SELECT Id, Material_Number__r.Name FROM QuoteLineItems ORDER BY Id)
                     FROM Quote WHERE id =:objId ];
        
        if(!quoteList.isEmpty())
        {
            quoteList[0].Opportunity.SGTProfile__c = false;
            Id accProfileId = quoteList[0].Account.CreatedBy.profileId;
            Id userProfileId = userinfo.getProfileId();
            String accprofileName = [Select Id, Name from Profile WHERE Id=:accProfileId].Name;
            String userprofileName = [Select Id, Name from Profile WHERE Id=:userProfileId].Name;
            system.debug('accProfileName: '+accprofileName+' accProfileID: '+accprofileId+' userProfileName: '+userprofileName+' userProfileID: '+userprofileId);
            HCI_SAP__c accMC = HCI_SAP__c.getInstance(accprofileId);
            HCI_SAP__c userMC = HCI_SAP__c.getInstance(userprofileId);
            system.debug('accMC: '+accMC+' userMC: '+userMC);
            if(accMC.Allow_Push_to_SAP__c == true && userMC.Allow_Push_to_SAP__c == true)
            {    
                quoteList[0].Opportunity.SGTProfile__c = true;
                system.debug('----You are SGT Profile----');
            }
            else {system.debug('----You are not SGT Profile----');}
        }
        return quoteList;
    }
    
    
    @AuraEnabled
    Public static List<QuoteLineItem> getQuoteItems (Id objId)
    {
        List<QuoteLineItem > quoteItemList =  [SELECT Id, QuoteId, Quote.OpportunityId, PricebookEntryId, Product2Id, Quantity, UnitPrice, Material_Number__c,
                                                Product_Form_Id__c        
                                               //MaterialHierarchy__c, ProductHierarchy__c, Material_Description__c, Is_VC_Material__c, Item_Number__c, 
                                               //Material_Description1__c, Product_Name__c, Variable_Configurator__c,CreateQuoteSAP_Success__c, VC_RecordType_Id__c,
                                               //Line_Item_Text__c,Is_VC_Material__c,Availability_to_Promise_ATP__c,Net_Value_PR00__c,Discount_K007__c,Discount_K008_Value__c,Cost_for_Generic_Material__c                                               
                                               //CreateQuoteSAP_Success__c, Material_Number__r.Is_VC__c,Material_Number__r.VC_Type__c,Variable_Configurator__r.Name,                                               
                                               //Variable_Configurator__r.Account__c, Variable_Configurator__r.Opportunity__c, Variable_Configurator__r.RecordTypeId, VC__c, VC__r.Form_Config__r.API_Name__c
                                               FROM QuoteLineItem WHERE QuoteId =: objId Order By Id];
        system.debug('getQuoteItems '+quoteItemList.size());
        
        return quoteItemList;
    }
    
    @AuraEnabled
    Public static Material_Number__c getMaterials (Id materialId)
    {
        Material_Number__c material =  [SELECT Id, Name, ERP_ID__c, Material_Status__c, Material_Description__c, Material_Type__c,
        //Is_VC__c,
                                        Product_Code__c, Quantity_Unit_Of_Measure__c, Third_Level_Material_Hierarchy_Name__c
                                        //, VC_Type__c 
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
        Variable_Configurator__c vc =  [SELECT Id, Name FROM Variable_Configurator__c where Name =: vcName];
        system.debug('VC : '+vc);
        return vc;
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
    Public static void QuoteyProductDML2 (List<QuoteLineItem> vcQuoteItemsList, List<QuoteLineItem> QuoteProductToDelete, String quoteCurrency){
        
        Set<Id> productIdSet = new Set<Id>();
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        Map<Integer,OpportunityLineItem> oppItemMap = new Map<Integer,OpportunityLineItem>();
        List<String> thirdLevelList = new List<String>();
        List<QuoteLineItem> oLineList = new List<QuoteLineItem>();
        String msg = '';
        Integer itemNo = 0;
        //List<Variable_Configurator__c> vcList = new List<Variable_Configurator__c>();
        //List<QuoteLineItem> vcQuoteItemsList = new List<QuoteLineItem>();
        List<Integer> oppItemIndex = new List<Integer>();
        Integer no = 0;
        
        System.debug('QuoteyProductDML');
        if(!vcQuoteItemsList.isEmpty())
        {
            
            for(QuoteLineItem item : vcQuoteItemsList){
                productIdSet.add(item.Product2Id); 
            }
            for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c,Product2Id
                                          FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: quoteCurrency
                                          AND Product2Id IN: productIdSet]){
                                              pbEntryMap.put(pbEntry.Product2Id, pbEntry.id); 
                                          }
            
            System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
            
            for(QuoteLineItem item : vcQuoteItemsList)
            {
                if (!pbEntryMap.isEmpty())
                {
                    QuoteLineItem oItem = new QuoteLineItem();
                    if(pbEntryMap.containsKey(item.Product2Id)) oItem.PricebookEntryId = pbEntryMap.get(item.Product2Id);
                    if(item.Id != null){
                        oItem.Id = item.Id;
                    }
                    else oItem.QuoteId = item.QuoteId;
                    oItem.Material_Number__c = item.Material_Number__c;
                    oItem.quantity = item.Quantity;
                    oItem.UnitPrice = item.UnitPrice;
                    //oItem.Line_Item_Text__c = item.Line_Item_Text__c ;
                    //oItem.Variable_Configurator__c = item.Variable_Configurator__c;
                    //oItem.VC__c = item.VC__c;
                    //oItem.Is_VC_Material__c = item.Is_VC_Material__c;
                    
                    //oItem.Availability_to_Promise_ATP__c = item.Availability_to_Promise_ATP__c;
                    //oItem.Net_Value_PR00__c = item.Net_Value_PR00__c;
                    //oItem.Discount_K007__c = item.Discount_K007__c;
                    //oItem.Discount_K008_Value__c = item.Discount_K008_Value__c;
                    //oItem.Cost_for_Generic_Material__c = item.Cost_for_Generic_Material__c;
                    //oItem.Markup_ZM01__c = item.Markup_ZM01__c;
                    //oItem.Markup_ZM02__c = item.Markup_ZM02__c;
                    //oItem.Tax_MWST__c = item.Tax_MWST__c;
                    //oItem.Cost_VPRS_Internal_Price__c = item.Cost_VPRS_Internal_Price__c;
                    
                    oLineList.add(oItem);
                    system.debug('oItem: '+itemNo+' '+item);
                    itemNo = itemNo+1;
                }
            }
        }
        
        Integer item = 1;
        Boolean error = false;
        Database.UpsertResult [] oppItemResult = Database.upsert(oLineList, QuoteLineItem.Fields.Id, false);
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
        
        if(!QuoteProductToDelete.isEmpty() && error == false)
        {
            System.debug('QuoteProductToDelete : '+QuoteProductToDelete);
            try{
                delete QuoteProductToDelete;
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
    Public static Boolean SendToSAP (Id objId)
    {
        system.debug('objId : '+objId);
        Set<Id> vcIdSet = new Set<Id>();
        Map<Id, QuoteLineItem> oppItemsVCMap = new Map<Id, QuoteLineItem>();
        List<QuoteLineItem> oliToUpdate = new List<QuoteLineItem>();
        vcSAPStatus = new VCSAPResponse();
        Quote mQuote;
        
        sapComDocumentSapIdocSoapMessages.IdocAssign Response = new sapComDocumentSapIdocSoapMessages.IdocAssign();
        sapComDocumentSapIdocSoapMessages.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202 reqMessage = new sapComDocumentSapIdocSoapMessages.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202();
        sapComDocumentSapIdocSoapMessages.QuotePort01 reqPort = new sapComDocumentSapIdocSoapMessages.QuotePort01();
        sapComDocumentSapIdocSoapMessages.E1SALESORDER_CREATEFROMDAT2_000 E1SALESORDER = new sapComDocumentSapIdocSoapMessages.E1SALESORDER_CREATEFROMDAT2_000();
        
        //Incoterm1,Incoterm2,Payment Term,Shipping Condition
        sapComDocumentSapIdocSoapMessages.E1BPSDHD1_003 E1BPSDHD1 = new sapComDocumentSapIdocSoapMessages.E1BPSDHD1_003();
        
        //Line Item Text
        sapComDocumentSapIdocSoapMessages.E1BPSDTEXT_000[] E1BPSDTEXT = new List<sapComDocumentSapIdocSoapMessages.E1BPSDTEXT_000>();
        
        //Availability-to-Promise (ATP)
        sapComDocumentSapIdocSoapMessages.E1BPSCHDL_001[] E1BPSCHDL = new List<sapComDocumentSapIdocSoapMessages.E1BPSCHDL_001>();
        
        //Net Value – PR00, Discount – K007(%), Cost (for Generic Material)
        sapComDocumentSapIdocSoapMessages.E1BPCOND_001[] E1BPCOND = new List<sapComDocumentSapIdocSoapMessages.E1BPCOND_001>();
        
        //ITM_NUMBER
        sapComDocumentSapIdocSoapMessages.E1BPSDITM_000[] E1BPSDITM = new List<sapComDocumentSapIdocSoapMessages.E1BPSDITM_000>();
        
        sapComDocumentSapIdocSoapMessages.E1BPPARNR_000[] E1BPPARNR = new List<sapComDocumentSapIdocSoapMessages.E1BPPARNR_000>();
        
        
        List<QuoteLineItem>  oliList = [SELECT Id, QuoteId,Quote.OpportunityId, Quote.Opportunity.Opportunity_ID__c,
                                        Quote.Opportunity.Incoterm1__c,Quote.Opportunity.Incoterm2__c,Quote.CurrencyIsoCode,
                                        Quote.Opportunity.Payment_Term__c,Quote.Opportunity.Shipping_Condition__c,
                                        Line_Item_Text__c,Availability_to_Promise_ATP__c,Net_Value_PR00__c,Discount_K007__c,Discount_K008_Value__c,Cost_for_Generic_Material__c,
                                        Quote.Opportunity.Plant__c,Quote.Opportunity.Division__c, Quote.Opportunity.Channel__c, Quote.Opportunity.Sales_Group__c,
                                        Quote.Opportunity.Sales_Office__c, Quote.Opportunity.Sales_Organization_User__r.code__c,Quote.ERP_Id__c,
                                        Quote.Opportunity.Expected_Delivery_Date__c,Quote.Account.ERP_Id__c,Quote.Shipping_Address__r.ERP_Id__c,Material_Number__c,
                                        COND_ST_NO_PR00__c, COND_COUNT_PR00__c,COND_ST_NO_K007__c,COND_COUNT_K007__c,COND_ST_NO_K008__c, COND_COUNT_K008__c,
                                        Quote.Incoterm1__c,Quote.Incoterm2__c,Quote.Payment_Term__c,Quote.Shipping_Condition__c,Quote.Notes__c,
                                        UnitPrice, Quantity, Description,Item_No__c,Variable_Configurator__c, CreateQuoteSAP_Success__c, Is_VC_Material__c
                                        FROM QuoteLineItem WHERE QuoteId =: objId];
        
        system.debug('QuoteId : '+objId);
        system.debug('oliList : '+oliList);
        sapComDocumentSapIdocSoapMessages.E1BPPARNR_000 E1BPPARNR_Temp;
        if(!oliList.isEmpty())    
        { 
            
            List<Condition_Types__c> conList = [SELECT Id, Sales_Organization__c, Channel__c, Gross_Value__c, Discount__c 
                                                FROM Condition_Types__c
                                                WHERE Sales_Organization__c =: oliList[0].Quote.Opportunity.Sales_Organization_User__r.code__c
                                                AND Channel__c =: oliList[0].Quote.Opportunity.Channel__c Limit 1];
            
            E1SALESORDER.SALESDOCUMENTIN = oliList[0].Quote.ERP_Id__c;
            E1BPSDHD1.REFOBJKEY = oliList[0].Quote.ERP_Id__c;                
            E1BPSDHD1.SALES_ORG = oliList[0].Quote.Opportunity.Sales_Organization_User__r.code__c;
            E1BPSDHD1.DISTR_CHAN = oliList[0].Quote.Opportunity.Channel__c;
            E1BPSDHD1.DIVISION = oliList[0].Quote.Opportunity.Division__c;
            E1BPSDHD1.PURCH_NO_C = oliList[0].Quote.Opportunity.Opportunity_ID__c;
            E1BPSDHD1.INCOTERMS1 = oliList[0].Quote.Incoterm1__c;
            E1BPSDHD1.INCOTERMS2 = oliList[0].Quote.Incoterm2__c;
            E1BPSDHD1.PMNTTRMS = oliList[0].Quote.Payment_Term__c;
            E1BPSDHD1.SHIP_COND = oliList[0].Quote.Shipping_Condition__c;
            
            system.debug('E1BPSDHD1.REFOBJKEY : '+E1BPSDHD1.REFOBJKEY);
            system.debug('E1BPSDHD1.SALES_ORG : '+E1BPSDHD1.SALES_ORG);
            system.debug('E1BPSDHD1.DISTR_CHAN : '+E1BPSDHD1.DISTR_CHAN);
            system.debug('E1BPSDHD1.DIVISION : '+E1BPSDHD1.DIVISION);
            system.debug('E1BPSDHD1.INCOTERMS1 : '+E1BPSDHD1.INCOTERMS1);
            system.debug('E1BPSDHD1.INCOTERMS2 : '+E1BPSDHD1.INCOTERMS2);
            system.debug('E1BPSDHD1.PMNTTRMS : '+E1BPSDHD1.PMNTTRMS);
            system.debug('E1BPSDHD1.SHIP_COND : '+E1BPSDHD1.SHIP_COND);
            
            E1BPPARNR_Temp = new sapComDocumentSapIdocSoapMessages.E1BPPARNR_000();
            E1BPPARNR_Temp.PARTN_ROLE = 'AG';
            E1BPPARNR_Temp.PARTN_NUMB = oliList[0].Quote.Account.ERP_Id__c;
            E1BPPARNR.add(E1BPPARNR_Temp);
            system.debug('E1BPPARNR AG : '+E1BPPARNR_Temp.PARTN_ROLE);
            system.debug('E1BPPARNR AG : '+E1BPPARNR_Temp.PARTN_NUMB);
            
            
            E1BPPARNR_Temp = new sapComDocumentSapIdocSoapMessages.E1BPPARNR_000();
            E1BPPARNR_Temp.PARTN_ROLE = 'WE';
            E1BPPARNR_Temp.PARTN_NUMB = oliList[0].Quote.Shipping_Address__r.ERP_Id__c;
            E1BPPARNR.add(E1BPPARNR_Temp);
            system.debug('E1BPPARNR WE : '+E1BPPARNR_Temp.PARTN_ROLE);
            system.debug('E1BPPARNR WE : '+E1BPPARNR_Temp.PARTN_NUMB);
            
            sapComDocumentSapIdocSoapMessages.E1BPSDTEXT_000 E1BPSDTEXT_Temp = new sapComDocumentSapIdocSoapMessages.E1BPSDTEXT_000();
            E1BPSDTEXT_Temp.ITM_NUMBER = '0';
            E1BPSDTEXT_Temp.TEXT_LINE = oliList[0].Quote.Notes__c;
            E1BPSDTEXT.add(E1BPSDTEXT_Temp);
            system.debug('E1BPSDTEXT_Temp.ITM_NUMBER : '+E1BPSDTEXT_Temp.ITM_NUMBER);
            system.debug('E1BPSDTEXT_Temp.TEXT_LINE : '+E1BPSDTEXT_Temp.TEXT_LINE);
            
            for(QuoteLineItem oItem : oliList)
            {
                E1BPSDTEXT_Temp = new sapComDocumentSapIdocSoapMessages.E1BPSDTEXT_000();
                //sapComDocumentSapIdocSoapMessages.E1BPSCHDL_001 E1BPSCHDL_Temp = new sapComDocumentSapIdocSoapMessages.E1BPSCHDL_001();
                sapComDocumentSapIdocSoapMessages.E1BPSDITM_000 E1BPSDITM_Temp = new sapComDocumentSapIdocSoapMessages.E1BPSDITM_000();
                
                //Item Number
                E1BPSDITM_Temp.ITM_NUMBER = String.valueOf(oItem.Item_No__c);
                E1BPSDITM.add(E1BPSDITM_Temp);
                system.debug('E1BPSDITM_Temp.ITM_NUMBER : '+E1BPSDITM_Temp.ITM_NUMBER);
                
                
                //Line Item Text
                E1BPSDTEXT_Temp.ITM_NUMBER = String.valueOf(oItem.Item_No__c);
                E1BPSDTEXT_Temp.TEXT_LINE = oItem.Line_Item_Text__c;
                E1BPSDTEXT.add(E1BPSDTEXT_Temp);
                system.debug('E1BPSDTEXT_Temp.ITM_NUMBER : '+E1BPSDTEXT_Temp.ITM_NUMBER);
                system.debug('E1BPSDTEXT_Temp.TEXT_LINE : '+E1BPSDTEXT_Temp.TEXT_LINE);
                

                
                //PR00, K007(%), VPRS
                for(Integer i=0; i<2; i++)
                {
                    sapComDocumentSapIdocSoapMessages.E1BPCOND_001 E1BPCOND_Temp = new sapComDocumentSapIdocSoapMessages.E1BPCOND_001();
                    E1BPCOND_Temp.ITM_NUMBER = String.valueOf(oItem.Item_No__c);
                    
                    if(i == 0) 
                    {
                        E1BPCOND_Temp.COND_TYPE = conList[0].Gross_Value__c;
                        E1BPCOND_Temp.COND_VALUE = String.valueOf(oItem.Net_Value_PR00__c);
                        if(oItem.COND_ST_NO_PR00__c != null){
                            E1BPCOND_Temp.COND_COUNT = String.valueOf(oItem.COND_COUNT_PR00__c );
                            E1BPCOND_Temp.COND_ST_NO = String.valueOf(oItem.COND_ST_NO_PR00__c );
                        }
                    }
                    else if(i == 1)
                    {

                        
                        E1BPCOND_Temp.COND_TYPE = conList[0].Discount__c;
                        E1BPCOND_Temp.COND_VALUE = String.valueOf(oItem.Discount_K007__c);
                        if(oItem.COND_ST_NO_K007__c != null){
                            E1BPCOND_Temp.COND_COUNT = String.valueOf(oItem.COND_COUNT_K007__c );
                            E1BPCOND_Temp.COND_ST_NO = String.valueOf(oItem.COND_ST_NO_K007__c );
                        }
                    }
                        


                        E1BPCOND_Temp.CURR_ISO = oItem.Quote.CurrencyIsoCode;
                        
                        
                        system.debug('E1BPCOND_Temp.ITM_NUMBER : '+E1BPCOND_Temp.ITM_NUMBER);
                        system.debug('E1BPCOND_Temp.COND_TYPE : '+E1BPCOND_Temp.COND_TYPE);
                        system.debug('E1BPCOND_Temp.COND_VALUE : '+E1BPCOND_Temp.COND_VALUE);
                        system.debug('E1BPCOND_Temp.CURR_ISO : '+E1BPCOND_Temp.CURR_ISO);
                        system.debug('E1BPCOND_Temp.COND_COUNT : '+E1BPCOND_Temp.COND_COUNT);
                        system.debug('E1BPCOND_Temp.COND_ST_NO : '+E1BPCOND_Temp.COND_ST_NO);
                        E1BPCOND.add(E1BPCOND_Temp);
                    }
                }
                
                E1SALESORDER.E1BPSDHD1 = E1BPSDHD1;
                E1SALESORDER.E1BPSDTEXT = E1BPSDTEXT;
                //E1SALESORDER.E1BPSCHDL = E1BPSCHDL;
                E1SALESORDER.E1BPSDITM = E1BPSDITM;
                E1SALESORDER.E1BPCOND = E1BPCOND;
                //E1SALESORDER.E1BPPARNR = E1BPPARNR;
                
                reqMessage.E1SALESORDER_CREATEFROMDAT2 = E1SALESORDER;
                
            }
            
            Boolean resSuccess = false;
            
            try
            {
                
                response = reqPort.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202(reqMessage);
                system.debug('Response DbId : '+response.DbId);
                if(response.dbId <> Null)
                {
                    resSuccess = true;
                    mQuote = new Quote(Id = objId, Pricing_Status__c  = 'In Progress');
                    update mQuote;
                    system.debug('Send Request to update Pricing Successfully!!!');
                }
                else
                {
                    resSuccess = false; 
                }
                
                system.debug('resSuccess: '+resSuccess);
            } 
            catch(Exception e)
            {
                System.debug(e.getMessage() + ' ' + e.getLineNumber());
                throw new AuraHandledException(e.getMessage());
                
            } 
        return resSuccess;
        
        }
    
    public static weirComB2bFolderRfq.Record_element map_WGR_Pump(Variable_Configurator__c vc, Map<Id, QuoteLineItem> oppItemsVCMap)
    { 
        weirComB2bFolderRfq.Record_element record = new weirComB2bFolderRfq.Record_element();
        record.CUSTOMER_NUMBER = 'ICY-GB10';
        //record.CUSTOMER_NUMBER = oppItemsVCMap.get(vc.Id).Opportunity.Account.ERP_Id__c;
        record.DIST_CHANNEL = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Channel__c;
        record.DIVISION = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Division__c;
        record.DRAWING_Number = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Opportunity_ID__c + oppItemsVCMap.get(vc.Id).Item_No__c;
        record.PLANT = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Plant__c;
        record.PRODUCT_LINE = 'STRAIGHT';
        record.QUANTITY = String.valueOf(oppItemsVCMap.get(vc.Id).Quantity);
        record.QUOTATION_FileName = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Opportunity_ID__c;
        record.REQ_DATE_H = String.valueOf(oppItemsVCMap.get(vc.Id).Quote.Opportunity.Expected_Delivery_Date__c).replaceall('-','');
        record.SALES_ORG = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Sales_Organization_User__r.code__c;
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
    
    public static weirComB2bFolderRfq.Record_element map_WMI_Horizontal_Pumps(Variable_Configurator__c vc, Map<Id, QuoteLineItem> oppItemsVCMap)
    { 
        weirComB2bFolderRfq.Record_element record = new weirComB2bFolderRfq.Record_element();
        
        record.CUSTOMER_NAME = 'ICY-AU10';
        record.CUSTOMER_NUMBER = 'ICY-AU10';
        record.DIST_CHANNEL = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Channel__c;
        record.DIVISION = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Division__c;
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
        record.PLANT = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Plant__c;
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
        record.QUOTATION_FileName = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Opportunity_ID__c;
        record.REQ_DATE_H = String.valueOf(oppItemsVCMap.get(vc.Id).Quote.Opportunity.Expected_Delivery_Date__c).replaceall('-','');
        //record.SALES_ORG = 'IN01';
        record.SALES_ORG = oppItemsVCMap.get(vc.Id).Quote.Opportunity.Sales_Organization_User__r.code__c;
        record.SHIP_TO_PARTY = 'ICY-AU10';
        
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