global class DeliveryDeltaWebservice
{    
    global class DeliveryItem
    {
        webservice	Integer	doLineItemNo;
        webservice	Integer	orderLineItemNo;
        webservice	String	orderERPID; 
        webservice	String	materialNumber;
        webservice	Decimal	deliveryQuantity;
        webservice	String	uom;
        webservice	Decimal	netWeight;
        webservice	Decimal	grossWeight;
        webservice	String	weightUnit;
        webservice	String	pickingStatus;
        webservice	String	packingStatus;
        webservice	String	goodIssuedStatus;
        webservice	String	proofOfDeliveryStatus ;
        webservice	String	billingStatus;
        webservice	String	materialDescription;
    }
    
    global class Results
    {
        webservice boolean success;
        webservice String errorMessage;
    }
    
    public static DeliveryDeltaWebservice.Results result =  new DeliveryDeltaWebservice.Results();
    
    webservice static DeliveryDeltaWebservice.Results DeliveryDelta(
        String deliveryERPID, String trackingNo, Date plannedGIDate, Date actualGIDate, Date loadingDate, Date pickingDate, Date transPlanningDate,
        String shipToStreet, String shipToCity, String ShipToState, String shipToPostalCode, String shipToCountry, String accountERPID,
        String pickingStatus, String packingStatus, String goodIssuedStatus, String proofOfDeliveryStatus, String billingStatus, Date deliveryDate,Date documentDate,
        String saleOrgCode, String ShipToERPID, String carrierName, List<DeliveryItem> DeliveryItems)
        
        
    {
        Id deliveryId;
        Integer deliveryItemSuccess = 0;
        List<Delivery_Product__c> deliveryProducts = new List<Delivery_Product__c>();
        Map<String,Id> orderItemsMap = new Map<String,Id>();
        List<String> allDeliveryOrderERPIds = new List<String>();
        List<OrderItem> allOrderItems = new List<OrderItem>();
        List<String> newDevItemsKey = new List<String>();
        List<Id> successDeliveryProductIds = new List<Id>();
        Map<String,DeliveryDeltaWebservice.DeliveryItem> keyDeliveryItemMap = new Map<String,DeliveryDeltaWebservice.DeliveryItem>();
        result.success = false;
        Boolean itemDeleted = false;
        Boolean validatedItems = false;
        
        List<Delivery__c>  Deliveries = [SELECT Id, (SELECT Id, Delivery__c, DO_Item_No__c, Order_Item_No__c, Item_Status__c, Item_Status_Detail__c, Order_Product__c, 
                                                     Order_Product__r.Order.ERP_Id__c, Delivery_Item_ID__c, Delivery__r.SAP_Delivery_Order_No__c
                                                     FROM Delivery_Orders__r)  FROM Delivery__c WHERE SAP_Delivery_Order_No__c =: deliveryERPID];
        
        List<Address__c> shipTo = [SELECT Id FROM Address__c WHERE ERP_Id__c =: shipToERPID LIMIT 1];
        system.debug('shipTo : '+shipTo);
        
        if (!Deliveries.isEmpty())
        { 
            for(DeliveryDeltaWebservice.DeliveryItem item : DeliveryItems)
            {
                keyDeliveryItemMap.put(deliveryERPID + item.doLineItemNo, item); 
            }
            
            system.debug('keyDeliveryItemMap '+keyDeliveryItemMap);
            
            for(DeliveryDeltaWebservice.DeliveryItem item : DeliveryItems)
            {
                allDeliveryOrderERPIds.add(item.orderERPID);
            }
            
            allOrderItems = [SELECT Id, Line_Item_No__c, OrderId, Order.ERP_Id__c FROM OrderItem WHERE Order.ERP_Id__c IN: allDeliveryOrderERPIds];
            
            if (!allOrderItems.isEmpty())
            {
                system.debug('allOrderItems '+allOrderItems);
                for(DeliveryDeltaWebservice.DeliveryItem deliveryItem : DeliveryItems)
                {
                    validatedItems = false;
                    for(OrderItem orderItem : allOrderItems)
                    {
                        if(deliveryItem.orderERPID == orderItem.Order.ERP_Id__c && deliveryItem.orderLineItemNo == orderItem.Line_Item_No__c)
                        {
                            validatedItems = true;
                            orderItemsMap.put(deliveryItem.orderERPID + deliveryItem.orderLineItemNo, orderItem.Id);
                            break;
                        }
                    }
                    
                    if(validatedItems == false)
                    {
                        result.errorMessage = 'Cannot find OrderItem No. '+ deliveryItem.orderLineItemNo+' orderERPID: '+deliveryItem.orderERPID+ ' on '+ deliveryERPID;
                        createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
                    }
                }
            }
            else if(DeliveryItems.isEmpty()) 
            {
                validatedItems = true; 
            }
            
            if(validatedItems == true)
            {
                system.debug(Deliveries);
                Savepoint sp = Database.setSavepoint(); 
                //-----------Update Delivery__c------------------//
                Delivery__c delivery = new Delivery__c();
                delivery.Id = Deliveries[0].Id;
                delivery.SAP_Delivery_Order_No__c = deliveryERPID;
                delivery.Tracking_No__c = trackingNo;
                delivery.Planned_Good_Issue_Date__c = plannedGIDate;
                delivery.Actual_Goods_Issue_Date__c = actualGIDate;
                delivery.Loading_Date__c = loadingDate;
                delivery.Picking_Date__c = pickingDate;
                if(transPlanningDate == date.valueOf('0002-11-30')) delivery.Transportation_Plan_Date__c = null;
                else delivery.Transportation_Plan_Date__c = transPlanningDate;
                delivery.Street__c = shipToStreet;
                delivery.City__c = shipToCity;
                delivery.State__c = ShipToState;
                delivery.Postal_Code__c = shipToPostalCode;
                delivery.Country__c = shipToCountry;
                delivery.Delivery_Date__c = deliveryDate;
                delivery.Document_Date__c = documentDate;
                delivery.Sales_Organization__c = saleOrgCode;
                if(!shipTo.isEmpty()) delivery.Ship_To__c = shipTo[0].Id; // if empty, leave it blank
                delivery.Account__r = new Account(ERP_Id__c = accountERPID);
                delivery.Carrier_Name__c  = carrierName;
                
                
                if(BillingStatus != '' && BillingStatus != 'A')
                {
                    delivery.Status__c = 'Billing';
                    delivery.Status_Detail__c = BillingStatus;
                }
                else if(proofOfDeliveryStatus != '' && proofOfDeliveryStatus != 'A')
                {
                    delivery.Status__c = 'Proof Of Delivery';
                    delivery.Status_Detail__c = proofOfDeliveryStatus;
                }
                else if(goodIssuedStatus != '' && goodIssuedStatus != 'A')
                {
                    delivery.Status__c = 'Goods Issued';
                    delivery.Status_Detail__c = goodIssuedStatus;
                }
                else if(packingStatus != '' && packingStatus != 'A')
                {
                    delivery.Status__c = 'Packing';
                    delivery.Status_Detail__c = packingStatus;
                }
                else if(pickingStatus != '' && pickingStatus != 'A')
                {
                    delivery.Status__c = 'Picking';
                    delivery.Status_Detail__c = pickingStatus;
                }
                else
                {
                    delivery.Status__c = 'Delivery Created';
                    delivery.Status_Detail__c = null;
                }
                
                system.debug('Update Delivery '+delivery);
                Database.SaveResult deliveryResult = Database.update(delivery, false);
                if (deliveryResult.isSuccess())
                {
                    deliveryId = deliveryResult.getId();
                    System.debug('Delivery updated successfully: ' + deliveryId);
                    //-----------Update Deliver Line Items------------------//
                    
                    if(!DeliveryItems.isEmpty())
                    {
                        for(DeliveryDeltaWebservice.DeliveryItem item : DeliveryItems)
                        {                  
                            System.debug('item : ' + item);
                            Boolean found = false;
                            allDeliveryOrderERPIds.add(item.orderERPID);
                            
                            Delivery_Product__c deliveryProduct = new Delivery_Product__c();
                            deliveryProduct.Order_Item_No__c = item.orderLineItemNo;
                            deliveryProduct.Order_Product__c = orderItemsMap.get(item.orderERPID + item.orderLineItemNo);
                            deliveryProduct.Delivery__c = deliveryId;
                            deliveryProduct.DO_Item_No__c = item.doLineItemNo;
                            deliveryProduct.Product_ID__c  = item.materialNumber;
                            deliveryProduct.Product_Description__c  = item.materialDescription;
                            deliveryProduct.Delivery_Qty__c = item.deliveryQuantity;
                            deliveryProduct.Delivery_Qty_UOM__c = item.uom;
                            deliveryProduct.Net_Weight__c = item.netWeight;
                            deliveryProduct.Gross_Weight__c = item.grossWeight;
                            deliveryProduct.Weight_Unit__c = item.weightUnit;
                            deliveryProduct.Planned_Goods_Issue_Date__c = plannedGIDate;
                            deliveryProduct.Actual_Goods_Issue_Date__c = actualGIDate;
                            deliveryProduct.Delivery_Item_ID__c = deliveryERPID + item.doLineItemNo + item.orderERPID + item.orderLineItemNo;
                            
                            if(item.BillingStatus != '' && item.BillingStatus != 'A')
                            {
                                deliveryProduct.Item_Status__c = 'Billing';
                                deliveryProduct.Item_Status_Detail__c = item.BillingStatus;
                            }
                            else if(item.proofOfDeliveryStatus != '' && item.proofOfDeliveryStatus != 'A')
                            {
                                deliveryProduct.Item_Status__c = 'Proof Of Delivery';
                                deliveryProduct.Item_Status_Detail__c = item.proofOfDeliveryStatus;
                            }
                            else if(item.GoodIssuedStatus != '' && item.GoodIssuedStatus != 'A')
                            {
                                deliveryProduct.Item_Status__c = 'Goods Issued';
                                deliveryProduct.Item_Status_Detail__c = item.GoodIssuedStatus;
                            }
                            else if(item.PackingStatus != '' && item.PackingStatus != 'A')
                            {
                                deliveryProduct.Item_Status__c = 'Packing';
                                deliveryProduct.Item_Status_Detail__c = item.PackingStatus;
                            }
                            else if(item.PickingStatus != '' && item.PickingStatus != 'A')
                            {
                                deliveryProduct.Item_Status__c = 'Picking';
                                deliveryProduct.Item_Status_Detail__c = item.PickingStatus;
                            }
                            else
                            {
                                deliveryProduct.Item_Status__c = 'Delivery Created';
                                deliveryProduct.Item_Status_Detail__c = null;
                            }
                            
                            deliveryProducts.add(deliveryProduct);
                            
                        }
                        
                        system.debug(deliveryProducts);
                        Schema.SObjectField ftoken = Delivery_Product__c.Fields.Delivery_Item_ID__c;
                        Database.UpsertResult[] deliveryItemResultList = Database.upsert(deliveryProducts,ftoken,false);
                        for (Database.UpsertResult sr : deliveryItemResultList) 
                        {
                            if (sr.isSuccess())
                            {
                                successDeliveryProductIds.add(sr.getId());
                                System.debug('DeliveryItems updated successfully: ' + sr.getId());
                            }
                            else
                            {              
                                for(Database.Error err : sr.getErrors())
                                {                 
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('DeliveryItems fields that affected this error: ' + err.getFields());
                                    result.errorMessage = 'Create DeliveryItems '+err.getStatusCode() + ': ' + err.getMessage();
                                }
                                Database.rollback(sp);
                                createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
                            }
                        }
                        
                        if(successDeliveryProductIds.size() == deliveryProducts.size())
                        {
                            
                            List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
                            List<Delivery_Product__c> deliveryItemsToDelete = new List<Delivery_Product__c>();
                            List<Delivery_Product__c> successDeliveryProducts = [SELECT Id, Order_Product__c, Order_Product__r.Remaining_Quantity__c, Delivery__r.Document_Date__c, Actual_Goods_Issue_Date__c  
                                                                                 FROM Delivery_Product__c WHERE Id IN: successDeliveryProductIds];
                            
                            if(!keyDeliveryItemMap.isEmpty())
                            {
                                for(Delivery_Product__c dItem : Deliveries[0].Delivery_Orders__r)
                                {
                                    //system.debug('dItem.Order_Product__r.Order.ERP_Id__c + dItem.Order_Item_No__c '+dItem.Order_Product__r.Order.ERP_Id__c + dItem.Order_Item_No__c);
                                    if(!keyDeliveryItemMap.containsKey(dItem.Delivery__r.SAP_Delivery_Order_No__c + dItem.Do_Item_No__c))
                                    {
                                        deliveryItemsToDelete.add(dItem);
                                        system.debug('Delete ID '+dItem.Id);
                                    }
                                }  
                            }
                            
                            system.debug('deliveryItemsToDelete size '+deliveryItemsToDelete.size());
                            
                            for(Delivery_Product__c dePro : successDeliveryProducts)
                            {
                                if(dePro.Order_Product__r.Remaining_Quantity__c == 0)
                                {
                                    OrderItem item = new OrderItem();
                                    item.Id = dePro.Order_Product__c;
                                    item.Actual_Goods_Issue_Date__c = dePro.Actual_Goods_Issue_Date__c;
                                    item.Delivery_Creation_Date__c  = dePro.Delivery__r.Document_Date__c;
                                    orderItemsToUpdate.add(item);
                                }  
                            }
                            
                            system.debug('orderItemsToUpdate '+orderItemsToUpdate);
                            
                            List<Order> ordersToUpdate = [SELECT Id, Order_Updated_Date__c FROM Order WHERE ERP_Id__c IN: allDeliveryOrderERPIds];
                            for(Order order : ordersToUpdate)
                            {
                                order.Order_Updated_Date__c = DateTime.now();
                            }
                            system.debug('ordersToUpdate '+ordersToUpdate);
                            
                            try{
                                if(!deliveryItemsToDelete.isEmpty()) delete deliveryItemsToDelete;
                                update orderItemsToUpdate;
                                update ordersToUpdate;
                                result.success = true;
                            }
                            catch (DmlException e)
                            {
                                result.errorMessage = e.getMessage() + ': ' + e.getLineNumber();
                                System.debug(result.errorMessage);
                                Database.rollback(sp);
                                createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
                            }
                        }
                    }
                    else
                    {
                        if(!Deliveries[0].Delivery_Orders__r.isEmpty())
                        {
                            system.debug('All Delivery Items will be deleted : '+ Deliveries[0].Delivery_Orders__r.size()); 
                            delete Deliveries[0].Delivery_Orders__r;
                        }
                    }
                }
                else // Create Delivery Fail
                {              
                    for(Database.Error err : deliveryResult.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Delivery fields that affected this error: ' + err.getFields());
                        result.errorMessage = 'Create Delivery '+err.getStatusCode() + ': ' + err.getMessage();
                    }
                    Database.rollback(sp);
                    createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
                }
            }
            else createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
        }
        else
        {
            result.errorMessage = 'Delivery : '+deliveryERPID+' is not found';
            createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
        }
        
        
        System.debug('ReturnValue '+result);
        return result;  
    }
    
    public static void createErrorMessage(String errMessage, String deliveryERPID, String accountERPID)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = 'Delivery Order Delta';
            mError.Error_Message_Detail__c = errMessage;
            mError.Delivery_ERP_ID__c = deliveryERPID;
            mError.Account_ERP_ID__c = accountERPID;
            insert mError;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}