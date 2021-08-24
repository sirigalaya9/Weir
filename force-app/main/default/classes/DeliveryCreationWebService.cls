global class DeliveryCreationWebService
{    
    global class DeliveryItem
    {
        webservice	Integer	doLineItemNo; //10,20,30
        webservice	Integer	orderLineItemNo; //10,20,30
        webservice	String	orderERPID; 
        webservice	String	materialNumber; //D009
        webservice	Decimal	deliveryQuantity; //10
        webservice	String	uom; //UNT
        webservice	Decimal	netWeight;
        webservice	Decimal	grossWeight;
        webservice	String	weightUnit;
        webservice	String	pickingStatus; //A,B,C
        webservice	String	packingStatus; //A,B,C
        webservice	String	materialDescription;
    }
    
    global class Results
    {
        webservice boolean success;
        webservice String errorMessage;
    }
    
    public static DeliveryCreationWebService.Results result =  new DeliveryCreationWebService.Results();
    
    webservice static DeliveryCreationWebService.Results DeliveryCreation(
        String deliveryERPID, String trackingNo, Date plannedGIDate, Date actualGIDate, Date loadingDate, Date pickingDate, Date transPlanningDate,
        String shipToStreet, String shipToCity, String ShipToState, String shipToPostalCode, String shipToCountry, String accountERPID,
        String pickingStatus, String packingStatus, Date deliveryDate, Date documentDate, String saleOrgCode, String ShipToERPID, String carrierName ,List<DeliveryItem> DeliveryItems)
        
    {
        Id deliveryId;
        Integer deliveryItemSuccess = 0;
        Map<String,Id> orderItemsMap = new Map<String,Id>();
        List<String> allDeliveryOrderERPIds = new List<String>();
        List<OrderItem> allOrderItems = new List<OrderItem>();
        List<Delivery_Product__c> deliveryProducts = new List<Delivery_Product__c>();
        result.success = false;
        Boolean validatedItems = false;
        
        if (!DeliveryItems.isEmpty())
        {
            
            for(DeliveryCreationWebService.DeliveryItem item : DeliveryItems)
            {
                allDeliveryOrderERPIds.add(item.orderERPID);
            }
            
            allOrderItems = [SELECT Id, Line_Item_No__c, OrderId, Order.ERP_Id__c FROM OrderItem WHERE Order.ERP_Id__c IN: allDeliveryOrderERPIds];
            
            if (!allOrderItems.isEmpty())
            {
                system.debug('allOrderItems '+allOrderItems);
                for(DeliveryCreationWebService.DeliveryItem deliveryItem : DeliveryItems)
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
            else
            {
                result.errorMessage = 'Cannot find Order ERP Id : '+ allDeliveryOrderERPIds;
                createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
            }
            
            
            List<Address__c> shipTo = [SELECT Id FROM Address__c WHERE ERP_Id__c =: shipToERPID LIMIT 1];
            system.debug('shipTo : '+shipTo);
            
            if (validatedItems == true)
            {
                Savepoint sp = Database.setSavepoint(); 
                //-----------Create Delivery__c------------------//
                Delivery__c delivery = new Delivery__c();
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
                
                system.debug('PackingStatus '+PackingStatus);
                system.debug('PickingStatus '+PickingStatus);
                if(PackingStatus != '' && PackingStatus != 'A')
                {
                    delivery.Status__c = 'Packing';
                    delivery.Status_Detail__c = PackingStatus;
                }
                else if(PickingStatus != '' && PickingStatus != 'A')
                {
                    delivery.Status__c = 'Picking';
                    delivery.Status_Detail__c = PickingStatus;
                }
                else
                {
                    delivery.Status__c = 'Delivery Created';
                    delivery.Status_Detail__c = null;
                }
                
                system.debug('new Delivery '+delivery);
                Database.SaveResult deliveryResult = Database.insert(delivery, false);
                if (deliveryResult.isSuccess())
                {
                    deliveryId = deliveryResult.getId();
                    System.debug('Delivery created successfully: ' + deliveryId);
                    //-----------Create Delivery Line Items------------------//
                    if (!orderItemsMap.isEmpty())
                    {
                        for(DeliveryCreationWebService.DeliveryItem item : DeliveryItems)
                        {
                            if(orderItemsMap.containsKey(item.orderERPID + item.orderLineItemNo))
                            {
                                system.debug('item PackingStatus '+item.PackingStatus);
                                system.debug('item PickingStatus '+item.PickingStatus);
                                Delivery_Product__c deliveryProduct = new Delivery_Product__c();
                                deliveryProduct.Delivery__c = deliveryId;
                                deliveryProduct.Order_Product__c = orderItemsMap.get(item.orderERPID + item.orderLineItemNo);
                                deliveryProduct.Order_Item_No__c = item.orderLineItemNo;
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
                                
                                if(item.PackingStatus != '' && item.PackingStatus != 'A')
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
                            /*else
{
result.errorMessage = 'Cannot find OrderItem No. : '+ item.orderLineItemNo+ ' on '+ item.orderERPID;
Database.rollback(sp);
createErrorMessage(result.errorMessage, deliveryERPID, accountERPID);
}*/
                        }
                        
                        if(!deliveryProducts.isEmpty()){
                            Database.SaveResult[] deliveryItemResultList = Database.insert(deliveryProducts, false);
                            for (Database.SaveResult sr : deliveryItemResultList) 
                            {
                                if (sr.isSuccess())
                                {
                                    deliveryItemSuccess = deliveryItemSuccess+1;
                                    System.debug('DeliveryItems created successfully: ' + sr.getId());
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
                            
                            if(deliveryItemSuccess == deliveryProducts.size())
                            {
                                result.success = true;
                                List<Order> orders = [SELECT Id, Order_Updated_Date__c FROM Order WHERE ERP_Id__c IN: allDeliveryOrderERPIds];
                                for(Order order : orders)
                                {
                                    order.Order_Updated_Date__c = DateTime.now();
                                }
                                system.debug('Update Order_Updated_Date__c '+orders);
                                update orders;
                            }
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
            result.errorMessage = 'There is no DeliveryItems';
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
            mError.Scenario__c = 'Delivery Order Creation';
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