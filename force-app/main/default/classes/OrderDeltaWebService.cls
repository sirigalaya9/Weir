global class OrderDeltaWebService
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
        webservice String saleOrgCode;
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
    
    public static OrderDeltaWebService.Results result =  new OrderDeltaWebService.Results();
    
    webservice static OrderDeltaWebService.Results OrderDelta(
        String accountERPID, String userERPID, String shipToERPID, Date orderEffectiveDate, String oppRefId,
        String orderCurrency, String orderDescription, String orderERPID, String orderLegacySource,
        String orderBillingStreet, String orderBillingCity, String orderBillingState,
        String orderBillingPostalCode,String orderBillingCountry,
        String orderCreatedByERPID, String orderOwnerERPID,
        AdditionalInfo additionalInfo,
        List<OrderItems> OrderItem)
    {
        Id orderId, orderItemId, quoteId, pricebookId;
        Integer orderItemSuccess = 0;
        String orderStatus,oppId;
        Set<Id> successOrderLineItemsId = new Set<Id>();
        Pricebook2 pb;
        HCI_SAP__c csOrgDefault = HCI_SAP__c.getOrgDefaults();
        List<OrderItem> oLineList = new List<OrderItem>();
        List<PricebookEntry> pbEntryList;
        Map<String,Id> pbEntryMap = new Map<String,Id>();
        List<String> thirdLevelList = new List<String>();
        List<String> materialList = new List<String>();
        Opportunity oppUpdate;
        List<Delivery_Product__c> existDeliveryProducts = new List<Delivery_Product__c>();
        Map<Decimal,List<Id>> deliveryOrderItemMap = new Map<Decimal,List<Id>>(); // Map OrderItem NO , Delivery Pro Id
        Map<Decimal,List<Id>> invoiceItemMap = new Map<Decimal,List<Id>>(); // Map OrderItem NO , Invoice Item Id
        Map<Decimal,OrderItem> orderItemStatusMap = new Map<Decimal,OrderItem>();
        List<Invoice_Item__c> existinvoiceItems = new List<Invoice_Item__c>();
        List<User> oppOwner_SF = new List<User>();
        List<Sales_Organization_User__c> oppSaleOrgUsers = new List<Sales_Organization_User__c>();
        List<User> orderOwner_SF = new List<User>();
        List<Sales_Organization_User__c> orderSaleOrgUsers = new List<Sales_Organization_User__c>();
        Id orderOwnerId,defaultUser,oppOwnerId;
        String orderCreator,defaultUserDivision,oppUserSalesOrgName;
        //Map<Decimal,List<Id>> orderItemNoDeliveryItemIdMap = new Map<Decimal,List<Id>>();
        
        if(!Test.isRunningTest())
        {
            pb = [SELECT Id, Name, IsActive FROM PriceBook2 WHERE IsStandard= True LIMIT 1];
            pricebookId = pb.id;
        }
        else
            pricebookId = Test.getStandardPricebookId();
        
        List<Order> order = [SELECT Id, OpportunityId, QuoteId, CurrencyIsoCode, Opportunity.CurrencyIsoCode,(SELECT Id FROM OrderItems) FROM Order WHERE ERP_Id__c =: orderERPID LIMIT 1];
        List<User> user = [SELECT Id, Name FROM User Where ERP_ID__c =: userERPID LIMIT 1];
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

        if(!shipTo.isEmpty() && !order.isEmpty())
        {
            Savepoint sp = Database.setSavepoint();
            
            existDeliveryProducts = [SELECT Id, Name, Delivery__c, Order_Item_No__c, Order_Product__r.Line_Item_No__c FROM Delivery_Product__c WHERE Order_Product__r.Order.ERP_ID__c =: orderERPID];
            for(Delivery_Product__c deliveryPro : existDeliveryProducts)
            {
                //DeliveryOrderItemMap.put(deliveryPro.Order_Product__r.Line_Item_No__c, deliveryPro.Id);//Delivery_Item_ID__c
                
                if(!deliveryOrderItemMap.containsKey(deliveryPro.Order_Product__r.Line_Item_No__c)){
                    deliveryOrderItemMap.put(deliveryPro.Order_Product__r.Line_Item_No__c, new List<Id >{deliveryPro.Id});
                }
                else{
                    deliveryOrderItemMap.get(deliveryPro.Order_Product__r.Line_Item_No__c).add(deliveryPro.Id);
                }
                
                
            }

            existinvoiceItems = [SELECT Id, Invoice_Item_No__c, Order_Item__c, Order_Item__r.Line_Item_No__c FROM Invoice_Item__c WHERE Order_Item__r.Order.ERP_ID__c =: orderERPID];
            for(Invoice_Item__c invoiceItem : existinvoiceItems)
            {
                //invoiceItemMap.put(invoiceItem.Order_Item__r.Line_Item_No__c, invoiceItem.Id);
                if(!invoiceItemMap.containsKey(invoiceItem.Order_Item__r.Line_Item_No__c)){
                    invoiceItemMap.put(invoiceItem.Order_Item__r.Line_Item_No__c, new List<Id >{invoiceItem.Id});
                }
                else{
                    invoiceItemMap.get(invoiceItem.Order_Item__r.Line_Item_No__c).add(invoiceItem.Id);
                }
            }
            
            system.debug(DeliveryOrderItemMap);
            system.debug(invoiceItemMap);
            
            /*if(orderCurrency != order[0].Opportunity.CurrencyIsoCode && order[0].QuoteId == null)
                {
                    Order oCur = new Order(id = order[0].id, status = 'Draft');
                    update oCur;
                    List<OpportunityLineItem> oppLineItems = [SELECT Id, OpportunityId FROM OpportunityLineItem WHERE OpportunityId =: order[0].OpportunityId];
                    if(order[0].OrderItems.size() > 0) delete order[0].OrderItems;
                    if(oppLineItems.size() > 0) delete oppLineItems;
                    update oppUpdate = new Opportunity(Id = order[0].OpportunityId, CurrencyIsoCode = orderCurrency, Quoted_Margin__c = additionalInfo.quotedMargin);
                }
                else
                    update oppUpdate = new Opportunity(Id = order[0].OpportunityId, Quoted_Margin__c = additionalInfo.quotedMargin);
				*/
            
            system.debug(orderCurrency);
            system.debug(order[0].CurrencyIsoCode);
            if(orderCurrency != order[0].CurrencyIsoCode)
            {
                Order oCur = new Order(id = order[0].id, status = 'Draft');
                update oCur;
                if(order[0].OrderItems.size() > 0) delete order[0].OrderItems;
            }
            
            //if(order[0].OpportunityId != null) oppId = order[0].OpportunityId;
            
            system.debug('oppRefId : '+oppRefId);
            Opportunity oppRef;
            if(oppRefId != null && oppRefId != '') oppRef = [SELECT Id FROM Opportunity WHERE Opportunity_ID__c =: oppRefId];
            //system.debug('oppRef : '+oppRef);
            //system.debug('oppRef ID : '+oppRef.Id);
            
            //-----------Update Order------------------//
            Order o = new Order();
            o.id = order[0].id;
            o.Name = csOrgDefault.Order_Name_Prefix__c+' '+orderERPID;
            o.Pricebook2Id = pricebookId;
            o.Account = new Account(ERP_Id__c = accountERPID);
            if(oppRef != null ) o.OpportunityId = oppRef.Id;
            else o.OpportunityId = null;
            o.status = 'Draft';
            o.Order_Creator__c = orderCreator;
            o.Description = orderDescription;
            o.CurrencyIsoCode = orderCurrency;
            o.ERP_Id__c = orderERPID;
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
            o.Order_Reception_Date__c  = additionalInfo.orderReceptionDate;
            o.Requested_Delivery_Date__c = additionalInfo.requestedDeliveryDate;
            o.Sales_Organization__c = additionalInfo.saleOrgCode;
            o.Customer_PO_Number__c  = additionalInfo.customerPONumber;
            o.Credit_On_Hold__c  = additionalInfo.onHold;
            
            
            system.debug('Order '+o);
            Database.SaveResult orderResult = Database.update(o, false);
            if (orderResult.isSuccess())
            {
                orderId = orderResult.getId();
                System.debug('Order created successfully: ' + orderId);
                //-----------Update Order Line Items------------------//
                
                List<OrderItem> delOrderItems = [SELECT Id, Line_Item_No__c, Status__c, Actual_Goods_Issue_Date__c, Order.ERP_ID__c FROM OrderItem where Order.ERP_ID__c=: orderERPID];
                if(!delOrderItems.isEmpty()) 
                { 
                    for(OrderItem dItem : delOrderItems)
                    {
                        orderItemStatusMap.put(dItem.Line_Item_No__c , dItem);
                    }
                    
                    delete delOrderItems;
                    System.debug('orderItemStatusMap '+orderItemStatusMap);
                    System.debug(delOrderItems+' has been Deleted!');
                }
                
                if (!OrderItem.isEmpty())
                {
                    Integer itemNo = 0;
                    for(OrderDeltaWebService.OrderItems item : OrderItem)
                    {
                        if(item.thirdLevelHierarchy != null && item.thirdLevelHierarchy != '')
                            thirdLevelList.add(item.thirdLevelHierarchy);
                        else if(item.materialNumber != null && item.materialNumber != '')
                            materialList.add(item.materialNumber); 
                    }

                    if(!materialList.isEmpty())
                        thirdLevelList =  OrderDeltaWebService.updateProductHierarchy(materialList,thirdLevelList,OrderItem);
                    
                    for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c
                                                  FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: orderCurrency
                                                  AND Product2.Third_Level_Product_Hierarchy__c IN: thirdLevelList AND Pricebook2Id =: pricebookId])
                    {
                        pbEntryMap.put(pbEntry.Product2.Third_Level_Product_Hierarchy__c, pbEntry.id);
                    }
                    
                    System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);

                    for(OrderDeltaWebService.OrderItems item : OrderItem)
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
                            oitem.Original_Promised_Date__c = item.originalPromisedDate;
                            oItem.X1st_Planned_Goods_Issue_Date__c  = item.plannedGoodsIssueDate;
                            oItem.X1st_Planned_Material_Avail_Date__c = item.plannedMaterialAvailableDate;
                            oItem.Original_Customer_Request_Delivery_Date__c = item.originalCusReqDlvDate;
                            oItem.Shipping_Point__c = item.shippingPoint;
                            oItem.Route__c = item.route;
                            oItem.Rejected__c = item.rejected;
                            oItem.Rejected_Reason__c = item.rejectedReason;
                            oLineList.add(oItem);
                            itemNo = itemNo+1;
                            system.debug('OrderItem: '+itemNo+' '+item);
                        }
                        else if(pbId == null)
                        {
                            result.errorMessage = 'PricebookEntry for item '+itemNo+' cannot be found : '+item.thirdLevelHierarchy+' '+orderCurrency;
                            Database.rollback(sp);
                            createErrorMessage(result.errorMessage, accountERPID, ShipToERPID, userERPID,orderERPID);
                            break;
                        }
                        else if(matRef == null) 
                        {
                            result.errorMessage = 'Material for item '+itemNo+' cannot be found : '+item.MaterialNumber;
                            Database.rollback(sp);
                            createErrorMessage(result.errorMessage, accountERPID, ShipToERPID, userERPID,orderERPID);
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
                                successOrderLineItemsId.add(sr.getId());
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
                                createErrorMessage(result.errorMessage, accountERPID, ShipToERPID, userERPID,orderERPID);
                            }
                        }
                        
                        if(orderItemSuccess == orderItem.size())
                        {
                            //Update Order Status to 'Activated'
                            Order mOrderItem = new Order(Id = OrderId, status = 'Activated');
                            try 
                            {
                                Update mOrderItem;
                                System.debug(OrderId+' status has been updated to '+mOrderItem.Status);
                                SyncOrderItems(successOrderLineItemsId, deliveryOrderItemMap, invoiceItemMap, orderItemStatusMap);
                                //if(order[0].QuoteId == null) Direct Order
                                    //syncedLineItems(successOrderLineItemsId, oppId, orderERPID, sp);
                                //Return OrderID back to ECC
                                List<Order> orders = [SELECT Id, Name, Order_ID__c FROM Order WHERE Id =: orderId LIMIT 1];
                                List<Opportunity> opps = [SELECT Opportunity_ID__c FROM Opportunity WHERE Id =: oppId];
                                if(!orders.isEmpty()){
                                    result.orderId = String.valueOf(orders[0].Order_ID__c);
                                    if (!opps.isEmpty())result.oppId = String.valueOf(opps[0].Opportunity_ID__c);
                                }
                            }
                            catch (DmlException e)
                            {
                                result.errorMessage = e.getMessage() + ': ' + e.getLineNumber();
                                System.debug(result.errorMessage);
                                Database.rollback(sp);
                                createErrorMessage(result.errorMessage, accountERPID, ShipToERPID, userERPID, orderERPID);
                            } 
                        } 
                    }
                }
                else
                {
                    List<Order> orders = [SELECT Id, Name, Order_ID__c FROM Order WHERE Id =: orderId LIMIT 1];
                    List<Opportunity> opps = [SELECT Opportunity_ID__c FROM Opportunity WHERE Id =: oppId];
                    if(!orders.isEmpty()){
                        result.orderId = String.valueOf(orders[0].Order_ID__c);
                        if (!opps.isEmpty())result.oppId = String.valueOf(opps[0].Opportunity_ID__c);
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
                    Database.rollback(sp);
                    createErrorMessage(result.errorMessage, accountERPID, ShipToERPID, userERPID, orderERPID);
                }
            }
        }
        else
        {
            if (shipTo.isEmpty())
                result.errorMessage = 'Ship To is not found: ' + shipToERPID;
            else if (order.isEmpty())
                result.errorMessage = 'Order To is not found: ' + orderERPID;
            /*else if (order[0].OpportunityId == null)
                result.errorMessage = 'Related opportunity is not found';*/
            createErrorMessage(result.errorMessage, accountERPID, ShipToERPID, userERPID, orderERPID);
            System.debug(result.errorMessage);
        }
        
        System.debug('ReturnValue '+result);
        return result; 
    }
    
     /*public static void syncedLineItems (Set<Id> successOrderLineItemsId, String oppId, String orderERPID, Savepoint sp)
    {
        Map<Id, OpportunityLineItem> oppLineItemsMap = new Map<Id, OpportunityLineItem>();
        List<OpportunityLineItem> oppItems = new List<OpportunityLineItem>();
        List<OrderItem> tmpOrderLineItems = [SELECT Id,Material_Number__c,quantity,UnitPrice,Availability_to_Promise_ATP__c,Product2Id,PricebookEntryId FROM OrderItem WHERE id IN: successOrderLineItemsId];
       
        List<OpportunityLineItem> tmpoppLineItems = [SELECT Id, OpportunityId, Product2Id, PricebookEntryId, Quantity, TotalPrice, UnitPrice, ListPrice, Material_Number__c, Weighted_Total_Price__c, 
                                                     ProductHierarchy__c, MaterialHierarchy__c, Material_Description__c FROM OpportunityLineItem WHERE OpportunityId =: oppId];
        
        System.debug('tmpOrderLineItems '+tmpOrderLineItems);

        if(!tmpOrderLineItems.isEmpty())
        {
            for(OrderItem o : tmpOrderLineItems)
            {
                OpportunityLineItem oppItem = new OpportunityLineItem();
                oppItem.Product2Id = o.Product2Id;
                oppItem.PricebookEntryId = o.PricebookEntryId;
                oppItem.Material_Number__c = o.Material_Number__c;
                oppItem.quantity = o.quantity;
                oppItem.UnitPrice = o.UnitPrice;
                //oppItem.Availability_to_Promise_ATP__c = o.Availability_to_Promise_ATP__c;
                oppItem.opportunityId = oppId;
                oppItems.add(oppItem);
                System.debug('oppItem '+oppItem);
            }
        }
        
        if(!oppItems.isEmpty())
        {
            try 
            {
                delete tmpoppLineItems;
                insert oppItems;
            } 
            catch (DmlException e)
            {
                System.debug(e.getMessage() + ': ' + e.getLineNumber());
                result.errorMessage = 'Synced to OppItems Fail: '+e.getMessage() + ': ' + e.getLineNumber();
                Database.rollback(sp);
                createErrorMessage(result.errorMessage, null, null, null, orderERPID);
            }
        }
    }*/
    
    public static List<String> updateProductHierarchy(List<String> materialList, List<String> thirdLevelList, List<OrderDeltaWebService.OrderItems> OrderItem)
    {
        Map<String,String> materialPHMap = new Map<String,String>();
        for(Material_Number__c mat : [SELECT Id, Name, X3rd_Level_Product_Hierarchy__c FROM Material_Number__c WHERE Name IN: materialList])
        {
            materialPHMap.put(mat.Name, mat.X3rd_Level_Product_Hierarchy__c);
            thirdLevelList.add(mat.X3rd_Level_Product_Hierarchy__c);
        }
        System.debug('materialPHMap : '+materialPHMap);
        System.debug('Size : '+thirdLevelList.size()+' thirdLevelList: ' + thirdLevelList);
        
        for(OrderDeltaWebService.OrderItems item : OrderItem)
        {
            if(materialPHMap.containsKey(item.materialNumber))
                item.thirdLevelHierarchy = materialPHMap.get(item.materialNumber);
        }
        return thirdLevelList;
    }
    
    public static void SyncOrderItems(Set<Id> successOrderLineItemsId, Map<Decimal,List<Id>> deliveryOrderItemMap, Map<Decimal,List<Id>> invoiceItemMap, Map<Decimal,OrderItem> orderItemStatusMap)
    {
        List<OrderItem> tmpOrderLineItems = [SELECT Id, Line_Item_No__c, Status__c,quantity,UnitPrice,OrderId FROM OrderItem WHERE id IN: successOrderLineItemsId];
        List<Delivery_Product__c> deliveryProducts = new List<Delivery_Product__c>();
        List<Invoice_Item__c> invoiceItems = new List<Invoice_Item__c>();
        system.debug('tmpOrderLineItems '+tmpOrderLineItems);
        
        for(OrderItem orderItem : tmpOrderLineItems)
        {
            system.debug('Line_Item_No__c '+orderItem.Line_Item_No__c);
            for(Decimal itemNo : deliveryOrderItemMap.keySet())
            {
                system.debug('itemNo '+itemNo);
                if(orderItem.Line_Item_No__c == itemNo)
                {
                    for(Id dItemId : deliveryOrderItemMap.get(orderItem.Line_Item_No__c))
                    {
                        Delivery_Product__c deliveryProduct = new Delivery_Product__c();
                        deliveryProduct.Id = dItemId; 
                        deliveryProduct.Order_Product__c = orderItem.Id;
                        deliveryProducts.add(deliveryProduct);
                    }
                }
            }
            
            for(Decimal itemNo : invoiceItemMap.keySet())
            {
                system.debug('itemNo '+itemNo);
                if(orderItem.Line_Item_No__c == itemNo)
                {
                    for(Id invItemId : invoiceItemMap.get(orderItem.Line_Item_No__c))
                    {
                        Invoice_Item__c invoiceItem = new Invoice_Item__c();
                        invoiceItem.Id = invItemId; 
                        invoiceItem.Order_Item__c = orderItem.Id; 
                        invoiceItems.add(invoiceItem);
                    }
                }
            }
            
            system.debug('orderItemStatusMap to sync '+orderItemStatusMap);
            
            for(Decimal itemNo : orderItemStatusMap.keySet())
            {
                if(orderItem.Line_Item_No__c == itemNo)
                {
                    orderItem.Status__c = orderItemStatusMap.get(orderItem.Line_Item_No__c).Status__c;
                    orderItem.Actual_Goods_Issue_Date__c = orderItemStatusMap.get(orderItem.Line_Item_No__c).Actual_Goods_Issue_Date__c;
                }
            }
        }

        if(!deliveryProducts.isEmpty()){
            Database.SaveResult[] srList = Database.update(deliveryProducts, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                }
                else {              
                    for(Database.Error err : sr.getErrors()) {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        createErrorMessage(err.getStatusCode() + ': ' + err.getMessage(), null, null, null, null);
                    }
                }
            }
        }
        
        if(!invoiceItems.isEmpty()){
            Database.SaveResult[] srList = Database.update(invoiceItems, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                }
                else {              
                    for(Database.Error err : sr.getErrors()) {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        createErrorMessage(err.getStatusCode() + ': ' + err.getMessage(), null, null, null, null);
                    }
                }
            }
        }
        
        if(!tmpOrderLineItems.isEmpty()){
            Database.SaveResult[] srList = Database.update(tmpOrderLineItems, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                }
                else {              
                    for(Database.Error err : sr.getErrors()) {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        createErrorMessage(err.getStatusCode() + ': ' + err.getMessage(), null, null, null, null);
                    }
                }
            }
        }

        /*try{
            update deliveryProducts;
            update invoiceItems;
            update tmpOrderLineItems;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
            result.errorMessage = 'SyncOrderItems Fail: '+e.getMessage() + ': ' + e.getLineNumber();
        }*/
        
    }

    public static void createErrorMessage(String errMessage, String accountERPID, String ShipToERPID, String userERPID, String orderERPID)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = 'Delta Sales Order';
            mError.Error_Message_Detail__c = errMessage;
            mError.Account_ERP_ID__c = accountERPID;
            mError.ShipTo_ERP_ID__c = shipToERPID;
            mError.User_ERP_ID__c = userERPID;
            mError.Order_ERP_ID__c = orderERPID;
            insert mError;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}