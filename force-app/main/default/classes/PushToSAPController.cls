global with sharing class PushToSAPController {
    
    public static List<Opportunity> oppList {get; set;}
    public static List<OpportunityLineItem> oliList {get; set;}
    public static PushToSAPStatus SAPStatus {get; set;}
    
    public class PushToSAPStatus
    {
        @AuraEnabled public Boolean accToSAPSuccess {get; set;}
        @AuraEnabled public Boolean oppToSAPSuccess{get; set;}
    }
    
    @AuraEnabled
    public static List<Opportunity> ValidateSGTProfile(Id objId)
    {
        try{
            Boolean allowInquiry = false;
            oppList = [SELECT Id, Name, SGTProfile__c, StageName, Integration_Status__c,CloseDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity_ID__c,
                       Division__c, Channel__c, Sales_Group__c, Sales_Office__c, Territory2Id, Sales_Organization_User__r.code__c,
                       AccountId, Account.CreatedBy.profileId, Account.Name,Account.Type, Account.Industry, Account.Industry_Code__c, Account.Phone, Account.Website,
                       Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingStateCode, Account.BillingPostalCode, Account.BillingCountry, Account.BillingCountryCode,
                       Shipping_Address__r.ERP_ID__c, Account.Account_Status__c, Account.Prospect__c, Account.ERP_Id__c, Account.CurrencyIsoCode,
                       Application__c, Integrated_Solution__c, Other_Strategic_Initiatives__c, Important__c, Managed_by_Project_Teams__c, 
                       (SELECT Id, Name, Material_Number__r.Name FROM OpportunityLineItems)
                       FROM Opportunity
                       WHERE id =:objId];
            
            if(!oppList.isEmpty())
            {
                system.debug('oppList');
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
        }
        catch(Exception e){
            
            throw new AuraHandledException('Error Exception happend'+e.getMessage());           
            
        }
        return oppList;
    }
    
    @AuraEnabled
    public static PushToSAPStatus CreateProspectAndInquiryToSAP(List<Opportunity> oppList)
    {
        If(!oppList.isEmpty())
        {
            SAPStatus = new PushToSAPStatus();
            SAPStatus.accToSAPSuccess = true;
            oliList = [SELECT Id, OpportunityId, Name, Material_Number__r.Name,
                       Material_Number__r.Quantity_Unit_Of_Measure__c, UnitPrice, Quantity, Description
                       FROM OpportunityLineItem
                       WHERE OpportunityId =:oppList[0].id];
            system.debug('oliList Size: '+oliList.size());
            system.debug('oppList[0].Account.ERP_Id__c: '+oppList[0].Account.ERP_Id__c);
            if(oppList[0].Account.ERP_Id__c == null)
            {
                SAPStatus.accToSAPSuccess = PushToSAP.CreateProspectAccount(oppList);
            }
            SAPStatus.oppToSAPSuccess = PushToSAP.CreateInquiry(oppList,oliList);
            system.debug('accToSAPSuccess : '+SAPStatus.accToSAPSuccess+' oppToSAPSuccess : '+SAPStatus.oppToSAPSuccess);
        }
        return SAPStatus;
    }
    
    
    @AuraEnabled
    public static List<OpportunityLineItem> getOpportunityItems (Id objId)
    {
        List<OpportunityLineItem> items = [SELECT Id, OpportunityId, Material_Number__c FROM OpportunityLineItem WHERE OpportunityId =:objId];
        system.debug(items);
        return items;
    }
    
    @AuraEnabled
    public static List<QuoteLineItem> getQuoteItems (Id objId)
    {
        List<QuoteLineItem> items = [SELECT Id, QuoteId, Material_Number__c FROM QuoteLineItem WHERE QuoteId =:objId];
        system.debug(items);
        return items;
    }
    
    @AuraEnabled
    public static Boolean PushQuoteToSAP(Id quoteId)
    {
        List<Quote> quote = [SELECT Id, Name, Integration_Status__c,ExpirationDate, Expected_Delivery_Date__c,CurrencyIsoCode,Opportunity.Opportunity_ID__c,Opportunity.Date_Received__c,
                             Division__c, Distribution_Channel__c, Sales_Group__c, Sales_Office__c, Sales_Organization__c,Quote_ID__c,ERP_ID__c,
                             Application__c, Integrated_Solution__c, Other_Strategic_Initiatives__c, Important__c, Managed_by_Project_Teams__c,Payment_Term__c,Incoterm_1__c,Incoterm_2__c,
                             Account.ERP_Id__c,Shipping_Address__r.ERP_ID__c,
                             (SELECT Id, Material_Number__r.Name, Material_Number__r.Quantity_Unit_Of_Measure__c, Product2.Third_Level_Product_Hierarchy__c,UnitPrice, Quantity, Description,Rejected_Reason__c FROM QuoteLineItems)
                             FROM Quote
                             WHERE id =:quoteId];
        
        Boolean quoteToSAPSuccess = PushToSAP.CreateQuote(quote, 'Creation');
        return quoteToSAPSuccess;
    }
}