global class QuoteCreationWebService
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
    }       
    
    public static QuoteCreationWebService.Results result =  new QuoteCreationWebService.Results();
    
    webservice static QuoteCreationWebService.Results DirectQuoteCreation(
        String accountERPID, String userERPID, String shipToERPID, String oppRefId, String saleOrgCode, String salesOffice,String salesGroup,Date oppCloseDate, 
        String oopCurrency, String oppDistributionChannel, String Division, Date oppBidDueDate, Date expectedDeliveryDate, Date inquiryReceivedDate, Date quotedDate,
        String quoteERPID, String quoteType, String quoteLegacySource, String quoteStatus, String quoteBillingStreet, String quoteBillingCity, String quoteBillingState,
        String quoteBillingPostalCode,String quoteBillingCountry, String quoteCreatedByERPID, String quoteOwnerERPID, 
        AdditionalInfo additionalInfo,
        List<QuoteItems> QuoteItem)
    {

        Id oppId, quoteId, quoteItemId, pricebookId;
        Id oppSGTRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
        Integer quoteItemSuccess = 0;
        Pricebook2 pb;
        HCI_SAP__c csOrgDefault = HCI_SAP__c.getOrgDefaults();
        List<QuoteLineItem> qLineList = new List<QuoteLineItem>();
        List<PricebookEntry> pbEntryList;
        //List<Material_Number__c> materialList;
        Set<Id> successQLineItemsId = new Set<Id>();
        Opportunity opp = new Opportunity();
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        Map<String,String> materialPHMap = new Map<String,String>();
        List<String> thirdLevelList = new List<String>();
        List<String> materialList = new List<String>();
        List<User> oppOwner_SF = new List<User>();
        List<Sales_Organization_User__c> oppSaleOrgUsers = new List<Sales_Organization_User__c>();
        List<User> qOwner_SF = new List<User>();
        List<Sales_Organization_User__c> quoteSaleOrgUsers = new List<Sales_Organization_User__c>();
        String quoteCreator;
        String defaultUserDivision;
        Id quoteOwnerId;
        Id oppOwnerId;
        Id defaultUser;
        String oppUserSalesOrgName;
        
        if(!Test.isRunningTest())
        {
            pb = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard= True LIMIT 1];
            pricebookId = pb.id;
        }
        else
            pricebookId = Test.getStandardPricebookId();
        
        //List<User> user = [SELECT Id, Name, Division FROM User Where ERP_ID__c =: userERPID LIMIT 1];
        List<Address__c> shipTo = [SELECT Id, Name, Account__r.ERP_Id__c, Street__c, City__c, State__c,
                                   PostalCode__c, Country__c, ERP_ID__c,State_Code__c, Country_Code__c
                                   FROM Address__c WHERE ERP_Id__c =: shipToERPID LIMIT 1];

        //List<Sales_Organization_User__c> saleOrgUsers = [SELECT Id, User__r.ERP_ID__c, Code__c, Name, Sales_Organizationa__r.Default_User__c FROM Sales_Organization_User__c 
                                                         //WHERE User__r.ERP_ID__c =: userERPID AND Code__c =: saleOrgCode LIMIT 1];
        
        if (String.isNotBlank(userERPID))
        {
            oppOwner_SF = [SELECT Id, Name, Division FROM User Where ERP_ID__c =: userERPID LIMIT 1];
            system.debug('userERPID '+userERPID);
            system.debug('oppOwner_SF '+oppOwner_SF);
            
            if(!oppOwner_SF.isEmpty() && oppOwner_SF[0].Name != 'Integration User'){
                oppOwnerId = oppOwner_SF[0].Id;
                oppUserSalesOrgName = oppOwner_SF[0].Name;
                defaultUserDivision = oppOwner_SF[0].Division;
            }
            else if(oppOwner_SF.isEmpty() || (!oppOwner_SF.isEmpty() && oppOwner_SF[0].Name == 'Integration User'))
            {
                system.debug('Integration User or Not found');
                Sales_Organization__c saleOrg = [SELECT Id, Code__c, Default_User__c,Default_User__r.name, Default_User__r.Division FROM Sales_Organization__c Where Code__c =: saleOrgCode LIMIT 1];
                system.debug('Default_User__r.name '+saleOrg.Default_User__r.name);
                oppOwnerId = saleOrg.Default_User__c;
                oppUserSalesOrgName = saleOrg.Default_User__r.Name;
                defaultUserDivision = saleOrg.Default_User__r.Division;
            }
            
            if(oppOwnerId != null)
            {
                oppSaleOrgUsers = [SELECT Id, User__r.ERP_ID__c, Code__c, Name FROM Sales_Organization_User__c WHERE User__c =: oppOwnerId AND Code__c =: saleOrgCode LIMIT 1]; 
                system.debug('oppSaleOrgUsers '+oppSaleOrgUsers);
            }
        }
        
        List<User> qCreatedBy_SF = [SELECT Id, Name FROM User Where ERP_ID__c =: quoteCreatedByERPID LIMIT 1];
        
        if(!qCreatedBy_SF.isEmpty()) quoteCreator = qCreatedBy_SF[0].Name;
        else 
        {
            List<Weir_Employee__c> weirEmployees = [SELECT Id, Name FROM Weir_Employee__c Where ERP_ID__c =: quoteCreatedByERPID LIMIT 1];
            if(!weirEmployees.isEmpty()) quoteCreator = weirEmployees[0].Name;
            else quoteCreator = quoteCreatedByERPID;
        }
        
        
		Boolean quoteOwnerDefault = false;
        if (String.isNotBlank(quoteOwnerERPID))
        {
            qOwner_SF = [SELECT Id, Name FROM User Where ERP_ID__c =: quoteOwnerERPID LIMIT 1];
            
            if(!qOwner_SF.isEmpty() && qOwner_SF[0].Name != 'Integration User'){
                quoteOwnerId = qOwner_SF[0].Id;
            }
            else if(qOwner_SF.isEmpty() || (!qOwner_SF.isEmpty() && qOwner_SF[0].Name == 'Integration User'))
            {
                system.debug('Integration User or Not found');
                Sales_Organization__c saleOrg = [SELECT Id, Code__c, Default_User__c,Default_User__r.name FROM Sales_Organization__c Where Code__c =: saleOrgCode LIMIT 1];
                system.debug('Default_User__r.name '+saleOrg.Default_User__r.name);
                quoteOwnerId = saleOrg.Default_User__c;
                quoteOwnerDefault = true;
            }
            
            if(quoteOwnerId != null)
            {
                quoteSaleOrgUsers = [SELECT Id, User__r.ERP_ID__c, Code__c, Name FROM Sales_Organization_User__c 
                                     WHERE User__c =: quoteOwnerId AND Code__c =: saleOrgCode LIMIT 1];
                system.debug('quoteSaleOrgUsers '+quoteSaleOrgUsers);
            }  
        }
        
        if(!shipTo.isEmpty() && oppOwnerId != null && quoteOwnerId != null && !oppSaleOrgUsers.isEmpty())
        {
            Savepoint sp = Database.setSavepoint();            
            if (quoteType == 'ZQT')
            {  
                //-----------Create Opportunity-----------------//
                opp.Name = 'ECC - '+quoteERPID;
                opp.StageName = 'Negotiation';
                opp.Account = new Account(ERP_Id__c = accountERPID);
                opp.OwnerId = oppOwnerId;
                opp.Sales_Organization_User__c = oppSaleOrgUsers[0].Id;
                //opp.Sales_Organization_User__c = saleOrgUsers[0].id;
                opp.Sales_Org_Code__c = saleOrgCode;
                opp.Sales_Office__c = salesOffice;
                opp.Sales_Group__c = salesGroup;
                opp.Territory_Integration__c = True;
                opp.Integration_Status__c = 'Not Applicable';
                opp.Shipping_Address__c = shipTo[0].Id;
                if(oppCloseDate == date.valueOf('0002-11-30'))
                    opp.CloseDate = date.valueOf('1900-01-01');
                else 
                    opp.CloseDate = oppCloseDate;
                opp.Bid_Due_Date__c = oppBidDueDate;
                opp.Expected_Delivery_Date__c = expectedDeliveryDate;
                if(defaultUserDivision == 'ENAR')
                {
                    opp.Date_Quoted__c = quotedDate;
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
                opp.Application__c = additionalInfo.application;
                opp.Integrated_Solution__c = additionalInfo.integratedSolution;
                opp.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                opp.Important__c = additionalInfo.important;
                opp.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                
                Database.SaveResult oppResult = Database.insert(opp, false);
                if (oppResult.isSuccess())
                {
                    oppId = oppResult.getId();
                    System.debug('Direct Quote: Opportunity created successfully: ' + oppId);
                }
                else // Create Opportunity Fail
                {              
                    for(Database.Error err : oppResult.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity fields that affected this error: ' + err.getFields());
                        result.errorMessage = 'Create Opportunity '+err.getStatusCode() + ': ' + err.getMessage();	
                    }
                    Database.rollback(sp);
                    createErrorMessage(quoteType, result.errorMessage, oppRefId, null, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                }
            }
            else if (quoteType == 'QT')
            {
                System.debug('oppRefId ' + oppRefId);
                if(oppRefId != null && oppRefId != '')
                {
                    opp = [SELECT Id, Name, CurrencyIsoCode, ERP_Id__c,(SELECT Id FROM OpportunityLineItems) FROM Opportunity WHERE Opportunity_ID__c =: oppRefId LIMIT 1];
                    if (opp != null)
                    {           
                        if(oopCurrency != opp.CurrencyIsoCode)
                        {
                            System.debug('Current Curency : ' + opp.CurrencyIsoCode);
                            System.debug('New Curency : ' + oopCurrency);
                            // Deleted all related Opp Items
                            try
                            {
                                if(opp.OpportunityLineItems.size() > 0) delete opp.OpportunityLineItems;
                                //Update Opp Currency to new Currency
                                Opportunity oppCur = new Opportunity(id = opp.Id, CurrencyIsoCode = oopCurrency);
                                Database.SaveResult oppResult = Database.update(oppCur, false);
                                if (oppResult.isSuccess())
                                {
                                    oppId = oppResult.getId();            
                                }
                                else // Update Opp Fail
                                {              
                                    for(Database.Error err : oppResult.getErrors())
                                    {                 
                                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                        System.debug('Oppprtunity fields that affected this error: ' + err.getFields());
                                        result.errorMessage = 'Update Currency Oppprtunity '+oopCurrency+ ' '+err.getStatusCode() + ': ' + err.getMessage(); 
                                    }
                                    Database.rollback(sp);
                                    createErrorMessage(quoteType, result.errorMessage, null, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);  
                                }   
                            }
                            catch (DmlException e)
                            {
                                System.debug(e.getMessage() + ': ' + e.getLineNumber());
                                Database.rollback(sp);
                            }
                        }
                        else
                            oppId = opp.Id;
                        
                        System.debug('Indirect Quote: Refer to the existing opportunity!! : ' + oppId);
                    }
                }
                else
                {
                    result.errorMessage = 'Opportunity ID input is Empty';
                    createErrorMessage(quoteType, result.errorMessage,null, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                }
            }
            else result.errorMessage = 'quoteType input is Empty';
            System.debug(result.errorMessage);
            
            if(oppId != null)
            {
                //-----------Create Quote------------------//
                Quote q = new Quote();
                q.Name = csOrgDefault.Quote_Name_Prefix__c+' '+quoteERPID;
                q.Pricebook2Id = pricebookId;
                q.OpportunityId = oppId;
                //q.OwnerId = qOwner_SF[0].Id;
                q.OwnerId = quoteOwnerId;
                q.status = quoteStatus;
                q.ERP_Id__c = quoteERPID;
                q.Sales_Organization_User__c = quoteSaleOrgUsers.isEmpty() ? null : quoteSaleOrgUsers[0].Id;
                q.Legacy_Source__c = quoteLegacySource;
                if(oppCloseDate == date.valueOf('0002-11-30'))
                    q.ExpirationDate = date.valueOf('1900-01-01');
                else 
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
                q.Quote_Creator__c = quoteCreator;
                q.Application__c = additionalInfo.application;
                q.Integrated_Solution__c = additionalInfo.integratedSolution;
                q.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                q.Important__c = additionalInfo.important;
                q.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                   
                Database.SaveResult quoteResult = Database.insert(q, false);
                if (quoteResult.isSuccess())
                {
                    quoteId = quoteResult.getId();
                    System.debug('Quote created successfully: ' + quoteId);
                    //-----------Create Quote Line Items------------------//
                    if (!QuoteItem.isEmpty())
                    {
                        Integer itemNo = 0;
                        for(QuoteCreationWebService.QuoteItems item : QuoteItem)
                        {
                            if(item.thirdLevelHierarchy != null && item.thirdLevelHierarchy != '')
                                thirdLevelList.add(item.thirdLevelHierarchy);
                            else if(item.materialNumber != null && item.materialNumber != '')
                                materialList.add(item.materialNumber); 
                        }
                        System.debug('Size : '+thirdLevelList.size()+' thirdLevelList: ' + thirdLevelList);
                        System.debug('Size : '+materialList.size()+' materialList: ' + materialList);
                        
                        if(!materialList.isEmpty())
                            thirdLevelList =  QuoteCreationWebService.updateProductHierarchy(materialList,thirdLevelList,QuoteItem);
                        
                        for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c
                                                      FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: oopCurrency
                                                      AND Product2.Third_Level_Product_Hierarchy__c IN: thirdLevelList AND Pricebook2Id =: pricebookId])
                        {
                            pbEntryMap.put(pbEntry.Product2.Third_Level_Product_Hierarchy__c, pbEntry.id); 
                        }
                        System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
                                 
                        for(QuoteCreationWebService.QuoteItems item : QuoteItem)
                        {   
                            Material_Number__c matRef = new Material_Number__c(ERP_Id__c = item.MaterialNumber);
                            String pbId;
                            if(!pbEntryMap.isEmpty()) pbId = pbEntryMap.get(item.thirdLevelHierarchy);
                            if (pbId != null && matRef != null)
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
                                system.debug('PricebookEntry for item '+itemNo+' cannot be found : '+item.thirdLevelHierarchy+' '+oopCurrency);
                                result.errorMessage = 'PricebookEntry for item '+itemNo+' cannot be found : '+item.thirdLevelHierarchy+' '+oopCurrency;
                                Database.rollback(sp);
                                createErrorMessage(quoteType, result.errorMessage, null, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                break;
                            }
                            else if(matRef == null)
                            {
                                result.errorMessage = 'Material for item '+itemNo+' cannot be found : '+item.MaterialNumber;
                                Database.rollback(sp);
                                createErrorMessage(quoteType, result.errorMessage, null, oppRefId, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
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
                                    createErrorMessage(quoteType, result.errorMessage, oppRefId, null, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);  
                                }
                            }
                            System.debug('successQLineItems Set Id: ' + successQLineItemsId);
                            if (quoteItemSuccess == QuoteItem.size() && (quoteStatus == 'Active' || quoteStatus == 'Won'))
                            {
                                //opp.SyncedQuoteId  = quoteId;
                                Opportunity oppUpdate = new Opportunity(Id = oppId, SyncedQuoteId = quoteId);
                                oppUpdate.Application__c = additionalInfo.application;
                                oppUpdate.Integrated_Solution__c = additionalInfo.integratedSolution;
                                oppUpdate.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                                oppUpdate.Important__c = additionalInfo.important;
                                oppUpdate.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams;                                  
                                Database.SaveResult oppUpdateResult = Database.update(oppUpdate, false);
                                if (oppUpdateResult.isSuccess())
                                {
                                    oppId = oppUpdateResult.getId();
                                    System.debug('Quote is Synced to Opportunity successfully!!');
                                    if(!successQLineItemsId.isEmpty()) syncedMaterialNumber(quoteType, successQLineItemsId, oppRefId, quoteERPID);
                                    getOpportunitAutoId(oppId,QuoteId);
                                    if (quoteOwnerDefault == True)
                                    {
                                        String errorMessage = 'Quote Owner is not found in Salesforce'; 
                                        System.debug(errorMessage);
                                        createErrorMessage(quoteType, errorMessage, result.opportunityId, result.quoteId, quoteERPID, accountERPID, ShipToERPID, null, saleOrgCode);
                                    }
                                    
                                }
                                else // Update Opportunity Fail
                                {              
                                    for(Database.Error err : oppUpdateResult.getErrors())
                                    {                 
                                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                        System.debug('Synced Opportunity Product Fail: ' + err.getFields());
                                        result.errorMessage = 'Synced Opportunity Product Fail '+err.getStatusCode() + ': ' + err.getMessage();
                                    }
                                    Database.rollback(sp);
                                    createErrorMessage(quoteType, result.errorMessage, oppRefId, null, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);
                                }
                            }
                            else if ((quoteItemSuccess == QuoteItem.size()) && quoteStatus != 'Active')
                            {
                                getOpportunitAutoId(oppId,QuoteId);
                                if (quoteOwnerDefault == True)
                                {
                                    String errorMessage = 'Quote Owner is not found in Salesforce'; 
                                    System.debug(errorMessage);
                                    createErrorMessage(quoteType, errorMessage, result.opportunityId, result.quoteId, quoteERPID, accountERPID, ShipToERPID, null, saleOrgCode);
                                }
                            }
                        }
                    }
                }
                else // Create Quote Fail
                {              
                    for(Database.Error err : quoteResult.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Quote fields that affected this error: ' + err.getFields());
                        result.errorMessage = 'Create Quote '+quoteERPID+ ' '+err.getStatusCode() + ': ' + err.getMessage(); 
                    }
                    Database.rollback(sp);
                    createErrorMessage(quoteType, result.errorMessage, oppRefId, null, quoteERPID, accountERPID, ShipToERPID, userERPID, saleOrgCode);  
                }
            }
        }
        else
        {
            //result.errorMessage = 'The existing User or ShipTo or saleOrgCode is not found';

            if (shipTo.isEmpty())
                result.errorMessage = 'Ship To is not found: ' + shipToERPID;
            else if (quoteOwnerId == null || oppOwnerId == null)
                result.errorMessage = 'The Default Key User is not found in '+saleOrgCode;
            else if (oppSaleOrgUsers.isEmpty())
                result.errorMessage = 'User : '+oppUserSalesOrgName+' is not found in SalesOrg : '+saleOrgCode;

            System.debug(result.errorMessage);
            createErrorMessage(quoteType, result.errorMessage, oppRefId, null, quoteERPID, accountERPID, ShipToERPID, null, saleOrgCode);
            
        }
        
        System.debug('ReturnValue '+result);
        return result;  
    }
    
    public static List<String> updateProductHierarchy(List<String> materialList, List<String> thirdLevelList, List<QuoteCreationWebService.QuoteItems> QuoteItem)
    {
        Map<String,String> materialPHMap = new Map<String,String>();
        for(Material_Number__c mat : [SELECT Id, Name, X3rd_Level_Product_Hierarchy__c FROM Material_Number__c WHERE Name IN: materialList])
        {
            materialPHMap.put(mat.Name, mat.X3rd_Level_Product_Hierarchy__c);
            thirdLevelList.add(mat.X3rd_Level_Product_Hierarchy__c);
        }
        System.debug('materialPHMap : '+materialPHMap);
        System.debug('Size : '+thirdLevelList.size()+' thirdLevelList: ' + thirdLevelList);
        
        for(QuoteCreationWebService.QuoteItems item : QuoteItem)
        {
            if(materialPHMap.containsKey(item.materialNumber))
                item.thirdLevelHierarchy = materialPHMap.get(item.materialNumber);
        }
        return thirdLevelList;
    }
    
    private static void getOpportunitAutoId(String newOppId, String newQuoteId)
    {
        QuoteCreationWebService.Results res =  new QuoteCreationWebService.Results();
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
    
    public static void syncedMaterialNumber(String scenario, Set<Id> successQLineItemsId, String oppRefId , String quoteERPID)
    {
        Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>();
        List<QuoteLineItem> tmpQuoteLineItems = [SELECT Id, Quote.name, OpportunityLineItemId, Material_Number__c,Rejected__c,Rejected_Reason__c FROM QuoteLineItem WHERE id IN: successQLineItemsId];
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
        try 
        {
            update oppLineItemsMap.values();
            System.debug('OpportunityLineItem '+oppLineItemsMap+' has been synced!');
        } 
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
            result.errorMessage = 'Synced MaterialNumber Fail: '+e.getMessage() + ': ' + e.getLineNumber();
            createErrorMessage(scenario, result.errorMessage, oppRefId, null, quoteERPID, null, null, null, null);
        }
    }
    
    public static void createErrorMessage(String scenario, String errMessage, String oppID, String QuoteID, String quoteERPID, String accountERPID, String ShipToERPID, String userERPID, String SaleOrg)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            if (scenario == 'ZQT') mError.Scenario__c = 'Direct Quotation'; else mError.Scenario__c = 'Indirect Quotation';
            mError.Error_Message_Detail__c = errMessage;
            mError.Opportunity_ID__c = oppID;
            mError.Quote_ID__c = QuoteID;
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