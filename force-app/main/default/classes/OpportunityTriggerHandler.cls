public class OpportunityTriggerHandler {
    
    public static Set<Id> oppIds = new Set <Id>();
    public static Set<Id> MaterialIds = new Set<Id>();    
    public static String saleOrgCode ;
    public static List<String> invalidHierarchyList = new List<String>();
    public static Map<String,Id> pbEntryMap = new Map<String,Id>();
    public static Map<String,String> invalidHierarchyMap = new Map<String,String>();
    public static List<Organization_Structure__c> orgStruc;
    public static List<Sales_Area_Detail__c> salesArea;
    public static Sales_Area_Detail__c mSaleAreaDetail;
    public static ObjectTerritory2Association mAccTerritory;
    
    public static Map<Id, List<Opportunity>> projectIdOppsMap = new Map<Id, List<Opportunity>>();
    public static Set<String> currencyISoCodes = new Set<String>();
    public static Map<String, Double> codeCurrencyTypeMap = new Map<String, Double>();
    public static List<Project__c> updatedProjs = new List<Project__c>();
    
    public static List<Organization_Structure__c> QueryOrganizationStructure(Opportunity opp, String recordTypeName){
        
        String q = 'SELECT Id, Name, Sales_Organization__c, Distribution_Channel__c,Division__c,'+
            ' Sales_District__c,Sales_Office__c, Sales_Group__c, Territoty_ID__c, Territory_Name__c '+
            ' FROM Organization_Structure__c'+
            ' WHERE Distribution_Channel__c = \''+opp.Channel__c+'\''+
            //' AND Division__c = \''+opp.Division__c+'\''+
            ' AND Sales_Office__c = \''+opp.Sales_Office__c+'\''+
            ' AND Sales_Group__c = \''+opp.Sales_Group__c+'\''+
            ' AND Sales_Organization__c = \''+opp.Sales_Organization_User_Code__c+'\''+
            ' AND Status__c = \'Active\'';
        
        if (opp.Sales_Office__c != null && opp.Sales_Group__c != null)
        {
            if(recordTypeName.contains('SGT'))
                q = q + ' AND SGT__c = TRUE ';
            if(recordTypeName.contains('Standalone'))
            {
                q = q + ' AND SGT__c = FALSE ';
                if(opp.Sales_District__c != null)
                    q = q + ' AND Sales_District__c = \''+opp.Sales_District__c+'\'';
            }
        }
        else
            q = null;
        
        system.debug('q orgStruc : '+q);
        if(q != null) orgStruc = Database.query(q);
        
        return orgStruc;
    }
    
    public static List<Sales_Area_Detail__c> QuerySalesAreaDetail(Opportunity opp, String recordTypeName){
        
        String q = 'SELECT Id, Organization_Structure__c, Organization_Structure__r.Sales_Organization__c,'+
            ' Organization_Structure__r.Distribution_Channel__c, Organization_Structure__r.Division__c,'+
            ' Organization_Structure__r.Sales_Office__c, Organization_Structure__r.Sales_Group__c, Organization_Structure__r.Sales_District__c,'+
            ' Organization_Structure__r.Territoty_ID__c, Organization_Structure__r.Territory_Name__c'+
            ' FROM Sales_Area_Detail__c'+
            ' WHERE Account__c = \''+opp.AccountId+'\''+
            ' AND Organization_Structure__r.Sales_Organization__c = \''+opp.Sales_Org_Code__c+'\''+
            ' AND Organization_Structure__r.Distribution_Channel__c = \''+opp.Channel__c+'\''+
            ' AND Organization_Structure__r.Division__c = \''+opp.Division__c+'\''+
            ' AND Organization_Structure__r.Status__c = \'Active\'';
        
        if(recordTypeName.contains('SGT'))
            q = q + ' AND Organization_Structure__r.SGT__c = TRUE';
        else if(recordTypeName.contains('Standalone'))
            q = q + ' AND Organization_Structure__r.SGT__c = FALSE';
        
        system.debug('q : '+q);
        if(q != null) salesArea = Database.query(q);
        
        return salesArea;
    }
    
    public static List<Sales_Area_Detail__c> PoppulateSalesAreaDetail(List<Organization_Structure__c> orgStruc, List<Sales_Area_Detail__c> accSaleAreaDetails, Id accountID){
        
        List<Sales_Area_Detail__c> mSaleAreaDetailList = new List<Sales_Area_Detail__c>();
        
        for(Organization_Structure__c org : orgStruc)
        {
            Boolean isFound = false;
            for(Sales_Area_Detail__c saleArea : accSaleAreaDetails)
                if(org.id == saleArea.Organization_Structure__c) isFound = true;
            if(isFound == false)
            {
                mSaleAreaDetail = new Sales_Area_Detail__c();
                mSaleAreaDetail.Organization_Structure__c = org.id;
                mSaleAreaDetail.Account__c = accountID;
                mSaleAreaDetailList.add(mSaleAreaDetail);
            }
            else
                system.debug('Duplicated SaleAreaDetail : '+org.id); 
        }
        return mSaleAreaDetailList;
    }
    
    public static List<ObjectTerritory2Association> PoppulateAccountTerritory(List<Organization_Structure__c> orgStruc, Id accountID){
        
        List<ObjectTerritory2Association> mAccTerritoryList = new List<ObjectTerritory2Association>(
            [SELECT Id, ObjectId, Territory2Id FROM ObjectTerritory2Association 
             WHERE ObjectId =: accountID AND Territory2Id =: orgStruc[0].Territoty_ID__c]);
        
        if(!mAccTerritoryList.isEmpty())
            mAccTerritoryList = null;
        else{
            mAccTerritory = new ObjectTerritory2Association();
            mAccTerritory.ObjectId = accountID;
            mAccTerritory.Territory2Id = orgStruc[0].Territoty_ID__c;
            mAccTerritory.AssociationCause = 'Territory2Manual';
            mAccTerritoryList.add(mAccTerritory);
        }
         return mAccTerritoryList;
    }
    
    public static List<Project__c> PoppulateTotalOpportunitySum(List<Id> projectIds){
        system.debug('projectIds '+projectIds);
            for(Opportunity opp : [Select Amount, CurrencyISOCode, Publish_to_Forecast__c, Project__r.currencyISOCode, Project__c from Opportunity 
                                   WHERE project__c IN: projectIds AND Publish_to_Forecast__c = TRUE AND StageName != 'Stopped' AND StageName != 'Closed Lost']){
                                       if(!projectIdOppsMap.containsKey(opp.Project__c))
                                       {
                                           projectIdOppsMap.put(opp.Project__c, new List<Opportunity>());
                                       } 
                                       projectIdOppsMap.get(opp.Project__c).add(opp);
                                       currencyISoCodes.add(opp.currencyISOCode);
                                       currencyISoCodes.add(opp.Project__r.currencyISOCode);   
                                   }
            for(CurrencyType currType : [Select conversionRate, ISOCode from CurrencyType where ISOCode = :currencyISOCodes and isActive = TRUE]){
                codeCurrencyTypeMap.put(currType.ISOCode, currType.conversionRate.doubleValue());   
            }
            
            List<Project__c> projs = [Select Total_Opportunity_Sum__c, Id from Project__c where Id = :projectIds];
            
            for(Project__c proj:projs){
                //calculate total sum for each project
                Double totalSum = 0.00;
                List<Opportunity> opps = new List<Opportunity>();
                
                if(projectIdOppsMap.containsKey(proj.Id)){
                    opps = projectIdOppsMap.get(proj.Id);
                    
                    for(Opportunity opp: opps){
                        totalSum += (opp.Amount==null?0.00:opp.Amount)  * codeCurrencyTypeMap.get(opp.Project__r.currencyISOCode)/codeCurrencyTypeMap.get(opp.currencyISOCode);
                    }
                }
                proj.Total_Opportunity_Sum__c = totalSum;
                system.debug('Total_Opportunity_Sum__c '+proj.Total_Opportunity_Sum__c);
                system.debug('updatedProjs size'+updatedProjs.size());
                if(updatedProjs.size() > 1)
                {
                    for(Project__c mPro: updatedProjs)
                    { 
                        if(mPro.Id != proj.Id)
                            updatedProjs.add(proj);
                        else
                            system.debug('Dunplicated Pro ID '+mPro.Id);
                    }
                }
                else
                    updatedProjs.add(proj); 
            }       
        return updatedProjs;
    }
    
    /*public static void createErrorMessage(String errMessage, String Scenario)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = Scenario;
            mError.Error_Message_Detail__c = errMessage;
            insert mError;
            System.debug('createErrorMessage Opportunity');
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }*/
    
    public static void InsertAndUpdateOpp(List<sObject> objectList)
    {
        if(objectList != null && !objectList.isEmpty())
        {
            String oType =  objectList.getSObjectType().getDescribe().getName();
            system.debug('oType :'+oType);   
            system.debug('objectList :'+objectList);
            try
            {
                if(oType == 'Sales_Area_Detail__c' || oType == 'ObjectTerritory2Association') insert objectList;
                else if(oType == 'Project__c')
                {
                    if(objectList.size() == 1) update objectList;
                }
            }
            catch(Exception e){
                System.debug(e.getMessage() + ': ' + e.getLineNumber());
                //createErrorMessage(errMessage, 'Opportunity Trigger');
            }
        }
    }
    
    @future (callout=true)
    public static void SyncDateToSAP(Set<Id> quoteDate_OppIdSet) {
        List<Quote> oppRelatedQuotes = [SELECT Id, Opportunity.Integration_Status__c ,Opportunity.CloseDate, Opportunity.Expected_Delivery_Date__c, ERP_Id__c,
        Opportunity.Application__c, Opportunity.Integrated_Solution__c, Opportunity.Other_Strategic_Initiatives__c, Opportunity.Important__c, Opportunity.Managed_by_Project_Teams__c
        FROM Quote
                                        WHERE IsSyncing = True AND OpportunityId IN: quoteDate_OppIdSet];
        
        if(!oppRelatedQuotes.isEmpty() && oppRelatedQuotes.size() == 1)
        {
            sapComDocumentSapIdocSoapMsgQuote.IdocAssign HCIResponse = new sapComDocumentSapIdocSoapMsgQuote.IdocAssign();
            sapComDocumentSapIdocSoapMsgQuote.QUOTATION_CREATEFROMDATA2_QUOTATION_CREATEFROMDATA202 reqMessage = new sapComDocumentSapIdocSoapMsgQuote.QUOTATION_CREATEFROMDATA2_QUOTATION_CREATEFROMDATA202();
            sapComDocumentSapIdocSoapMsgQuote.QUOTATION_CREATEFROMDATA2Port reqPort = new sapComDocumentSapIdocSoapMsgQuote.QUOTATION_CREATEFROMDATA2Port();
            
            sapComDocumentSapIdocSoapMsgQuote.E1QUOTATION_CREATEFROMDATA2_000 body = new sapComDocumentSapIdocSoapMsgQuote.E1QUOTATION_CREATEFROMDATA2_000();
            sapComDocumentSapIdocSoapMsgQuote.E1BPSDHD1_003 E1BPSDHD1 = new sapComDocumentSapIdocSoapMsgQuote.E1BPSDHD1_003();
            
            try{
                E1BPSDHD1.DOC_TYPE = oppRelatedQuotes[0].Opportunity.Integration_Status__c;
                E1BPSDHD1.QT_VALID_T = String.valueOf(oppRelatedQuotes[0].Opportunity.CloseDate);
                E1BPSDHD1.REQ_DATE_H = String.valueOf(oppRelatedQuotes[0].Opportunity.Expected_Delivery_Date__c);
                body.SALESDOCUMENTIN = oppRelatedQuotes[0].ERP_Id__c;
                body.E1BPSDHD1 = E1BPSDHD1;
                E1BPSDHD1.CUST_GRP1 = oppRelatedQuotes[0].Opportunity.Application__c;
                E1BPSDHD1.CUST_GRP2 = oppRelatedQuotes[0].Opportunity.Integrated_Solution__c;
                E1BPSDHD1.CUST_GRP3 = oppRelatedQuotes[0].Opportunity.Other_Strategic_Initiatives__c;
                E1BPSDHD1.CUST_GRP4 = String.valueOf(oppRelatedQuotes[0].Opportunity.Important__c);
                E1BPSDHD1.CUST_GRP5 = String.valueOf(oppRelatedQuotes[0].Opportunity.Managed_by_Project_Teams__c);                
                
                system.debug('DOC_TYPE : '+E1BPSDHD1.DOC_TYPE);
                system.debug('QT_VALID_T : '+E1BPSDHD1.QT_VALID_T);
                system.debug('REQ_DATE_H : '+E1BPSDHD1.REQ_DATE_H);
                system.debug('SALESDOCUMENTIN : '+body.SALESDOCUMENTIN);
                system.debug('E1BPSDHD1.CUST_GRP1 : '+E1BPSDHD1.CUST_GRP1);
                system.debug('E1BPSDHD1.CUST_GRP2 : '+E1BPSDHD1.CUST_GRP2);
                system.debug('E1BPSDHD1.CUST_GRP3 : '+E1BPSDHD1.CUST_GRP3);
                system.debug('E1BPSDHD1.CUST_GRP4 : '+E1BPSDHD1.CUST_GRP4);
                system.debug('E1BPSDHD1.CUST_GRP5 : '+E1BPSDHD1.CUST_GRP5);
                
                reqMessage.E1QUOTATION_CREATEFROMDATA2 = body;
                HCIResponse = reqPort.QUOTATION_CREATEFROMDATA2_QUOTATION_CREATEFROMDATA202(reqMessage);
                
                system.debug('HCIResponse DbId : '+HCIResponse.DbId);
                if(HCIResponse.dbId <> Null)
                {
                    system.debug('Syncing Expected Delivery/Close Date Successfully!!!');
                }
            }
            catch(Exception e)
            {
                System.debug('Error Syncing Expected Delivery/Close Date ' + e.getMessage() + ' ' + e.getLineNumber());
            } 
            
        }
        else
            system.debug('There is no synced Quotation related');
    }
}