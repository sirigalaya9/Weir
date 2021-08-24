global class OrderCreationWebService
{    
    global class OrderItems
    {
        webservice Integer lineItemNo;
        webservice String materialNumber;
        webservice String thirdLevelHierarchy;
        webservice Integer quantity;
        webservice Double unitPrice;
        webservice Date atp;
        webservice Date loadingDate;	
        webservice Date deliveryDate;
        webservice Date goodIssueDate;
        webservice Date materialAvailableDate;
        webservice Date transportationPlanDate;
        webservice Date originalPromisedDate;
        webservice Date plannedGoodsIssueDate;
        webservice Date plannedMaterialAvailableDate;
        webservice Date originalCusReqDlvDate;
        webservice String shippingPoint;
        webservice String route;
        webservice Boolean rejected;
        webservice String rejectedReason;
    }
    
    global class Results
    {
        webservice String orderId;
        webservice String oppId;
        webservice String errorMessage;
    }
    
    global class AdditionalInfo
    {
        webservice String orderType;
        webservice String saleOrgCode;
        webservice String salesOffice;
        webservice String salesGroup;
        webservice Date oppCloseDate;
        webservice String oppCurrency;
        webservice String oppDistributionChannel;
        webservice String division;
        webservice Date oppBidDueDate;
        webservice Date expectedDeliveryDate;
        webservice Date inquiryReceivedDate;
        webservice Date quotedDate;
        webservice String shippingCondition;
        webservice String incoterm1;
        webservice String incoterm2;
        webservice String paymentTerm;
        webservice Decimal quotedMargin;
        webservice String application;
        webservice String integratedSolution;
        webservice String otherStrategicInitiatives;
        webservice Boolean important;
        webservice Boolean managedByProjectTeams;
        webservice Date orderCreatedDate;
        webservice Date orderReceptionDate;
        webservice Date requestedDeliveryDate;
        webservice String customerPONumber;
        webservice Boolean onHold;
        
    }   
    
    public static OrderCreationWebService.Results result =  new OrderCreationWebService.Results();
    
    webservice static OrderCreationWebService.Results OrderCreation(
        String accountERPID, String userERPID, String shipToERPID, String quoteERPID, Date orderEffectiveDate, String oppRefId,
        String orderCurrency, String orderDescription, String orderERPID, String orderLegacySource,
        String orderBillingStreet, String orderBillingCity, String orderBillingState,
        String orderBillingPostalCode,String orderBillingCountry,String orderCreatedByERPID, String orderOwnerERPID,
        AdditionalInfo additionalInfo,List<OrderItems> OrderItem)
    {
        Id orderId, orderItemId, quoteId, pricebookId;
        Integer orderItemSuccess = 0;
        Pricebook2 pb;
        HCI_SAP__c csOrgDefault = HCI_SAP__c.getOrgDefaults();
        List<OrderItem> oLineList = new List<OrderItem>();
        List<PricebookEntry> pbEntryList;
        List<Quote> quote = new List<Quote>();
        Set<Id> successOLineItemsId = new Set<Id>();
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        List<String> thirdLevelList = new List<String>();
        List<String> materialList = new List<String>();
        Map<String,String> materialPHMap = new Map<String,String>();
        List<User> oppOwner_SF = new List<User>();
        List<Sales_Organization_User__c> oppSaleOrgUsers = new List<Sales_Organization_User__c>();
        List<User> orderOwner_SF = new List<User>();
        List<Sales_Organization_User__c> orderSaleOrgUsers = new List<Sales_Organization_User__c>();
        String orderCreator;
        Id orderOwnerId;
        Id defaultUser;
        String defaultUserDivision;
        Id oppOwnerId;
        String oppUserSalesOrgName;
        
        
        Opportunity opp = new Opportunity();
        Id oppSGTRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SGT_Record_Type').getRecordTypeId ();
        Id oppId;
        List<OpportunityLineItem> oppLineList = new List<OpportunityLineItem>();
        Integer oppItemSuccess = 0;
        
        if(!Test.isRunningTest())
        {
            pb = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard= True LIMIT 1];
            pricebookId = pb.id;
        }
        else
            pricebookId = Test.getStandardPricebookId();
        
        List<Address__c> shipTo = [SELECT Id, Name, Account__r.ERP_Id__c, Street__c, City__c, State__c,
                                   PostalCode__c, Country__c, ERP_ID__c,State_Code__c, Country_Code__c
                                   FROM Address__c WHERE ERP_Id__c =: shipToERPID LIMIT 1];
        
        if (String.isNotBlank(userERPID))
        {
            oppOwner_SF = [SELECT Id, Name, Division FROM User Where ERP_ID__c =: userERPID LIMIT 1];
            
            if(!oppOwner_SF.isEmpty() && oppOwner_SF[0].Name != 'Integration User'){
                oppOwnerId = oppOwner_SF[0].Id;
                oppUserSalesOrgName = oppOwner_SF[0].Name;
                defaultUserDivision = oppOwner_SF[0].Division;
            }
            else if(oppOwner_SF.isEmpty() || (!oppOwner_SF.isEmpty() && oppOwner_SF[0].Name == 'Integration User'))
            {
                system.debug('Integration User or Not found');
                Sales_Organization__c saleOrg = [SELECT Id, Code__c, Default_User__c,Default_User__r.name, Default_User__r.Division FROM Sales_Organization__c Where Code__c =: AdditionalInfo.saleOrgCode LIMIT 1];
                //system.debug('Default_Record_Owner__r.name '+saleOrg.Default_Record_Owner__r.name);
                oppOwnerId = saleOrg.Default_User__c;
                oppUserSalesOrgName = saleOrg.Default_User__r.Name;
                defaultUserDivision = saleOrg.Default_User__r.Division;
            }
            
            if(oppOwnerId != null)
            {
                oppSaleOrgUsers = [SELECT Id, User__r.ERP_ID__c, Code__c, Name FROM Sales_Organization_User__c WHERE User__c =: oppOwnerId AND Code__c =: AdditionalInfo.saleOrgCode LIMIT 1]; 
                system.debug('oppSaleOrgUsers '+oppSaleOrgUsers);
            }
        }
        
        List<User> orderCreatedBy_SF = [SELECT Id, Name FROM User Where ERP_ID__c =: orderCreatedByERPID LIMIT 1];
        
        if(!orderCreatedBy_SF.isEmpty()) orderCreator = orderCreatedBy_SF[0].Name;
        else 
        {
            List<Weir_Employee__c> weirEmployees = [SELECT Id, Name FROM Weir_Employee__c Where ERP_ID__c =: orderCreatedByERPID LIMIT 1];
            if(!weirEmployees.isEmpty()) orderCreator = weirEmployees[0].Name;
            else orderCreator = orderCreatedByERPID;
        }
        
        Boolean orderOwnerDefault =  false;
        if (String.isNotBlank(orderOwnerERPID))
        {
            orderOwner_SF = [SELECT Id, Name FROM User Where ERP_ID__c =: orderOwnerERPID LIMIT 1];
            //system.debug('orderOwner_SF '+orderOwner_SF);
            
            if(!orderOwner_SF.isEmpty() && orderOwner_SF[0].Name != 'Integration User'){
                orderOwnerId = orderOwner_SF[0].Id;
                system.debug('Not Integration User '+orderOwner_SF[0].Name);
            }
            else if(orderOwner_SF.isEmpty() || (!orderOwner_SF.isEmpty() && orderOwner_SF[0].Name == 'Integration User'))
            {
                system.debug('Integration User or Not found');
                Sales_Organization__c saleOrg = [SELECT Id, Code__c, Default_User__c,Default_User__r.name FROM Sales_Organization__c Where Code__c =: additionalInfo.saleOrgCode LIMIT 1];
                //system.debug('Default_Record_Owner__r.name '+saleOrg.Default_Record_Owner__r.name);
                orderOwnerId = saleOrg.Default_User__c;
                orderOwnerDefault = true;
            }
            
            if(orderOwnerId != null)
            {
                orderSaleOrgUsers = [SELECT Id, User__r.ERP_ID__c, Code__c, Name FROM Sales_Organization_User__c WHERE User__c =: orderOwnerId AND Code__c =: additionalInfo.saleOrgCode LIMIT 1];
            }
        }
        
        if(quoteERPID != '' && quoteERPID != null)
        {
            system.debug('quoteERPID : '+quoteERPID);
            quote = [SELECT Id, Name, OpportunityId, Status FROM Quote Where Quote_ID__c =: quoteERPID LIMIT 1];
        }
        
        if(!shipTo.isEmpty() && oppOwnerId != null && orderOwnerId != null)
        {
            Savepoint sp = Database.setSavepoint();
            
            if (!OrderItem.isEmpty())
            {
                Integer itemNo = 0;
                for(OrderCreationWebService.OrderItems item : OrderItem)
                {
                    if(item.thirdLevelHierarchy != null && item.thirdLevelHierarchy != '')
                        thirdLevelList.add(item.thirdLevelHierarchy);
                    else if(item.materialNumber != null && item.materialNumber != '')
                        materialList.add(item.materialNumber); 
                }

                if(!materialList.isEmpty())
                    thirdLevelList =  OrderCreationWebService.updateProductHierarchy(materialList,thirdLevelList,OrderItem);
            }
            
            if (additionalInfo.orderType.equalsIgnoreCase('ZOR') || additionalInfo.orderType.equalsIgnoreCase('OR'))
            {            
                Opportunity oppRef;
                system.debug('oppRefId '+oppRefId);
                if(additionalInfo.orderType.equalsIgnoreCase('ZOR') && oppRefId != null && oppRefId != '')
                {
                    oppRef = [SELECT Id FROM Opportunity WHERE Opportunity_ID__c =: oppRefId];
                    system.debug('oppRef '+oppRef);
                }
                
                //-----------Create Order------------------//
                Order o = new Order();
                o.Name = csOrgDefault.Order_Name_Prefix__c+' '+orderERPID;
                o.Pricebook2Id = pricebookId;
                o.OwnerId = orderOwnerId;
                o.Account = new Account(ERP_Id__c = accountERPID);
                o.status = 'Draft';
                o.Order_Creator__c = orderCreator;
                o.Description = orderDescription;
                o.CurrencyIsoCode = orderCurrency;
                o.ERP_Id__c = orderERPID;
                if(!quote.isEmpty() && additionalInfo.orderType.equalsIgnoreCase('OR')){o.OpportunityId = quote[0].OpportunityId; o.QuoteId = quote[0].id;}
                else if (additionalInfo.orderType.equalsIgnoreCase('ZOR') && oppRef != null) { o.OpportunityId = oppRef.Id; }
                o.Legacy_Source__c = orderLegacySource;
                o.EffectiveDate  = additionalInfo.orderCreatedDate;
                o.billingStreet = orderBillingStreet;
                o.billingCity = orderBillingCity;
                o.billingStateCode = orderBillingState;
                o.billingPostalCode = orderBillingPostalCode;
                o.billingCountryCode = orderBillingCountry;
                o.Shipping_Address__c = shipTo[0].Id;
                o.shippingStreet = shipTo[0].Street__c;
                o.shippingCity = shipTo[0].City__c;
                o.shippingStateCode = shipTo[0].State_Code__c;
                o.shippingPostalCode = shipTo[0].PostalCode__c;
                o.shippingCountryCode = shipTo[0].Country_Code__c;
                o.Shipping_Condition__c = additionalInfo.shippingCondition;
                o.Incoterm_1__c = additionalInfo.incoterm1;
                o.Incoterm_2__c = additionalInfo.incoterm2;
                o.Payment_Term__c = additionalInfo.paymentTerm;
                o.Quoted_Margin__c = additionalInfo.quotedMargin;
                o.Application__c = additionalInfo.application;
                o.Integrated_Solution__c = additionalInfo.integratedSolution;
                o.Other_Strategic_Initiatives__c = additionalInfo.otherStrategicInitiatives;
                o.Important__c = additionalInfo.important;
                o.Managed_by_Project_Teams__c = additionalInfo.managedByProjectTeams; 
                //o.SAP_Order_Created_Date__c  = additionalInfo.orderCreatedDate;
                o.Order_Reception_Date__c  = additionalInfo.orderReceptionDate;
                o.Requested_Delivery_Date__c = additionalInfo.requestedDeliveryDate;
                o.Sales_Organization__c = additionalInfo.saleOrgCode;
                o.Customer_PO_Number__c  = additionalInfo.customerPONumber;
                o.Credit_On_Hold__c  = additionalInfo.onHold;
                
                system.debug('Order '+o);
                Database.SaveResult orderResult = Database.insert(o, false);
                if (orderResult.isSuccess())
                {
                    orderId = orderResult.getId();
                    System.debug('Order created successfully: ' + orderId);
                    //-----------Create Order Line Items------------------//
                    if (!OrderItem.isEmpty())
                    {
                        Integer itemNo = 0;
                        for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c
                                                      FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: orderCurrency
                                                      AND Product2.Third_Level_Product_Hierarchy__c IN: thirdLevelList AND Pricebook2Id =: pricebookId])
                        {
                            pbEntryMap.put(pbEntry.Product2.Third_Level_Product_Hierarchy__c, pbEntry.id);
                        }
                        
                        for(OrderCreationWebService.OrderItems item : OrderItem)
                        {   
                            Material_Number__c matRef = new Material_Number__c(ERP_Id__c = item.MaterialNumber);
                            String pbId;
                            if(!pbEntryMap.isEmpty()) pbId = pbEntryMap.get(item.thirdLevelHierarchy);
                            if (pbId != null && (matRef != null))
                            {
                                OrderItem oItem = new OrderItem();
                                //if(pbEntryMap.containsKey(item.thirdLevelHierarchy)) oItem.PricebookEntryId = pbEntryMap.get(item.thirdLevelHierarchy);
                                oItem.PricebookEntryId = pbId;
                                oItem.orderId = orderId;
                                oItem.Material_Number__r = matRef;
                                oItem.quantity = item.Quantity;
                                oItem.UnitPrice = item.UnitPrice;
                                oItem.Availability_to_Promise_ATP__c = item.atp;
                                oItem.Line_Item_No__c = item.lineItemNo;
                                oItem.Loading_Date__c = item.loadingDate;
                                oItem.Delivery_Date__c = item.deliveryDate;
                                oItem.Good_Issue_Date__c = item.goodIssueDate;
                                oItem.Material_Available_Date__c = item.materialAvailableDate;
                                oItem.Transportation_Plan_Date__c = item.transportationPlanDate;
                                oItem.Original_Promised_Date__c = item.originalPromisedDate;
                                oItem.X1st_Planned_Goods_Issue_Date__c  = item.plannedGoodsIssueDate;
                                oItem.X1st_Planned_Material_Avail_Date__c = item.plannedMaterialAvailableDate;
                                oItem.Original_Customer_Request_Delivery_Date__c = item.originalCusReqDlvDate;
                                oItem.Shipping_Point__c = item.shippingPoint;
                                oItem.Route__c = item.route;
                                oItem.Rejected__c = item.rejected;
                                oItem.Rejected_Reason__c = item.rejectedReason;
                                
                                oLineList.add(oItem);
                                itemNo = itemNo+1;
                                system.debug('OrderItem: '+itemNo+' '+oItem);
                            }
                            else if(pbId == null) 
                            {
                                result.errorMessage = 'PricebookEntry for item '+itemNo+' cannot be found : '+item.thirdLevelHierarchy+' '+additionalInfo.oppCurrency;
                                Database.rollback(sp);
                                createErrorMessage(additionalInfo.orderType, result.errorMessage,null,null, quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode, orderERPID);
                                break;
                            }
                            else if(matRef == null) 
                            {
                                result.errorMessage = 'Material for item '+itemNo+' cannot be found : '+item.MaterialNumber;
                                Database.rollback(sp);
                                createErrorMessage(additionalInfo.orderType, result.errorMessage,null,null, quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode, orderERPID);
                                break;
                            }  
                        }
                        
                        if(!oLineList.isEmpty() && (oLineList.size() == OrderItem.size()))
                        {
                            Database.SaveResult[] orderItemResultList = Database.insert(oLineList, false);
                            for (Database.SaveResult sr : orderItemResultList) 
                            {
                                if (sr.isSuccess())
                                {
                                    orderItemSuccess = orderItemSuccess+1;
                                    System.debug('OrderItems created successfully: ' + sr.getId());
                                }
                                else
                                {              
                                    for(Database.Error err : sr.getErrors())
                                    {                 
                                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                        System.debug('OrderItems fields that affected this error: ' + err.getFields());
                                        result.errorMessage = 'Create OrderItems '+err.getStatusCode() + ': ' + err.getMessage();
                                    }
                                    Database.rollback(sp);
                                    createErrorMessage(additionalInfo.orderType, result.errorMessage,null,null, quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode,orderERPID);
                                }
                            }
                            
                            if(orderItemSuccess == orderItem.size())
                            {
                                //Update Order Status to 'Activated'
                                Order mOrderItem = new Order(Id = OrderId, status = 'Activated');
                                try 
                                {
                                    Update mOrderItem;
                                    System.debug(OrderId+' status has been updated to '+mOrderItem.status);
                                    //Update Quote Status to 'Won'
                                    if(!quote.isEmpty())
                                    {
                                        Quote q = new Quote(Id = quote[0].id , status = 'Won');
                                        opp = new Opportunity(Id = quote[0].opportunityId, StageName = 'Contract', Closed_Reason__c = 'Won due to SAP order generated');
                                        Integer relatedOrdersSize = [SELECT count() FROM Order where OpportunityId =: opp.Id];
                                        system.debug('relatedOrdersSize : '+relatedOrdersSize);
                                        if(relatedOrdersSize == 1) opp.CloseDate = orderEffectiveDate;
                                        Update q;
                                        Update opp;
                                        System.debug(q.id+' status has been updated to WON!');
                                        System.debug(opp.id+' status has been updated to Contract!');
                                        //Return OrderID back to ECC
                                        List<Order> orders = [SELECT Id, Name, Order_ID__c FROM Order WHERE Id =: orderId LIMIT 1];
                                        List<Opportunity> opps = [SELECT Opportunity_ID__c FROM Opportunity WHERE Id =: opp.Id];
                                        if(!orders.isEmpty())
                                        {
                                            result.orderId = String.valueOf(orders[0].Order_ID__c);
                                            if (!opps.isEmpty())
                                                result.oppId = String.valueOf(opps[0].Opportunity_ID__c);
                                        }
                                        else
                                            result.errorMessage = 'Response Value: Cannot Query OrderID'; 
                                    }
                                    else
                                    {
                                        //Return OrderID back to ECC
                                        List<Order> orders = [SELECT Id, Name, Order_ID__c FROM Order WHERE Id =: orderId LIMIT 1];
                                        List<Opportunity> opps = [SELECT Opportunity_ID__c FROM Opportunity WHERE Id =: opp.Id];
                                        if(!orders.isEmpty())
                                        {
                                            result.orderId = String.valueOf(orders[0].Order_ID__c);
                                            if (!opps.isEmpty())
                                                result.oppId = String.valueOf(opps[0].Opportunity_ID__c);
                                            
                                            if (orderOwnerDefault == True)
                                            {
                                                String errorMessage = 'Order Owner is not found in Salesforce'; 
                                                System.debug(errorMessage);
                                                createErrorMessage(additionalInfo.orderType, errorMessage,result.oppId, result.orderId, quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode,orderERPID); 
                                            }
                                        }
                                        else
                                            result.errorMessage = 'Response Value: Cannot Query OrderID'; 
                                    }
                                    
                                }
                                catch (DmlException e)
                                {
                                    result.errorMessage = e.getMessage() + ': ' + e.getLineNumber();
                                    System.debug(result.errorMessage);
                                    Database.rollback(sp);
                                    createErrorMessage(additionalInfo.orderType, result.errorMessage,null,null, quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode,orderERPID); 
                                }
                                
                            }
                        }
                    }
                }
                else // Create Order Fail
                {              
                    for(Database.Error err : orderResult.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Order fields that affected this error: ' + err.getFields());
                        result.errorMessage = 'Create Order '+err.getStatusCode() + ': ' + err.getMessage();
                    }
                    Database.rollback(sp);
                    createErrorMessage(additionalInfo.orderType, result.errorMessage, null,null,quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode,orderERPID);
                }
            }
        }
        else
        {
            if (shipTo.isEmpty())
                result.errorMessage = 'Ship To is not found: ' + shipToERPID;
            else if (orderOwnerId == null || oppOwnerId == null)
                result.errorMessage = 'The Default Key User is not found in '+additionalInfo.saleOrgCode;
            /*else if (oppSaleOrgUsers == null)
                result.errorMessage = 'User : '+oppUserSalesOrgName+' is not found in SalesOrg : '+additionalInfo.saleOrgCode;*/
            
            System.debug(result.errorMessage);
            createErrorMessage(additionalInfo.orderType, result.errorMessage, null,null,quoteERPID, accountERPID, ShipToERPID, userERPID, additionalInfo.saleOrgCode,orderERPID);
        }
        System.debug('ReturnValue '+result);
        return result; 
    }
    
    public static List<String> updateProductHierarchy(List<String> materialList, List<String> thirdLevelList, List<OrderCreationWebService.OrderItems> OrderItem)
    {
        Map<String,String> materialPHMap = new Map<String,String>();
        for(Material_Number__c mat : [SELECT Id, Name, X3rd_Level_Product_Hierarchy__c FROM Material_Number__c WHERE Name IN: materialList])
        {
            materialPHMap.put(mat.Name, mat.X3rd_Level_Product_Hierarchy__c);
            thirdLevelList.add(mat.X3rd_Level_Product_Hierarchy__c);
        }
        System.debug('materialPHMap : '+materialPHMap);
        System.debug('Size : '+thirdLevelList.size()+' thirdLevelList: ' + thirdLevelList);
        
        for(OrderCreationWebService.OrderItems item : OrderItem)
        {
            if(materialPHMap.containsKey(item.materialNumber))
                item.thirdLevelHierarchy = materialPHMap.get(item.materialNumber);
        }
        return thirdLevelList;
    }
    
    public static void createErrorMessage(String scenario, String errMessage, String oppID, String OrderID, String quoteERPID, String accountERPID, String ShipToERPID, String userERPID, String SaleOrg, String orderERPID)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            if (scenario == 'ZOR') mError.Scenario__c = 'Direct Order';
            else mError.Scenario__c = 'Indirect Order';
            mError.Opportunity_ID__c = oppID;
            mError.Order_ID__c = OrderID;
            mError.Error_Message_Detail__c = errMessage;
            mError.Quote_ERP_ID__c = quoteERPID;
            mError.Account_ERP_ID__c = accountERPID;
            mError.ShipTo_ERP_ID__c = shipToERPID;
            mError.User_ERP_ID__c = userERPID;
            mError.Sale_Organization__c = SaleOrg;
            mError.Order_ERP_ID__c = orderERPID;
            insert mError;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}