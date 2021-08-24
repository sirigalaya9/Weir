public class PushToSAP {

    public static Boolean CreateProspectAccount(List<Opportunity> oppList)
    {
        sapComDocumentSapIdocSoapMsg.IdocAssign HCIResponse = new sapComDocumentSapIdocSoapMsg.IdocAssign();
        sapComDocumentSapIdocSoapMsg.DEBMAS_CFS_DEBMAS06 reqMessage = new sapComDocumentSapIdocSoapMsg.DEBMAS_CFS_DEBMAS06();
        sapComDocumentSapIdocSoapMsg.DEBMAS_CFS_DEBMAS06_Port reqPort = new sapComDocumentSapIdocSoapMsg.DEBMAS_CFS_DEBMAS06_Port();
        sapComDocumentSapIdocSoapMsg.E1KNA1M_005 body = new sapComDocumentSapIdocSoapMsg.E1KNA1M_005();
        Boolean accToSAPSuccess = false;
        if(!oppList.isEmpty())
        {
            try
            {   
                if(oppList[0].Account.Prospect__c == true && oppList[0].Account.ERP_Id__c == null)
                {
                    system.debug('----Create Prospect Account!----');
                    body.NAME1 = oppList[0].Account.Name;
                    body.KTOKD = String.valueOf(oppList[0].Account.Prospect__c);
                    body.LOEVM = oppList[0].Account.Account_Status__c;
                    body.BRSCH = oppList[0].Account.Industry;
                    body.BRAN1 = oppList[0].Account.Industry_Code__c;
                    body.KUKLA = oppList[0].Account.Type;
                    body.TELF1 = oppList[0].Account.Phone;
                    body.STCEG = oppList[0].Account.Website;
                    body.STRAS = oppList[0].Account.BillingStreet;
                    body.ORT01 = oppList[0].Account.BillingCity;
                    body.REGIO = oppList[0].Account.BillingStateCode;
                    body.PSTLZ = oppList[0].Account.BillingPostalCode;
                    body.LAND1 = oppList[0].Account.BillingCountryCode;
                    body.SORTL = oppList[0].Account.Name;
                    body.KATR1 = oppList[0].Account.CurrencyIsoCode;
                    body.TELTX = oppList[0].AccountId;
                    body.TELX1 = oppList[0].Opportunity_ID__c;
                    body.KDKG1 = oppList[0].Sales_Organization_User__r.code__c;
                    body.KDKG2 = oppList[0].Channel__c;
                    body.KDKG3 = oppList[0].Division__c;
                    body.KDKG4 = oppList[0].Sales_Group__c;
                    body.KDKG5 = oppList[0].Sales_Office__c;

                    system.debug('Account NAME1 : '+body.NAME1);
                    system.debug('Account KTOKD : '+body.KTOKD);
                    system.debug('Account LOEVM : '+body.LOEVM);
                    system.debug('Account BRSCH : '+body.BRSCH);
                    system.debug('Account BRAN1 : '+body.BRAN1);
                    system.debug('Account KUKLA : '+body.KUKLA);
                    system.debug('Account TELF1 : '+body.TELF1);
                    system.debug('Account STCEG : '+body.STCEG);
                    system.debug('Account STRAS : '+body.STRAS);
                    system.debug('Account ORT01 : '+body.ORT01);
                    system.debug('Account REGIO : '+body.REGIO);
                    system.debug('Account PSTLZ : '+body.PSTLZ);
                    system.debug('Account LAND1 : '+body.LAND1);
                    system.debug('Account SORTL : '+body.SORTL);
                    system.debug('Account KATR1 : '+body.KATR1);
                    system.debug('Account TELTX : '+body.TELTX);
                    system.debug('Account TELX1 : '+body.TELX1);
                    system.debug('Opportunity KDKG1 : '+body.KDKG1);
                    system.debug('Opportunity KDKG2 : '+body.KDKG2);
                    system.debug('Opportunity KDKG3 : '+body.KDKG3);
                    system.debug('Opportunity KDKG4 : '+body.KDKG4);
                    system.debug('Opportunity KDKG5 : '+body.KDKG5);
                }
                
                reqMessage.E1KNA1M = body;
                HCIResponse = reqPort.DEBMAS_CFS_DEBMAS06(reqMessage);
                
                system.debug('Prospect Response DbId : '+HCIResponse.DbId);
                if(HCIResponse.dbId <> Null)
                {
                    accToSAPSuccess = True;
                    system.debug('CreateProspectAccount Successfully!!!');
                }
            }
            catch(Exception e)
            {
                System.debug('Error CreateProspectAccount ' + e.getMessage() + ' ' + e.getLineNumber());
            } 
        }
        return accToSAPSuccess;
    }
    
    public static Boolean CreateInquiry(List<Opportunity> oppList, List<OpportunityLineItem> oliList)
    {
        sapComDocumentSapIdocSoapMsgOpp.IdocAssign HCIResponse = new sapComDocumentSapIdocSoapMsgOpp.IdocAssign();
        sapComDocumentSapIdocSoapMsgOpp.E1BPSDHD1_003 E1BPSDHD1 = new sapComDocumentSapIdocSoapMsgOpp.E1BPSDHD1_003();
        sapComDocumentSapIdocSoapMsgOpp.E1BPSDITM_000[] E1BPSDITM = new List<sapComDocumentSapIdocSoapMsgOpp.E1BPSDITM_000>();
        sapComDocumentSapIdocSoapMsgOpp.E1BPPARNR_000[] E1BPPARNR = new List<sapComDocumentSapIdocSoapMsgOpp.E1BPPARNR_000>();
        sapComDocumentSapIdocSoapMsgOpp.E1BPSCHDL_001[] E1BPSCHDL = new List<sapComDocumentSapIdocSoapMsgOpp.E1BPSCHDL_001>();
        sapComDocumentSapIdocSoapMsgOpp.E1SALESORDER_CREATEFROMDAT2_000 body = new sapComDocumentSapIdocSoapMsgOpp.E1SALESORDER_CREATEFROMDAT2_000();
        Boolean oppToSAPSuccess = false;
        if(!oppList.isEmpty())
        {
            try
            {               
                E1BPSDHD1.REFOBJKEY = oppList[0].id;
                E1BPSDHD1.SALES_ORG = oppList[0].Sales_Organization_User__r.code__c;
                E1BPSDHD1.SALES_OFF  = oppList[0].Sales_Office__c;
                E1BPSDHD1.SALES_GRP = oppList[0].Sales_Group__c;
                E1BPSDHD1.DISTR_CHAN = oppList[0].Channel__c;
                E1BPSDHD1.DIVISION = oppList[0].Division__c;
                E1BPSDHD1.QT_VALID_T = String.valueOf(oppList[0].CloseDate).replaceall('-','');
                E1BPSDHD1.REQ_DATE_H = String.valueOf(oppList[0].Expected_Delivery_Date__c).replaceall('-','');
                E1BPSDHD1.PURCH_NO_C = oppList[0].id;
                E1BPSDHD1.REF_1_S = oppList[0].Opportunity_ID__c;
                E1BPSDHD1.PP_SEARCH = oppList[0].name;
                E1BPSDHD1.REF_DOC = oppList[0].id;
                E1BPSDHD1.CUST_GRP1 = oppList[0].Application__c;
                E1BPSDHD1.CUST_GRP2 = oppList[0].Integrated_Solution__c;
                E1BPSDHD1.CUST_GRP3 = oppList[0].Other_Strategic_Initiatives__c;
                E1BPSDHD1.CUST_GRP4 = String.valueOf(oppList[0].Important__c);
                E1BPSDHD1.CUST_GRP5 = String.valueOf(oppList[0].Managed_by_Project_Teams__c);
                          
                system.debug('E1BPSDHD1.REFOBJKEY : '+E1BPSDHD1.REFOBJKEY);
                system.debug('E1BPSDHD1.SALES_ORG : '+E1BPSDHD1.SALES_ORG);
                system.debug('E1BPSDHD1.SALES_OFF : '+E1BPSDHD1.SALES_OFF);
                system.debug('E1BPSDHD1.SALES_GRP : '+E1BPSDHD1.SALES_GRP);
                system.debug('E1BPSDHD1.DISTR_CHAN : '+E1BPSDHD1.DISTR_CHAN);
                system.debug('E1BPSDHD1.DIVISION : '+E1BPSDHD1.DIVISION);
                system.debug('E1BPSDHD1.QT_VALID_T : '+E1BPSDHD1.QT_VALID_T);
                system.debug('E1BPSDHD1.REQ_DATE_H : '+E1BPSDHD1.REQ_DATE_H);
                system.debug('E1BPSDHD1.PURCH_NO_C : '+E1BPSDHD1.PURCH_NO_C);
                system.debug('E1BPSDHD1.REF_1_S : '+E1BPSDHD1.REF_1_S);
                system.debug('E1BPSDHD1.PP_SEARCH : '+E1BPSDHD1.PP_SEARCH);
                system.debug('E1BPSDHD1.REF_DOC : '+E1BPSDHD1.REF_DOC);
                system.debug('E1BPSDHD1.CUST_GRP1 : '+E1BPSDHD1.CUST_GRP1);
                system.debug('E1BPSDHD1.CUST_GRP2 : '+E1BPSDHD1.CUST_GRP2);
                system.debug('E1BPSDHD1.CUST_GRP3 : '+E1BPSDHD1.CUST_GRP3);
                system.debug('E1BPSDHD1.CUST_GRP4 : '+E1BPSDHD1.CUST_GRP4);
                system.debug('E1BPSDHD1.CUST_GRP5 : '+E1BPSDHD1.CUST_GRP5);
                
                /////////////////-----Looping for Opportunity Product-------///////////////           
                for(Integer i=0; i<oliList.size(); i++)
                {
                    sapComDocumentSapIdocSoapMsgOpp.E1BPSDITM_000 E1BPSDITM_Temp = new sapComDocumentSapIdocSoapMsgOpp.E1BPSDITM_000();
                    sapComDocumentSapIdocSoapMsgOpp.E1BPSDITM1_004 E1BPSDITM1 = new sapComDocumentSapIdocSoapMsgOpp.E1BPSDITM1_004();
                    E1BPSDITM1.REF_DOC = oppList[0].id;
                    E1BPSDITM1.REF_DOC_IT = String.valueOf(i+1)+'0';
                    
                    E1BPSDITM_Temp.ITM_NUMBER = String.valueOf(i+1)+'0';
                    E1BPSDITM_Temp.MATERIAL = oliList[i].Material_Number__r.Name;
                    E1BPSDITM_Temp.S_UNIT_ISO = oliList[i].Material_Number__r.Quantity_Unit_Of_Measure__c;
                    E1BPSDITM_Temp.TARGET_VAL = String.valueOf(oliList[i].UnitPrice);
                    E1BPSDITM_Temp.TARGET_QTY = String.valueOf(oliList[i].Quantity);
                    E1BPSDITM_Temp.INCOTERMS1 = oliList[i].Description ;
                    E1BPSDITM_Temp.CURRENCY_x = oppList[0].CurrencyIsoCode;
                    E1BPSDITM_Temp.E1BPSDITM1 = E1BPSDITM1;
                    E1BPSDITM.add(E1BPSDITM_Temp);
                    
                    system.debug('E1BPSDITM['+i+'].ITM_NUMBER : '+E1BPSDITM[i].ITM_NUMBER);
                    system.debug('E1BPSDITM['+i+'].MATERIAL : '+E1BPSDITM[i].MATERIAL);
                    system.debug('E1BPSDITM['+i+'].S_UNIT_ISO : '+E1BPSDITM[i].S_UNIT_ISO);
                    system.debug('E1BPSDITM['+i+'].TARGET_VAL : '+E1BPSDITM[i].TARGET_VAL);
                    system.debug('E1BPSDITM['+i+'].INCOTERMS1 : '+E1BPSDITM[i].INCOTERMS1);
                    system.debug('E1BPSDITM['+i+'].CURRENCY_x : '+E1BPSDITM[i].CURRENCY_x);
                    system.debug('E1BPSDITM['+i+'].E1BPSDITM1.REF_DOC : '+E1BPSDITM[i].E1BPSDITM1.REF_DOC);
                    system.debug('E1BPSDITM['+i+'].E1BPSDITM1.REF_DOC_IT : '+E1BPSDITM[i].E1BPSDITM1.REF_DOC_IT);
                    
                    sapComDocumentSapIdocSoapMsgOpp.E1BPSCHDL_001 E1BPSCHDL_Temp = new sapComDocumentSapIdocSoapMsgOpp.E1BPSCHDL_001();
                    E1BPSCHDL_Temp.ITM_NUMBER = String.valueOf(i+1)+'0';
                    E1BPSCHDL_Temp.REQ_DATE = String.valueOf(System.Today()).replaceall('-','');
                    E1BPSCHDL_Temp.REQ_QTY = String.valueOf(oliList[i].Quantity);
                    E1BPSCHDL_Temp.DLV_DATE = String.valueOf(oppList[0].Expected_Delivery_Date__c).replaceall('-','');
                    E1BPSCHDL.add(E1BPSCHDL_Temp); 
                    
                    system.debug('E1BPSCHDL['+i+'].ITM_NUMBER : '+E1BPSCHDL[i].ITM_NUMBER);
                    system.debug('E1BPSCHDL['+i+'].REQ_DATE : '+E1BPSCHDL[i].REQ_DATE);
                    system.debug('E1BPSCHDL['+i+'].REQ_QTY : '+E1BPSCHDL[i].REQ_QTY);
                    system.debug('E1BPSCHDL['+i+'].DLV_DATE : '+E1BPSCHDL[i].DLV_DATE);
                }
                
                /////////////////-----E1BPPARNR will be sent if the Account has ERP ID-------///////////////
                if(oppList[0].Account.ERP_Id__c != null)
                {
                    sapComDocumentSapIdocSoapMsgOpp.E1BPPARNR_000 E1BPPARNR_Temp = new sapComDocumentSapIdocSoapMsgOpp.E1BPPARNR_000();
                    E1BPPARNR_Temp.PARTN_ROLE = 'AG';
                    E1BPPARNR_Temp.PARTN_NUMB = oppList[0].Account.ERP_Id__c;
                    E1BPPARNR.add(E1BPPARNR_Temp);
                    system.debug('E1BPPARNR[0].PARTN_ROLE : '+E1BPPARNR[0].PARTN_ROLE);
                    system.debug('E1BPPARNR[0].PARTN_NUMB : '+E1BPPARNR[0].PARTN_NUMB);
                }
                
                if(oppList[0].Shipping_Address__r.ERP_ID__c != null)
                {
                    sapComDocumentSapIdocSoapMsgOpp.E1BPPARNR_000 E1BPPARNR_Temp = new sapComDocumentSapIdocSoapMsgOpp.E1BPPARNR_000();
                    E1BPPARNR_Temp.PARTN_ROLE = 'WE';
                    E1BPPARNR_Temp.PARTN_NUMB = oppList[0].Shipping_Address__r.ERP_ID__c;
                    E1BPPARNR.add(E1BPPARNR_Temp);
                }
                
                //-------- Main Body----------//
                body.E1BPSDHD1 = E1BPSDHD1;
                body.E1BPSDITM = E1BPSDITM;
                body.E1BPPARNR = E1BPPARNR;
                body.E1BPSCHDL = E1BPSCHDL;
                
                sapComDocumentSapIdocSoapMsgOpp.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202 reqMessage = new sapComDocumentSapIdocSoapMsgOpp.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202();
                reqMessage.E1SALESORDER_CREATEFROMDAT2 = body;
                
                sapComDocumentSapIdocSoapMsgOpp.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202_Port reqPort = new sapComDocumentSapIdocSoapMsgOpp.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202_Port();
                HCIResponse = reqPort.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202(reqMessage);
                system.debug('Inquiry Response DbId : '+HCIResponse.DbId);
                oppToSAPSuccess = True;
                oppList[0].Integration_Status__c = 'In Progress';
                oppList[0].Inprogress__c = true;
                UpdateDatabase(oppList);
                system.debug('CreateInquiry Successfully!!! '+oppList[0].Integration_Status__c);
            }
            catch(Exception e)
            {
                System.debug('Error CreateInquiry ' + e.getMessage() + ' ' + e.getLineNumber());
            } 
        }
        return oppToSAPSuccess;
    }
    
    public static void UpdateDatabase(List<Opportunity> oppList)
    {
        if(!oppList.isEmpty())
        { 
            Database.update(oppList, false);
            System.debug('Inquiry Status: In Progress..');
        }
    }
    
    public static Boolean CreateQuote(List<Quote> quotes, String quoteType)
    {
        sapComDocumentSapIdocQuoteToSAP.IdocAssign HCIResponse = new sapComDocumentSapIdocQuoteToSAP.IdocAssign();
        sapComDocumentSapIdocQuoteToSAP.E1BPSDHD1_003 E1BPSDHD1 = new sapComDocumentSapIdocQuoteToSAP.E1BPSDHD1_003();
        sapComDocumentSapIdocQuoteToSAP.E1BPSDITM_000[] E1BPSDITM = new List<sapComDocumentSapIdocQuoteToSAP.E1BPSDITM_000>();
        sapComDocumentSapIdocQuoteToSAP.E1BPPARNR_000[] E1BPPARNR = new List<sapComDocumentSapIdocQuoteToSAP.E1BPPARNR_000>();
        sapComDocumentSapIdocQuoteToSAP.E1BPSCHDL_001[] E1BPSCHDL = new List<sapComDocumentSapIdocQuoteToSAP.E1BPSCHDL_001>();
        sapComDocumentSapIdocQuoteToSAP.E1BPCOND_001[] E1BPCOND = new List<sapComDocumentSapIdocQuoteToSAP.E1BPCOND_001>();
        sapComDocumentSapIdocQuoteToSAP.E1SALESORDER_CREATEFROMDAT2_000 body = new sapComDocumentSapIdocQuoteToSAP.E1SALESORDER_CREATEFROMDAT2_000();
        Boolean quoteToSAPSuccess = false;
        if(!quotes.isEmpty())
        {
            for(Quote quote : quotes)
            {
                try
                {               
                    E1BPSDHD1.REFOBJKEY = quote.id;
                    E1BPSDHD1.DOC_TYPE = 'ZQT';
                    E1BPSDHD1.COLLECT_NO = quote.Quote_ID__c ;
                    E1BPSDHD1.SALES_ORG = quote.Sales_Organization__c;
                    E1BPSDHD1.SALES_OFF  = quote.Sales_Office__c;
                    E1BPSDHD1.SALES_GRP = quote.Sales_Group__c;
                    E1BPSDHD1.DISTR_CHAN = quote.Distribution_Channel__c;
                    E1BPSDHD1.DIVISION = quote.Division__c;
                    E1BPSDHD1.QT_VALID_T = String.valueOf(quote.ExpirationDate).replaceall('-','');
                    E1BPSDHD1.REQ_DATE_H = String.valueOf(quote.Expected_Delivery_Date__c).replaceall('-','');
                    //E1BPSDHD1.PURCH_DATE = String.valueOf(quote.Opportunity.Date_Received__c ).replaceall('-','');
                    //E1BPSDHD1.PURCH_NO_C = quote.id;
                    E1BPSDHD1.REF_1_S = quote.Opportunity.Opportunity_ID__c;
                    //E1BPSDHD1.PP_SEARCH = quote.name;
                    //E1BPSDHD1.REF_DOC = quote.id;
                    E1BPSDHD1.CUST_GRP1 = quote.Application__c;
                    E1BPSDHD1.CUST_GRP2 = quote.Integrated_Solution__c;
                    E1BPSDHD1.CUST_GRP3 = quote.Other_Strategic_Initiatives__c;
                    E1BPSDHD1.CUST_GRP4 = String.valueOf(quote.Important__c);
                    E1BPSDHD1.CUST_GRP5 = String.valueOf(quote.Managed_by_Project_Teams__c);
                    E1BPSDHD1.DLVSCHDUSE = String.valueOf(quote.Application__c);
                    E1BPSDHD1.PMNTTRMS = quote.Payment_Term__c;
                    E1BPSDHD1.INCOTERMS1  = quote.Incoterm_1__c	;
                    E1BPSDHD1.INCOTERMS2 = quote.Incoterm_2__c	;
                    E1BPSDHD1.CURRENCY_x = String.valueOf(quote.CurrencyIsoCode);
                    
                    
                    system.debug('E1BPSDHD1.REFOBJKEY : '+E1BPSDHD1.REFOBJKEY);
                    system.debug('E1BPSDHD1.SALES_ORG : '+E1BPSDHD1.SALES_ORG);
                    system.debug('E1BPSDHD1.SALES_OFF : '+E1BPSDHD1.SALES_OFF);
                    system.debug('E1BPSDHD1.SALES_GRP : '+E1BPSDHD1.SALES_GRP);
                    system.debug('E1BPSDHD1.DISTR_CHAN : '+E1BPSDHD1.DISTR_CHAN);
                    system.debug('E1BPSDHD1.DIVISION : '+E1BPSDHD1.DIVISION);
                    system.debug('E1BPSDHD1.QT_VALID_T : '+E1BPSDHD1.QT_VALID_T);
                    system.debug('E1BPSDHD1.REQ_DATE_H : '+E1BPSDHD1.REQ_DATE_H);
                    system.debug('E1BPSDHD1.PURCH_NO_C : '+E1BPSDHD1.PURCH_NO_C);
                    system.debug('E1BPSDHD1.REF_1_S : '+E1BPSDHD1.REF_1_S);
                    system.debug('E1BPSDHD1.PP_SEARCH : '+E1BPSDHD1.PP_SEARCH);
                    system.debug('E1BPSDHD1.REF_DOC : '+E1BPSDHD1.REF_DOC);
                    system.debug('E1BPSDHD1.CUST_GRP1 : '+E1BPSDHD1.CUST_GRP1);
                    system.debug('E1BPSDHD1.CUST_GRP2 : '+E1BPSDHD1.CUST_GRP2);
                    system.debug('E1BPSDHD1.CUST_GRP3 : '+E1BPSDHD1.CUST_GRP3);
                    system.debug('E1BPSDHD1.CUST_GRP4 : '+E1BPSDHD1.CUST_GRP4);
                    system.debug('E1BPSDHD1.CUST_GRP5 : '+E1BPSDHD1.CUST_GRP5);
                    
                    /////////////////-----Looping for Quote Product-------///////////////
                    List<QuoteLineItem> qItems = quote.QuoteLineItems;   
                    
                    for(Integer i=0; i<qItems.size(); i++)
                    {
                        sapComDocumentSapIdocQuoteToSAP.E1BPSDITM_000 E1BPSDITM_Temp = new sapComDocumentSapIdocQuoteToSAP.E1BPSDITM_000();
                        sapComDocumentSapIdocQuoteToSAP.E1BPSDITM1_004 E1BPSDITM1 = new sapComDocumentSapIdocQuoteToSAP.E1BPSDITM1_004();
                        //E1BPSDITM1.REF_DOC = quote.id;
                        //E1BPSDITM1.REF_DOC_IT = String.valueOf(i+1)+'0';
                        
                        E1BPSDITM_Temp.ITM_NUMBER = String.valueOf(i+1)+'0';
                        E1BPSDITM_Temp.MATERIAL = qItems[i].Material_Number__r.Name;
                        E1BPSDITM_Temp.PROD_HIERA = String.valueOf(qItems[i].Product2.Third_Level_Product_Hierarchy__c);
                        E1BPSDITM_Temp.S_UNIT_ISO = qItems[i].Material_Number__r.Quantity_Unit_Of_Measure__c;
                        E1BPSDITM_Temp.TARGET_VAL = String.valueOf(qItems[i].UnitPrice);
                        E1BPSDITM_Temp.TARGET_QTY = String.valueOf(qItems[i].Quantity);
                        //E1BPSDITM_Temp.INCOTERMS1 = qItems[i].Description ;
                        E1BPSDITM_Temp.CURRENCY_x = quote.CurrencyIsoCode;
                        E1BPSDITM_Temp.REASON_REJ = qItems[i].Rejected_Reason__c ;
                        E1BPSDITM.add(E1BPSDITM_Temp);
                        
                        system.debug('E1BPSDITM['+i+'].ITM_NUMBER : '+E1BPSDITM[i].ITM_NUMBER);
                        system.debug('E1BPSDITM['+i+'].MATERIAL : '+E1BPSDITM[i].MATERIAL);
                        system.debug('E1BPSDITM['+i+'].S_UNIT_ISO : '+E1BPSDITM[i].S_UNIT_ISO);
                        //system.debug('E1BPSDITM['+i+'].TARGET_VAL : '+E1BPSDITM[i].TARGET_VAL);
                        //system.debug('E1BPSDITM['+i+'].INCOTERMS1 : '+E1BPSDITM[i].INCOTERMS1);
                        //system.debug('E1BPSDITM['+i+'].CURRENCY_x : '+E1BPSDITM[i].CURRENCY_x);
                        //system.debug('E1BPSDITM['+i+'].E1BPSDITM1.REF_DOC : '+E1BPSDITM[i].E1BPSDITM1.REF_DOC);
                        //system.debug('E1BPSDITM['+i+'].E1BPSDITM1.REF_DOC_IT : '+E1BPSDITM[i].E1BPSDITM1.REF_DOC_IT);
                        
                        sapComDocumentSapIdocQuoteToSAP.E1BPSCHDL_001 E1BPSCHDL_Temp = new sapComDocumentSapIdocQuoteToSAP.E1BPSCHDL_001();
                        E1BPSCHDL_Temp.ITM_NUMBER = String.valueOf(i+1)+'0';
                        E1BPSCHDL_Temp.REQ_DATE = String.valueOf(System.Today()).replaceall('-','');
                        E1BPSCHDL_Temp.REQ_QTY = String.valueOf(qItems[i].Quantity);
                        E1BPSCHDL_Temp.DLV_DATE = String.valueOf(quote.Expected_Delivery_Date__c).replaceall('-','');
                        E1BPSCHDL.add(E1BPSCHDL_Temp); 
                        
                        system.debug('E1BPSCHDL['+i+'].ITM_NUMBER : '+E1BPSCHDL[i].ITM_NUMBER);
                        system.debug('E1BPSCHDL['+i+'].REQ_DATE : '+E1BPSCHDL[i].REQ_DATE);
                        system.debug('E1BPSCHDL['+i+'].REQ_QTY : '+E1BPSCHDL[i].REQ_QTY);
                        system.debug('E1BPSCHDL['+i+'].DLV_DATE : '+E1BPSCHDL[i].DLV_DATE);
                        
                        ///////////////----- E1BPCOND -------//////////
                        sapComDocumentSapIdocQuoteToSAP.E1BPCOND_001 E1BPCOND_Temp = new sapComDocumentSapIdocQuoteToSAP.E1BPCOND_001();
                        E1BPCOND_Temp.ITM_NUMBER = String.valueOf(i+1)+'0';
                        E1BPCOND_Temp.COND_TYPE = 'EDI1';
                        E1BPCOND_Temp.COND_VALUE = String.valueOf(qItems[i].UnitPrice);
                        E1BPCOND.add(E1BPCOND_Temp);
                    }
                    
                    /////////////////-----E1BPPARNR will be sent if the Account has ERP ID-------///////////////
                    if(quote.Account.ERP_Id__c != null)
                    {
                        sapComDocumentSapIdocQuoteToSAP.E1BPPARNR_000 E1BPPARNR_Temp = new sapComDocumentSapIdocQuoteToSAP.E1BPPARNR_000();
                        E1BPPARNR_Temp.PARTN_ROLE = 'AG';
                        E1BPPARNR_Temp.PARTN_NUMB = quote.Account.ERP_Id__c;
                        E1BPPARNR.add(E1BPPARNR_Temp);
                        system.debug('E1BPPARNR[0].PARTN_ROLE : '+E1BPPARNR[0].PARTN_ROLE);
                        system.debug('E1BPPARNR[0].PARTN_NUMB : '+E1BPPARNR[0].PARTN_NUMB);
                    }
                    
                    if(quote.Shipping_Address__r.ERP_ID__c != null)
                    {
                        sapComDocumentSapIdocQuoteToSAP.E1BPPARNR_000 E1BPPARNR_Temp = new sapComDocumentSapIdocQuoteToSAP.E1BPPARNR_000();
                        E1BPPARNR_Temp.PARTN_ROLE = 'WE';
                        E1BPPARNR_Temp.PARTN_NUMB = quote.Shipping_Address__r.ERP_ID__c;
                        E1BPPARNR.add(E1BPPARNR_Temp);
                    }
                    
                    
                    //-------- Main Body----------//
                    body.SALESDOCUMENTIN = quote.ERP_Id__c;
                    body.E1BPSDHD1 = E1BPSDHD1;
                    body.E1BPSDITM = E1BPSDITM;
                    body.E1BPPARNR = E1BPPARNR;
                    body.E1BPSCHDL = E1BPSCHDL;
                    body.E1BPCOND = E1BPCOND;
                    
                    sapComDocumentSapIdocQuoteToSAP.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202 reqMessage = new sapComDocumentSapIdocQuoteToSAP.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202();
                    reqMessage.E1SALESORDER_CREATEFROMDAT2 = body;
                    
                    sapComDocumentSapIdocQuoteToSAP.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202_Port reqPort = new sapComDocumentSapIdocQuoteToSAP.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202_Port();
                    HCIResponse = reqPort.SALESORDER_CREATEFROMDAT2_SALESORDER_CREATEFROMDAT202(reqMessage);
                    system.debug('Quote Response DbId : '+HCIResponse.DbId);
                    quoteToSAPSuccess = True;

                    if(quoteType == 'Creation')
                    {
                        Quote updateQuote = new Quote(Id =  quote.Id, Integration_Status__c = 'In Progress', Inprogress__c = true);
                        update updateQuote;
                        system.debug('Create Quote Successfully!!! '+updateQuote.Integration_Status__c);
                    }
                    else if(quoteType == 'Delta')
                    {
                        system.debug('Update Quote Successfully!!!');
                    }
                }
                catch(Exception e)
                {
                    System.debug('Error Synce Quote ' + e.getMessage() + ' ' + e.getLineNumber());
                } 
            }
        }
        return quoteToSAPSuccess;
    }   
    
}