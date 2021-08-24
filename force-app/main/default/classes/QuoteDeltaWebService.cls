global class QuoteDeltaWebService
{    
    global class QuoteItems
    {
        webservice String materialNumber;
        webservice String thirdLevelHierarchy;
        webservice Integer quantity;
        webservice Double unitPrice;
        webservice Boolean rejected;
        webservice String rejectedReason;
    }
    
    global class Results
    {
        webservice String opportunityId;
        webservice String quoteId;
        webservice String errorMessage;
    }

    global class AdditionalInfo
    {        
        webservice String application;
        webservice String integratedSolution;
        webservice String otherStrategicInitiatives;
        webservice Boolean important;
        webservice Boolean managedByProjectTeams;
        webservice String incoterm1;
        webservice String incoterm2;
        webservice String paymentTerm;
        webservice Decimal quoteMargin;
    }      
    
    public static QuoteDeltaWebService.Results result =  new QuoteDeltaWebService.Results();
    
    webservice static QuoteDeltaWebService.Results QuoteDelta(
        String accountERPID, String userERPID, String shipToERPID, String oppRefId, String oppStageName, String oppInquiryStatus, String saleOrgCode,String salesOffice,String salesGroup, Date oppCloseDate, 
        String oopCurrency, String oppDistributionChannel, String Division, Date expectedDeliveryDate, Date inquiryReceivedDate, Date quotedDate,
        String quoteERPID, String quoteStatus, String quoteLegacySource, String quoteBillingStreet, String quoteBillingCity, String quoteBillingState,
        String quoteBillingPostalCode,String quoteBillingCountry,String quoteCreatedByERPID, 
        AdditionalInfo additionalInfo,
        List<QuoteItems> QuoteItem)
    {
        Id oppId, quoteId, quoteItemId, pricebookId;
        Id oppSGTRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
        Integer quoteItemSuccess = 0;
        String SyncedQuoteERPId;
        HCI_SAP__c csOrgDefault = HCI_SAP__c.getOrgDefaults();
        List<QuoteLineItem> qLineList = new List<QuoteLineItem>();
        List<PricebookEntry> pbEntryList;
        //List<Material_Number__c> materialList;
        Set<Id> successQLineItemsId = new Set<Id>();
        Pricebook2 pb;
        Opportunity opp = new Opportunity();
        Quote q = new Quote();
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        Map<String,Id> pbEntryCurMap = new Map<String,Id>();
        List<String> thirdLevelList = new List<String>();
        List<String> thirdLevelListCur = new List<String>();
        List<String> materialList = new List<String>();
        //List<String> thirdLevelListCur = new List<String>();
        List<QuoteLineItem> qLineCurList = new List<QuoteLineItem>();
        Map<String, List<Quote>> quotesMap = new Map<String, List<Quote>>();
        Map<String, List<QuoteLineItem>> quoteItemsMap = new Map<String, List<QuoteLineItem>>();
        Boolean allRelatedDeleted = false;
        String quoteCreator;
        
        if(!Test.isRunningTest())
        {
            pb = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard= True LIMIT 1];
            pricebookId = pb.id;
        }
        else
            pricebookId = Test.getStandardPricebookId();
        
        List<User> user = [SELECT Id, Name, Division FROM User Where ERP_ID__c =: userERPID LIMIT 1];
        List<Address__c> shipTo = [SELECT Id, Name, Account__r.ERP_Id__c, Street__c, City__c, State__c,
                                   PostalCode__c, Country__c, ERP_ID__c,State_Code__c, Country_Code__c
                                   FROM Address__c WHERE ERP_Id__c =: shipToERPID LIMIT 1];
        List<Quote> tmpQuote = [SELECT Id, Name, OpportunityId, Opportunity.Integration_Status__c, Opportunity.CurrencyIsoCode, Opportunity.Owner.Division,Quote_Creator__c,
                                (SELECT Id FROM Orders) FROM Quote WHERE ERP_Id__c =: quoteERPID AND Opportunity.Opportunity_ID__c =: oppRefId LIMIT 1];
        List<Sales_Organization_User__c> saleOrgUsers = [SELECT Id, User__r.ERP_ID__c, Code__c, Name FROM Sales_Organization_User__c 
                                                         WHERE User__r.ERP_ID__c =: userERPID AND Code__c =: saleOrgCode LIMIT 1];
        
        if(!tmpQuote.isEmpty() && tmpQuote[0].Quote_Creator__c == null){
            List<User> qCreatedBy_SF = [SELECT Id, Name FROM User Where ERP_ID__c =: quoteCreatedByERPID LIMIT 1];
            if(!qCreatedBy_SF.isEmpty())
                quoteCreator = qCreatedBy_SF[0].Name;
            else 
            {
                List<Weir_Employee__c> weirEmployees = [SELECT Id, Name FROM Weir_Employee__c Where ERP_ID__c =: quoteCreatedByERPID LIMIT 1];
                if(!weirEmployees.isEmpty()) quoteCreator = weirEmployees[0].Name;
                else quoteCreator = quoteCreatedByERPID;
            }
        }
        
        System.debug('quoteCreatedByERPID Delta : '+ quoteCreatedByERPID);
        System.debug('quoteCreator Delta : '+ quoteCreator);
        
        if(!shipTo.isEmpty() && !tmpQuote.isEmpty())
        {
            Savepoint sp = Database.setSavepoint();
            //-----------Check Quote Currency Changed?-----------------//
            if (!QuoteItem.isEmpty())
            {  
                for(QuoteDeltaWebService.QuoteItems item : QuoteItem)
                {
                    if(item.thirdLevelHierarchy != null && item.thirdLevelHierarchy != '')
                        thirdLevelList.add(item.thirdLevelHierarchy);
                    else if(item.materialNumber != null && item.materialNumber != '')
                        materialList.add(item.materialNumber); 
                }
                System.debug('Size : '+thirdLevelList.size()+' thirdLevelList: ' + thirdLevelList);
                System.debug('Size : '+materialList.size()+' materialList: ' + materialList);
                
                if(!materialList.isEmpty())
                    thirdLevelList =  QuoteDeltaWebService.updateProductHierarchy(materialList,thirdLevelList,QuoteItem);
            }
            
            if(oopCurrency != tmpQuote[0].Opportunity.CurrencyIsoCode)
            {
                System.debug('Current Curency : ' + tmpQuote[0].Opportunity.CurrencyIsoCode);
                System.debug('New Curency : ' + oopCurrency);
                
                
                Id quoteRefId;
                List<String> QuoteFields = new List<String>(Quote.SObjectType.getDescribe().fields.getMap().keySet());
                List<String> QuoteItemFields = new List<String>(QuoteLineItem.SObjectType.getDescribe().fields.getMap().keySet());
                QuoteItemFields.add('QuoteLineItem.Product2.Third_Level_Product_Hierarchy__c');
                
                String Quotesoql = 'SELECT '+string.join(QuoteFields, ',')+',(SELECT '+string.join(QuoteItemFields, ',')+' FROM QuoteLineItems)'+' FROM Quote WHERE Opportunity.Opportunity_ID__c = \''+oppRefId+'\'';
                List<Quote> allRelatedQuotes = Database.query(Quotesoql);
                List<Quote> backupQuotes = allRelatedQuotes.clone(); //addall();
                List<OpportunityLineItem> oppLineItems = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE Opportunity.Opportunity_ID__c =: oppRefId];

                for(Quote mapQ : allRelatedQuotes)
                {
                    if(mapQ.IsSyncing == true) SyncedQuoteERPId = mapQ.ERP_Id__c;
                    System.debug('Q ERP ID: ' + mapQ.ERP_Id__c);
                    quotesMap.put(mapQ.ERP_Id__c, new List<Quote>{mapQ});          
                    
                    for(QuoteLineItem mapQItem : mapQ.QuoteLineItems)
                    {
                        //System.debug(' mapQItem: ' + mapQItem);
                        if(!quoteItemsMap.containsKey(mapQ.ERP_Id__c)){
                            quoteItemsMap.put(mapQ.ERP_Id__c, new List<QuoteLineItem>{mapQItem});
                        }else{
                            quoteItemsMap.get(mapQ.ERP_Id__c).add(mapQItem);
                        }    
                        
                        thirdLevelListCur.add(mapQItem.Product2.Third_Level_Product_Hierarchy__c);
                    }
                }
                
                System.debug(quotesMap.size()+' quotesMap: ' + quotesMap);
                System.debug(quoteItemsMap.size()+' quoteItemsMap: ' + quoteItemsMap);
                System.debug('thirdLevelListCur: ' + thirdLevelListCur);
                
                if(allRelatedQuotes.size() > 0) delete allRelatedQuotes;
                if(oppLineItems.size() > 0) delete oppLineItems;
                allRelatedDeleted = true;
                
                System.debug('allRelatedQuotes: ' + allRelatedQuotes);
                System.debug('oppLineItems: ' + oppLineItems);
                
                if(allRelatedDeleted == true){
                    Opportunity oppCur = new Opportunity();
                    oppCur.Id = tmpQuote[0].OpportunityId;
                    oppCur.Account = new Account(ERP_Id__c = accountERPID);
                    oppCur.Sales_Org_Code__c = saleOrgCode;
                    oppCur.Sales_Office__c = salesOffice;
                    oppCur.Sales_Group__c = salesGroup;
                    oppCur.Integration_Status__c = oppInquiryStatus;
                    oppCur.Shipping_Address__c = shipTo[0].Id;
                    oppCur.Updated_from_SAP__c = true;
                    if(oppCloseDate == date.valueOf('0002-11-30'))
                        oppCur.CloseDate = date.valueOf('1900-01-01');
                    else if(oppCloseDate != date.valueOf('1990-01-01'))
                        oppCur.CloseDate = oppCloseDate;
                    oppCur.Expected_Delivery_Date__c = expectedDeliveryDate;
                    if(tmpQuote[0].opportunity.Owner.Division == 'ENAR' && tmpQuote[0].opportunity.Integration_Status__c == 'Not Applicable')
                    {
                        if(inquiryReceivedDate == date.valueOf('0002-11-30'))
                            oppCur.Date_Received__c = date.valueOf('1900-01-01');
                        else 
                            oppCur.Date_Received__c = inquiryReceivedDate;
                    }
                    oppCur.CurrencyIsoCode = oopCurrency;
                    oppCur.Division__c = Division;
                    oppCur.Channel__c = oppDistributionChannel;
                    oppCur.Pricebook2Id = pricebookId;
                    oppCur.RecordTypeId = oppSGTRecordTypeId;                    
                    if(quoteStatus != 'Active' && quoteStatus != 'Won') 
                    {
                        oppCur.SyncedQuoteId  = null;
                    }
                    else
                    {                     
                        oppCur.Application__c = additionalInfo.application;
                        oppCur.Integrated_Solution__c = additionalInfo.integratedSolution;
                        oppCur.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                        oppCur.Important__c = additionalInfo.important;
                        oppCur.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                          
                    }
                    Database.SaveResult oppCurResult = Database.update(oppCur, false);
                    if (oppCurResult.isSuccess())
                    {   
                        oppId = oppCurResult.getId();
                        //Do after Insert Opportunity Successfully
                        //Update all related Quotes Currency
                        List<Quote> quotesToInsert = new List<Quote>();
                        for(Quote newQ : backupQuotes)
                        {
                            newQ.CurrencyIsoCode = oopCurrency;
                            newQ.id =null;
                            if(newQ.ERP_Id__c == quoteERPID)
                            {
                                newQ.Name = csOrgDefault.Quote_Name_Prefix__c+' '+quoteERPID;
                                newQ.Pricebook2Id = pricebookId;
                                newQ.status = quoteStatus;
                                newQ.Legacy_Source__c = quoteLegacySource;
                                if(oppCloseDate == date.valueOf('0002-11-30'))
                                    newQ.ExpirationDate = date.valueOf('1900-01-01');
                                else if(oppCloseDate != date.valueOf('1990-01-01'))
                                    newQ.ExpirationDate = oppCloseDate;
                                newQ.Expected_Delivery_Date__c = expectedDeliveryDate;
                                newQ.billingStreet = quoteBillingStreet;
                                newQ.billingCity = quoteBillingCity;
                                newQ.billingStateCode = quoteBillingState;
                                newQ.billingPostalCode = quoteBillingPostalCode;
                                newQ.billingCountryCode = quoteBillingCountry;
                                newQ.Shipping_Address__c = shipTo[0].Id;
                                newQ.shippingStreet = shipTo[0].Street__c;
                                newQ.shippingCity = shipTo[0].City__c;
                                newQ.shippingStateCode = shipTo[0].State_Code__c;
                                newQ.shippingPostalCode = shipTo[0].PostalCode__c;
                                newQ.shippingCountryCode = shipTo[0].Country_Code__c;
                                newQ.Application__c = additionalInfo.application;
                                newQ.Integrated_Solution__c = additionalInfo.integratedSolution;
                                newQ.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                                newQ.Important__c = additionalInfo.important;
                                newQ.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                              
                                if(quoteCreator != null) newQ.Quote_Creator__c = quoteCreator;
                                newQ.Incoterm_1__c = additionalInfo.incoterm1;
                                newQ.Incoterm_2__c = additionalInfo.incoterm2;
                                newQ.Payment_Term__c = additionalInfo.paymentTerm;
                                newQ.Quoted_Margin__c = additionalInfo.quoteMargin;
                                newQ.Trigger_from_SAP__c = true;
                                 
                            }
                            quotesToInsert.add(newQ);
                        }
                        
                        //Insert all Quote with new Currency                   
                        if(!quotesToInsert.isEmpty())
                        {   
                            pbEntryMap = getPricebookEntry(oopCurrency, thirdLevelList, pricebookId);
                            //Get New PricebookEntry with new Currency
                            pbEntryCurMap = getPricebookEntry(oopCurrency, thirdLevelListCur, pricebookId);
                            System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
                            System.debug('pbEntryCurMap Size : '+pbEntryCurMap.size()+' pbEntryCurMap: ' + pbEntryCurMap);
                            
                            List<Id> qInsertSuccessID = new List<Id>();
                            Database.SaveResult [] quoteCurResult = Database.insert(quotesToInsert, false);
                            for (Database.SaveResult sr : quoteCurResult) {
                                if (sr.isSuccess())
                                {
                                    //Do after Insert Quote Successfully
                                    qInsertSuccessID.add(sr.getId());
                                }
                                else
                                {
                                    for(Database.Error err : sr.getErrors()){                 
                                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                        System.debug('Quote fields that affected this error: ' + err.getFields());
                                        result.errorMessage = 'Insert Quote Currency Fail '+err.getStatusCode() + ': ' + err.getMessage();
                                    }
                                    Database.rollback(sp);
                                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                }
                            }
                            
                            Id bkSyncedQuoteId;
                            for(Quote successCurQuote : [Select Id, ERP_ID__c from Quote where ID IN: qInsertSuccessID])
                            {
                                for(String ERPID : quoteItemsMap.keyset())
                                {                     
                                    if(successCurQuote.ERP_ID__c == ERPID)
                                    {
                                        if(successCurQuote.ERP_ID__c == SyncedQuoteERPId) bkSyncedQuoteId = successCurQuote.Id;
                                        // Matched ERPID,, Update with new Quote Items data
                                        if(successCurQuote.ERP_ID__c == quoteERPID && !QuoteItem.isEmpty()) 
                                        {
                                            System.debug('------This a triggered Quote -----: ' + successCurQuote.ERP_ID__c);
                                            quoteRefId = successCurQuote.Id;
                                            Integer itemNo = 0;
                                            for(QuoteDeltaWebService.QuoteItems item : QuoteItem)
                                            {   
                                                system.debug('item.MaterialNumber: '+item.MaterialNumber);
                                                Material_Number__c matRef = new Material_Number__c(ERP_Id__c = item.MaterialNumber);
                                                if (!pbEntryMap.isEmpty() && (matRef != null))
                                                {
                                                    //system.debug('QuoteItem '+itemNo+': '+QuoteItem[itemNo]);
                                                    QuoteLineItem qt = new QuoteLineItem();
                                                    if(pbEntryMap.containsKey(item.thirdLevelHierarchy)) qt.PricebookEntryId = pbEntryMap.get(item.thirdLevelHierarchy);
                                                    qt.quoteId = successCurQuote.id;
                                                    qt.Material_Number__r = matRef;
                                                    qt.quantity = item.Quantity;
                                                    qt.UnitPrice = item.UnitPrice;
                                                    qt.Rejected__c = item.rejected;
                                                    qt.Rejected_Reason__c = item.rejectedReason;
                                                    qLineCurList.add(qt);
                                                    itemNo = itemNo+1;
                                                    system.debug('qItem: '+itemNo+' '+item);
                                                }
                                                else
                                                {
                                                    result.errorMessage = 'PricebookEntry for item '+itemNo+' cannot be found! : '+item.thirdLevelHierarchy+' '+oopCurrency;
                                                    system.debug(result.errorMessage);
                                                    Database.rollback(sp);
                                                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                                    break;
                                                }  
                                            }   
                                        }
                                        else // Update with existing Quote Items data
                                        {
                                            System.debug('------ERPID-----: ' + ERPID+ ' '+quoteItemsMap.get(ERPID).size());
                                            for(QuoteLineItem updateQItem : quoteItemsMap.get(ERPID))
                                            {
                                                if(pbEntryMap.containsKey(updateQItem.Product2.Third_Level_Product_Hierarchy__c))
                                                {
                                                    QuoteLineItem qt = new QuoteLineItem(); 
                                                    if(pbEntryMap.containsKey(updateQItem.Product2.Third_Level_Product_Hierarchy__c))
                                                        qt.PricebookEntryId = pbEntryMap.get(updateQItem.Product2.Third_Level_Product_Hierarchy__c);
                                                    qt.Material_Number__c = updateQItem.Material_Number__c;
                                                    qt.quantity = updateQItem.Quantity;
                                                    qt.UnitPrice = updateQItem.UnitPrice;
                                                    qt.QuoteId  = successCurQuote.id;
                                                    qt.Rejected__c = updateQItem.Rejected__c;
                                                    qt.Rejected_Reason__c = updateQItem.Rejected_Reason__c;
                                                    
                                                    qLineCurList.add(qt);
                                                }
                                            }
                                        }
                                        System.debug('qLineCurList Size : '+qLineCurList.size()+' : ' + qLineCurList);
                                    }
                                }
                            }
                            
                            //-------------Insert quoteItem------------------
                            Database.SaveResult[] quoteItemResultList = Database.insert(qLineCurList, false);
                            for (Database.SaveResult sr : quoteItemResultList)
                            {
                                if (sr.isSuccess())
                                {
                                    quoteItemSuccess = quoteItemSuccess+1;
                                    successQLineItemsId.add(sr.getId());
                                    System.debug('QuoteItems created successfully: ' + sr.getId());
                                }
                                else
                                {              
                                    for(Database.Error err : sr.getErrors())
                                    {                 
                                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                        System.debug('QuoteItems fields that affected this error: ' + err.getFields());
                                        result.errorMessage = 'Create QuoteItems '+err.getStatusCode() + ': ' + err.getMessage();   
                                    }
                                    Database.rollback(sp);
                                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                }
                            }
                            System.debug('successQLineItems Set Id: ' + successQLineItemsId);
                            
                            if ((quoteItemSuccess == qLineCurList.size()))
                            {
                                System.debug('bkSyncedQuoteId : '+bkSyncedQuoteId);
                                if (bkSyncedQuoteId != null)
                                {
                                    Opportunity o = new Opportunity(Id = oppId, SyncedQuoteId  = bkSyncedQuoteId);
                                    Database.SaveResult oppUpdateResult = Database.update(o, false);
                                    if (oppUpdateResult.isSuccess())
                                    {
                                        if(!successQLineItemsId.isEmpty()) syncedMaterialNumber(successQLineItemsId);
                                        System.debug('Synced Quote successfully!!');
                                    }
                                    else // Synced Quote Fail
                                    {              
                                        for(Database.Error err : oppUpdateResult.getErrors())
                                        {                 
                                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                            System.debug('Synced Quote Fail: ' + err.getFields());
                                            result.errorMessage = 'Synced Quote Fail '+err.getStatusCode() + ': ' + err.getMessage();
                                        }
                                        Database.rollback(sp);
                                        createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                    }
                                }
                                Boolean successUpdatedOrder = true;
                                if(!tmpQuote[0].Orders.isEmpty() && tmpQuote[0].Orders.size() > 0)
                                {
                                    System.debug('tmpQuote[0].Orders : ' + tmpQuote[0].Orders.size()); 
                                    successUpdatedOrder = updateOrderwithNewQuote(tmpQuote[0].Orders, quoteRefId);
                                }
                                
                                if(successUpdatedOrder == true) getOpportunitAutoId(oppId,quoteRefId);
                            }
                            else
                            {
                                result.errorMessage = 'Some QuoteItems Insert Fail';
                                System.debug(result.errorMessage);
                                Database.rollback(sp);
                                createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                            }
                            //-------------Insert quoteItem------------------
                            
                        }
                    }
                    else
                    {
                        for(Database.Error err : oppCurResult.getErrors())
                        {                 
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Opportunity fields that affected this error: ' + err.getFields());
                            result.errorMessage = 'Updated Opportunity Currency Fail '+err.getStatusCode() + ': ' + err.getMessage();
                        }
                        Database.rollback(sp);
                        createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                    }
                    
                }
                else
                    System.debug('allRelatedDeleted = false');
                
            }
            //-----------Check Quote Currency Changed?-----------------//
            else
            {
                System.debug('Refer to Existing opportunity!! : ' + tmpQuote[0].OpportunityId);
                //-----------Update Opportunity-----------------//
                opp.Id = tmpQuote[0].OpportunityId;
                opp.Account = new Account(ERP_Id__c = accountERPID);
                opp.Sales_Org_Code__c = saleOrgCode;
                opp.Sales_Office__c = salesOffice;
                opp.Sales_Group__c = salesGroup;
                opp.Integration_Status__c = oppInquiryStatus;
                opp.Shipping_Address__c = shipTo[0].Id;
                opp.Updated_from_SAP__c = true;
                if(oppCloseDate == date.valueOf('0002-11-30'))
                    opp.CloseDate = date.valueOf('1900-01-01');
                else if(oppCloseDate != date.valueOf('1990-01-01'))
                    opp.CloseDate = oppCloseDate;
                opp.Expected_Delivery_Date__c = expectedDeliveryDate;
                if(tmpQuote[0].opportunity.Owner.Division == 'ENAR' && tmpQuote[0].opportunity.Integration_Status__c == 'Not Applicable')
                {
                    if(inquiryReceivedDate == date.valueOf('0002-11-30'))
                        opp.Date_Received__c = date.valueOf('1900-01-01');
                    else 
                        opp.Date_Received__c = inquiryReceivedDate;
                }
                opp.CurrencyIsoCode = oopCurrency;
                opp.Division__c = Division;
                opp.Channel__c = oppDistributionChannel;
                opp.Pricebook2Id = pricebookId;
                opp.RecordTypeId = oppSGTRecordTypeId;
                if(quoteStatus != 'Active' && quoteStatus != 'Won') 
                {
                    opp.SyncedQuoteId  = null;
                }
                else
                {
                    opp.Application__c = additionalInfo.application;
                    opp.Integrated_Solution__c = additionalInfo.integratedSolution;
                    opp.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                    opp.Important__c = additionalInfo.important;
                    opp.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                                      
                }
                Database.SaveResult oppResult = Database.update(opp, false);
                if (oppResult.isSuccess())
                {
                    oppId = oppResult.getId();
                    System.debug('Opportunity updated successfully: ' + oppResult.getId());
                    //-----------Update Quote------------------//
                    q.id = tmpQuote[0].id;
                    q.Name = csOrgDefault.Quote_Name_Prefix__c+' '+quoteERPID;
                    q.Pricebook2Id = pricebookId;
                    q.OpportunityId = oppId;
                    q.status = quoteStatus;
                    q.ERP_Id__c = quoteERPID;
                    //q.Sales_Organization_User__c = saleOrgUsers[0].id;
                    q.Legacy_Source__c = quoteLegacySource;
                    if(oppCloseDate == date.valueOf('0002-11-30'))
                        q.ExpirationDate = date.valueOf('1900-01-01');
                    else if(oppCloseDate != date.valueOf('1990-01-01'))
                        q.ExpirationDate = oppCloseDate;
                    q.Expected_Delivery_Date__c = expectedDeliveryDate;
                    q.billingStreet = quoteBillingStreet;
                    q.billingCity = quoteBillingCity;
                    q.billingStateCode = quoteBillingState;
                    q.billingPostalCode = quoteBillingPostalCode;
                    q.billingCountryCode = quoteBillingCountry;
                    q.Shipping_Address__c = shipTo[0].Id;
                    q.shippingStreet = shipTo[0].Street__c;
                    q.shippingCity = shipTo[0].City__c;
                    q.shippingStateCode = shipTo[0].State_Code__c;
                    q.shippingPostalCode = shipTo[0].PostalCode__c;
                    q.shippingCountryCode = shipTo[0].Country_Code__c;
                    q.Application__c = additionalInfo.application;
                    q.Integrated_Solution__c = additionalInfo.integratedSolution;
                    q.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                    q.Important__c = additionalInfo.important;
                    q.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                        
                    if(quoteCreator != null) q.Quote_Creator__c = quoteCreator;
                    q.Incoterm_1__c = additionalInfo.incoterm1;
                    q.Incoterm_2__c = additionalInfo.incoterm2;
                    q.Payment_Term__c = additionalInfo.paymentTerm;
                    q.Quoted_Margin__c = additionalInfo.quoteMargin;
                    q.Trigger_from_SAP__c = true;
                    system.debug('Quote to be updated '+q);
                    Database.SaveResult quoteResult = Database.update(q, false);
                    if (quoteResult.isSuccess())
                    {
                        quoteId = quoteResult.getId();
                        System.debug('Quote updated successfully: ' + quoteResult.getId());
                        
                        List<QuoteLineItem> delQuoteItems = [SELECT Id, Quote.ERP_ID__c FROM QuoteLineItem where Quote.ERP_ID__c=: quoteERPID];
                        if(!delQuoteItems.isEmpty()) 
                        {
                            delete delQuoteItems;
                            System.debug(delQuoteItems+' has been Deleted!');
                        }
                        
                        if (!QuoteItem.isEmpty())
                        {  
                            Integer itemNo = 0;
                            pbEntryMap = getPricebookEntry(oopCurrency, thirdLevelList, pricebookId);
                            System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
                            
                            for(QuoteDeltaWebService.QuoteItems item : QuoteItem)
                            {   
                                Material_Number__c matRef = new Material_Number__c(ERP_Id__c = item.MaterialNumber);
                                String pbId;
                                if(!pbEntryMap.isEmpty()) pbId = pbEntryMap.get(item.thirdLevelHierarchy);
                                if (pbId != null && (matRef != null))
                                {
                                    system.debug('QuoteItem '+itemNo+': '+QuoteItem[itemNo]);
                                    QuoteLineItem qItem = new QuoteLineItem();
                                    //if(pbEntryMap.containsKey(item.thirdLevelHierarchy)) qItem.PricebookEntryId = pbEntryMap.get(item.thirdLevelHierarchy);
                                    qItem.PricebookEntryId = pbId;
                                    qItem.quoteId = quoteId;
                                    qItem.Material_Number__r = matRef;
                                    qItem.quantity = item.Quantity;
                                    qItem.UnitPrice = item.UnitPrice;
                                    qItem.Rejected__c = item.rejected;
                                	qItem.Rejected_Reason__c = item.rejectedReason;
                                    qLineList.add(qItem);
                                    itemNo = itemNo+1;
                                    system.debug('qItem: '+itemNo+' '+item);
                                }
                                else if(pbId == null) 
                                {
                                    result.errorMessage = 'PricebookEntry for item '+itemNo+' cannot be found : '+item.thirdLevelHierarchy+' '+oopCurrency;
                                    system.debug(result.errorMessage);
                                    Database.rollback(sp);
                                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                    break;
                                }
                                else if(matRef == null)
                                {
                                    result.errorMessage = 'Material for item '+itemNo+' cannot be found : '+item.MaterialNumber;
                                    Database.rollback(sp);
                                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                    break;
                                }
                            }
                            
                            if(!qLineList.isEmpty() && (qLineList.size() == QuoteItem.size()))
                            {
                                Database.SaveResult[] quoteItemResultList = Database.insert(qLineList, false);
                                for (Database.SaveResult sr : quoteItemResultList)
                                {
                                    if (sr.isSuccess())
                                    {
                                        quoteItemSuccess = quoteItemSuccess+1;
                                        successQLineItemsId.add(sr.getId());
                                        System.debug('QuoteItems created successfully: ' + sr.getId());
                                    }
                                    else
                                    {              
                                        for(Database.Error err : sr.getErrors())
                                        {                 
                                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                            System.debug('QuoteItems fields that affected this error: ' + err.getFields());
                                            result.errorMessage = 'Create QuoteItems '+err.getStatusCode() + ': ' + err.getMessage();   
                                        }
                                        Database.rollback(sp);
                                        createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                    }
                                }
                                System.debug('successQLineItems Set Id: ' + successQLineItemsId);
                                
                                if ((quoteItemSuccess == QuoteItem.size()))
                                {
                                    if (quoteStatus == 'Active' || quoteStatus == 'Won')
                                    {
                                        opp.SyncedQuoteId  = quoteId;
                                        System.debug('quoteStatus : '+quoteStatus+' Quote will be synced to Opportunity!!');
                                        Database.SaveResult oppUpdateResult = Database.update(opp, false);
                                        if (oppUpdateResult.isSuccess())
                                        {
                                            oppId = oppUpdateResult.getId();
                                            if(!successQLineItemsId.isEmpty()) syncedMaterialNumber(successQLineItemsId);
                                            System.debug('Synced Quote successfully!!');
                                        }
                                        else // Synced Quote Fail
                                        {              
                                            for(Database.Error err : oppUpdateResult.getErrors())
                                            {                 
                                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                                System.debug('Synced Quote Fail: ' + err.getFields());
                                                result.errorMessage = 'Synced Quote Fail '+err.getStatusCode() + ': ' + err.getMessage();
                                            }
                                            Database.rollback(sp);
                                            createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                        }
                                    }
                                    getOpportunitAutoId(oppId,QuoteId);
                                }
                                /*else
                                {
                                    result.errorMessage = 'Some QuoteItems Insert Fail';
                                    System.debug(result.errorMessage);
                                    Database.rollback(sp);
                                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                }*/
                            }
                        }
                        else getOpportunitAutoId(oppId,QuoteId);
                    }
                    else // Update Quote Fail
                    {              
                        for(Database.Error err : quoteResult.getErrors())
                        {                 
                            System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            System.debug('Quote fields that affected this error: ' + err.getFields());
                            result.errorMessage = 'Update Quote: '+err.getStatusCode() + ': ' + err.getMessage();
                        }
                        Database.rollback(sp);
                        createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                    }     
                }
                else // Update Opportunity Fail
                {              
                    for(Database.Error err : oppResult.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                        result.errorMessage = 'Update Opportunity: '+err.getStatusCode() + ': ' + err.getMessage();
                    }
                    Database.rollback(sp);
                    createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                }
            }
        }
        else
        {
            //result.errorMessage = 'The Quote or ShipTo is not found';
            
            if (shipTo.isEmpty())
                result.errorMessage = 'Ship To is not found: ' + shipToERPID;
            else if (tmpQuote.isEmpty())
                result.errorMessage = 'Quote is not found: ' + quoteERPID;
            
            System.debug(result.errorMessage);
            createErrorMessage(result.errorMessage, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
        }
        System.debug('ReturnValue '+result);
        return result;  
    }
    
    
    public static List<String> updateProductHierarchy(List<String> materialList, List<String> thirdLevelList, List<QuoteDeltaWebService.QuoteItems> QuoteItem)
    {
        Map<String,String> materialPHMap = new Map<String,String>();
        for(Material_Number__c mat : [SELECT Id, Name, X3rd_Level_Product_Hierarchy__c FROM Material_Number__c WHERE Name IN: materialList])
        {
            materialPHMap.put(mat.Name, mat.X3rd_Level_Product_Hierarchy__c);
            thirdLevelList.add(mat.X3rd_Level_Product_Hierarchy__c);
        }
        System.debug('materialPHMap : '+materialPHMap);
        System.debug('Size : '+thirdLevelList.size()+' thirdLevelList: ' + thirdLevelList);
        
        for(QuoteDeltaWebService.QuoteItems item : QuoteItem)
        {
            if(materialPHMap.containsKey(item.materialNumber))
                item.thirdLevelHierarchy = materialPHMap.get(item.materialNumber);
        }
        return thirdLevelList;
    }
    
    private static void getOpportunitAutoId(String newOppId, String newQuoteId)
    {
        List<Opportunity> opps = [SELECT Id, Name, Opportunity_ID__c FROM Opportunity WHERE Id =: newOppId LIMIT 1];
        List<Quote> quotes = [SELECT Id, Name, Quote_ID__c FROM Quote WHERE Id =: newQuoteId LIMIT 1];
        if(!opps.isEmpty() && !quotes.isEmpty())
        {
            result.opportunityId = String.valueOf(opps[0].Opportunity_ID__c);
            result.quoteId = String.valueOf(quotes[0].Quote_ID__c);
        }
        else
            result.errorMessage = 'Response Value: Cannot Query Opportunity or Quote ID';
    }
    
    private static boolean updateOrderwithNewQuote(List<Order> relatedOrders, String newQuoteId)
    {
        Boolean successUpdatedOrder = false;
        try
        {
            for(Order o : relatedOrders)
            {
                o.QuoteId = newQuoteId;
            }
            update relatedOrders;
            successUpdatedOrder = true;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
            result.errorMessage = 'Fail to update a new Quote to Order: '+e.getMessage() + ': ' + e.getLineNumber();
            createErrorMessage(result.errorMessage, null, null, null, null, null, null);
        }
        
        return successUpdatedOrder;
    }
    
    public static void syncedMaterialNumber(Set<Id> successQLineItemsId)
    {
        Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>();
        List<QuoteLineItem> tmpQuoteLineItems = [SELECT Id, Quote.name, OpportunityLineItemId, Material_Number__c, Rejected__c, Rejected_Reason__c  FROM QuoteLineItem WHERE id IN: successQLineItemsId];
        System.debug('tmpQuoteLineItems '+tmpQuoteLineItems);
        
        if(!tmpQuoteLineItems.isEmpty())
        {
            for(QuoteLineItem q : tmpQuoteLineItems)
            {
                if(q.OpportunityLineItemId != null && q.Material_Number__c != null)
                    oppLineItemsMap.put(q.OpportunityLineItemId, new OpportunityLineItem(id = q.OpportunityLineItemId, 
                                                                                         Material_Number__c = q.Material_Number__c,
                                                                                         Rejected__c = q.Rejected__c,
                                                                                         Rejected_Reason__c = q.Rejected_Reason__c));
            }
        }
        System.debug('Map OppLineID+MaterialNumber '+oppLineItemsMap);
        
        if(!oppLineItemsMap.isEmpty())
        {
            try 
            {
                update oppLineItemsMap.values();
                System.debug('OpportunityLineItem '+oppLineItemsMap+' has been synced!');
            } 
            catch (DmlException e)
            {
                System.debug(e.getMessage() + ': ' + e.getLineNumber());
                result.errorMessage = 'Synced MaterialNumber Fail: '+e.getMessage() + ': ' + e.getLineNumber();
                createErrorMessage(result.errorMessage, null, null, null, null, null, null);
            }
        }
    }
    
    public static Map<String,Id> getPricebookEntry(String oopCurrency, List<String> thirdLevelList, ID pricebookId )
    {
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c
                                      FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: oopCurrency
                                      AND Product2.Third_Level_Product_Hierarchy__c IN: thirdLevelList AND Pricebook2Id =: pricebookId])
        {
            //System.debug('pbEntry: ' + pbEntry);
            pbEntryMap.put(pbEntry.Product2.Third_Level_Product_Hierarchy__c, pbEntry.id);
        }
        return pbEntryMap;
    }
    
    public static void createErrorMessage(String errMessage, String oppID, String quoteERPID, String accountERPID, String ShipToERPID, String userERPID, String SaleOrg)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = 'Delta Quotation';
            mError.Error_Message_Detail__c = errMessage;
            mError.Opportunity_ID__c = oppID;
            mError.Quote_ERP_ID__c = quoteERPID;
            mError.Account_ERP_ID__c = accountERPID;
            mError.ShipTo_ERP_ID__c = shipToERPID;
            mError.User_ERP_ID__c = userERPID;
            mError.Sale_Organization__c = SaleOrg;
            insert mError;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}