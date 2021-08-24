global class InvoiceCreationWebService
{    
    global class InvoiceItem
    {
        webservice Integer invoiceLineItemNo;
        webservice String deliveryERPID;
        webservice Integer doLineItemNo;
        webservice String orderERPID; 
        webservice Integer orderLineItemNo;
        webservice String materialNumber;
        webservice String materialDescription;
        webservice Integer billedQuantity;
        webservice Decimal unitPrice;
        webservice Decimal netValue;
        webservice Decimal charges;
        webservice Decimal taxAmount;
    }
    
    global class Results
    {
        webservice boolean success;
        webservice String errorMessage;
    }
    
    public static InvoiceCreationWebService.Results result =  new InvoiceCreationWebService.Results();
    
    webservice static InvoiceCreationWebService.Results InvoiceCreation(
        String deliveryERPID, String accountERPID, String invoiceERPID, Date billingDate , Decimal netValue, String invoiceCurrency, String customerPONumber,
        String incoterm1, String paymentTerm, Decimal taxAmount, Decimal totalAmount, String saleOrgCode, List<InvoiceItem> InvoiceItems)
        
    {
        Id invoiceId;
        Integer invoiceItemSuccess = 0;
        Map<String,Id> orderItemsMap = new Map<String,Id>();
        Map<String,Id> deliveryItemsMap = new Map<String,Id>();
        List<String> allOrderERPIds = new List<String>();
        List<String> allDeliveryERPIds = new List<String>();
        List<OrderItem> orderItems = new List<OrderItem>();
        List<Invoice_Item__c> invoiceItemList = new List<Invoice_Item__c>();
        List<Delivery_Product__c> deliveryProducts = new List<Delivery_Product__c>();
        result.success = false;
        Boolean validatedItems = false;
        List<OrderItem> allOrderItems;
        List<Delivery_Product__c> allDeliveryItems;
        
        if(!InvoiceItems.isEmpty())
        {
            for(InvoiceCreationWebService.InvoiceItem item : InvoiceItems)
            {
                if(item.orderERPID != null) allOrderERPIds.add(item.orderERPID);
                if(item.deliveryERPID != null) allDeliveryERPIds.add(item.deliveryERPID);
            }
            
            allOrderItems = [SELECT Id, Line_Item_No__c, OrderId, Order.ERP_Id__c FROM OrderItem WHERE Order.ERP_Id__c IN: allOrderERPIds];
            allDeliveryItems = [SELECT Id, DO_Item_No__c, Delivery__r.SAP_Delivery_Order_No__c  FROM Delivery_Product__c WHERE Delivery__r.SAP_Delivery_Order_No__c IN: allDeliveryERPIds];
            
            system.debug('allOrderItems '+allOrderItems);
            system.debug('allDeliveryItems '+allDeliveryItems);
            for(InvoiceCreationWebService.InvoiceItem InvoiceItem : InvoiceItems)
            {
                validatedItems = false;
                for(OrderItem orderItem : allOrderItems)
                {
                    if(InvoiceItem.orderERPID == orderItem.Order.ERP_Id__c && InvoiceItem.orderLineItemNo == orderItem.Line_Item_No__c)
                    {
                        validatedItems = true;
                        orderItemsMap.put(InvoiceItem.orderERPID + InvoiceItem.orderLineItemNo, orderItem.Id);
                        break;
                    }
                }
                
                for(Delivery_Product__c deliveryItem : allDeliveryItems)
                {
                    if(InvoiceItem.deliveryERPID == deliveryItem.Delivery__r.SAP_Delivery_Order_No__c && InvoiceItem.doLineItemNo == deliveryItem.DO_Item_No__c)
                    {
                        //validatedItems = true;
                        deliveryItemsMap.put(InvoiceItem.deliveryERPID + InvoiceItem.doLineItemNo, deliveryItem.Id);
                        break;
                    }
                }
                
                if(validatedItems == false)
                {
                    result.errorMessage = 'Cannot find OrderItem No. '+ InvoiceItem.orderLineItemNo+' orderERPID: '+InvoiceItem.orderERPID;
                    System.debug(result.errorMessage);
                    createErrorMessage(result.errorMessage, deliveryERPID, accountERPID, invoiceERPID);
                    break;
                }
            }
            
            system.debug('orderItemsMap : '+orderItemsMap);
            system.debug('deliveryItemsMap : '+deliveryItemsMap);
        }
        
        
        List<Delivery__c>  Deliveries = [SELECT Id, Status__c, Sales_Organization__c, 
                                         (SELECT Id, Delivery__c, Item_Status__c, Item_Status_Detail__c, Order_Product__c, Order_Product__r.Order.ERP_Id__c 
                                          FROM Delivery_Orders__r)  FROM Delivery__c WHERE SAP_Delivery_Order_No__c =: deliveryERPID];
        
        List<Account> soldTo = [SELECT Id FROM Account WHERE ERP_Id__c =: accountERPID LIMIT 1];
        system.debug('soldTo : '+soldTo);
        
        if (validatedItems == true){            
            Savepoint sp = Database.setSavepoint(); 
            //-----------Create Invoice__c------------------//
            Invoice__c invoice = new Invoice__c ();
            invoice.Billing_Date__c  = billingDate;
            invoice.Net_Value__c  = netValue;
            invoice.Sales_Organization__c  = saleOrgCode;
            invoice.ERP_ID__c  = invoiceERPID;
            invoice.CurrencyIsoCode = invoiceCurrency;
            if(!soldTo.isEmpty()) invoice.Sold_To__c = soldTo[0].Id; // if empty, leave it blank
            invoice.Customer_PO_Number__c  = customerPONumber;
            invoice.Payment_Term__c = paymentTerm;
            invoice.Incoterm_1__c = incoterm1;
            invoice.Tax_Amount__c = taxAmount;
            invoice.Total_Amount__c = totalAmount;
            system.debug('new invoice '+invoice);
            Database.SaveResult invoiceResult = Database.insert(invoice, false);
            if (invoiceResult.isSuccess())
            {
                invoiceId = invoiceResult.getId();
                System.debug('Invoice created successfully: ' + invoiceId);
                
                //-----------Create Invoice Line Items------------------//
                if (!InvoiceItems.isEmpty())
                { 
                    for(InvoiceCreationWebService.InvoiceItem item : InvoiceItems)
                    { 
                        Invoice_Item__c invoiceItem = new Invoice_Item__c();
                        invoiceItem.Invoice__c = invoiceId;
                        invoiceItem.Invoice_Item_No__c = item.invoiceLineItemNo;
                        if(deliveryItemsMap.get(item.deliveryERPID + item.doLineItemNo) != null)
                            invoiceItem.Delivery_Item__c = deliveryItemsMap.get(item.deliveryERPID + item.doLineItemNo);
                        if(orderItemsMap.get(item.orderERPID + item.orderLineItemNo) != null)
                            invoiceItem.Order_Item__c = orderItemsMap.get(item.orderERPID + item.orderLineItemNo);
                        invoiceItem.Billed_Quantity__c = item.billedQuantity;
                        invoiceItem.Material_Number__c = item.materialNumber;
                        invoiceItem.Product_Description__c = item.materialDescription;
                        invoiceItem.Net_Value__c = item.netValue;
                        invoiceItem.Unit_Price__c = item.unitPrice;
                        invoiceItem.Charges__c = item.charges;
                        invoiceItem.Tax_Amount__c = item.taxAmount;
                        invoiceItem.CurrencyIsoCode = invoiceCurrency;
                        invoiceItem.Invoice_Item_ID__c = invoiceERPID + item.invoiceLineItemNo;
                        invoiceItemList.add(invoiceItem);
                    }
                    
                    if(!invoiceItemList.isEmpty())
                    {
                        Database.SaveResult[] invoiceItemResultList = Database.insert(invoiceItemList, false);
                        for (Database.SaveResult sr : invoiceItemResultList) 
                        {
                            if (sr.isSuccess())
                            {
                                invoiceItemSuccess = invoiceItemSuccess+1;
                                System.debug('InvoiceItems created successfully: ' + sr.getId());
                            }
                            else
                            {              
                                for(Database.Error err : sr.getErrors())
                                {                 
                                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                    System.debug('InvoiceItems fields that affected this error: ' + err.getFields());
                                    result.errorMessage = 'Create InvoiceItems '+err.getStatusCode() + ': ' + err.getMessage();
                                }
                                Database.rollback(sp);
                                createErrorMessage(result.errorMessage, deliveryERPID, accountERPID, invoiceERPID);
                            }
                        }
                        
                        if(invoiceItemSuccess == invoiceItemList.size())
                        {
                            Delivery__c delivery;
                            if(deliveryERPID != null && deliveryERPID != '')
                            {                           
                                system.debug('Deliveries: true');
                                //-----------Update Delivery_Product__c------------------//
                                for(Delivery_Product__c dItem : Deliveries[0].Delivery_Orders__r)
                                {
                                    Delivery_Product__c deliveryProduct = new Delivery_Product__c();
                                    deliveryProduct.Id = dItem.Id;
                                    deliveryProduct.Item_Status__c = 'Billing';
                                    deliveryProduct.Item_Status_Detail__c = 'c';
                                    deliveryProducts.add(deliveryProduct);
                                    
                                    OrderItem oItem = new OrderItem();
                                    oItem.Id = dItem.Order_Product__c;
                                    oItem.Status__c = 'Billing';
                                    orderItems.add(oItem);
                                }
                                
                                delivery = new Delivery__c(Id = Deliveries[0].Id, Status__c = 'Billing');   
                            }
                            else
                            {
                                system.debug('Deliveries: false');
                                for(OrderItem item : allOrderItems)
                                {
                                    OrderItem oItem = new OrderItem();
                                    oItem.Id = item.Id;
                                    oItem.Status__c = 'Billing';
                                    oItem.Without_Delivery__c = true;
                                    orderItems.add(oItem);
                                }
                            }
                            
                            try
                            {
                                if(deliveryERPID != null && deliveryERPID != ''){
                                    update delivery;
                                    update deliveryProducts;
                                }
                                
                                update orderItems;
                                result.success = true;
                            }
                            catch (DmlException e)
                            {
                                System.debug(e.getMessage() + ': ' + e.getLineNumber());
                                createErrorMessage(result.errorMessage, deliveryERPID, accountERPID, invoiceERPID);
                            }
                        }
                        
                    }
                    
                }
                
            }
            else // Create Invoice Fail
            {              
                for(Database.Error err : invoiceResult.getErrors())
                {                 
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Invoice fields that affected this error: ' + err.getFields());
                    result.errorMessage = 'Create Invoice '+err.getStatusCode() + ': ' + err.getMessage();
                }
                Database.rollback(sp);
                createErrorMessage(result.errorMessage, deliveryERPID, accountERPID, invoiceERPID);
            }
        }
        /*else
{
System.debug('Cannot find Delivery : '+deliveryERPID);
result.errorMessage = 'Cannot find Delivery : '+deliveryERPID;
createErrorMessage(result.errorMessage, deliveryERPID, accountERPID, invoiceERPID);
}*/
        
        
        System.debug('ReturnValue '+result);
        return result;  
    }
    
    public static void createErrorMessage(String errMessage, String deliveryERPID, String accountERPID, String invoiceERPID)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = 'Invoice Creation';
            mError.Error_Message_Detail__c = errMessage;
            mError.Delivery_ERP_ID__c = deliveryERPID;
            mError.Account_ERP_ID__c = accountERPID;
            mError.Invoice_ERP_ID__c = invoiceERPID;
            insert mError;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}