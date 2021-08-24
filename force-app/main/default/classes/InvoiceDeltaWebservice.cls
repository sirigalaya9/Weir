global class InvoiceDeltaWebservice
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
    
    public static InvoiceDeltaWebservice.Results result =  new InvoiceDeltaWebservice.Results();
    
    webservice static InvoiceDeltaWebservice.Results InvoiceDelta(
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
        List<Delivery_Product__c> deliveryProducts = new List<Delivery_Product__c>();
        List<Invoice_Item__c> invoiceItemList = new List<Invoice_Item__c>();
        Map<String,InvoiceDeltaWebservice.InvoiceItem> keyInvoiceItemMap = new Map<String,InvoiceDeltaWebservice.InvoiceItem>();
        result.success = false;
        Boolean validatedItems = false;
        
        List<Invoice__c>  Invoices = [SELECT Id, Billing_Date__c, Net_Value__c, Sales_Organization__c, Sold_To__c, ERP_ID__c,
                                      (SELECT Id, Invoice_Item_No__c, Order_Item__c, Delivery_Item__c, 
                                       Invoice_Item_ID__c, Delivery_Item__r.Delivery__r.SAP_Delivery_Order_No__c, Delivery_Item__r.DO_Item_No__c, 
                                       Order_Item__r.Order.ERP_Id__c, Order_Item__r.Line_Item_No__c FROM Invoice_Items__r)
                                      FROM Invoice__c WHERE ERP_ID__c =: invoiceERPID];
        
        system.debug('accountERPID : '+accountERPID);
        List<Account> soldTo = [SELECT Id FROM Account WHERE ERP_Id__c =: accountERPID LIMIT 1];
        system.debug('soldTo : '+soldTo);
        
        if (!Invoices.isEmpty())
        {
            for(InvoiceDeltaWebservice.InvoiceItem item : InvoiceItems)
            {
                if(item.orderERPID != null) allOrderERPIds.add(item.orderERPID);
                if(item.deliveryERPID != null) allDeliveryERPIds.add(item.deliveryERPID);
            }
            
            List<OrderItem> allOrderItems = [SELECT Id, Line_Item_No__c, OrderId, Order.ERP_Id__c FROM OrderItem WHERE Order.ERP_Id__c IN: allOrderERPIds];
            List<Delivery_Product__c> allDeliveryItems = [SELECT Id, DO_Item_No__c, Delivery__r.SAP_Delivery_Order_No__c  FROM Delivery_Product__c WHERE Delivery__r.SAP_Delivery_Order_No__c IN: allDeliveryERPIds];
            
            
            system.debug('allOrderItems '+allOrderItems);
            system.debug('allDeliveryItems '+allDeliveryItems);
            for(InvoiceDeltaWebservice.InvoiceItem InvoiceItem : InvoiceItems)
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
            
            
            List<Delivery__c>  Deliveries = [SELECT Id, Status__c, Sales_Organization__c, 
                                             (SELECT Id, Delivery__c, Item_Status__c, Item_Status_Detail__c, Order_Product__c, Order_Product__r.Order.ERP_Id__c 
                                              FROM Delivery_Orders__r)  FROM Delivery__c WHERE SAP_Delivery_Order_No__c =: deliveryERPID];
            
            if (validatedItems == true)
            { 
                Savepoint sp = Database.setSavepoint(); 
                //-----------Create Invoice__c------------------//
                Invoice__c invoice = new Invoice__c ();
                invoice.Id = Invoices[0].Id;
                invoice.Billing_Date__c  = billingDate;
                invoice.Net_Value__c  = netValue;
                invoice.Sales_Organization__c  = saleOrgCode;
                invoice.ERP_ID__c  = invoiceERPID;
                invoice.CurrencyIsoCode = invoiceCurrency;
                if(!soldTo.isEmpty()) invoice.Sold_To__c = soldTo[0].Id;
                invoice.Customer_PO_Number__c  = customerPONumber;
                invoice.Payment_Term__c = paymentTerm;
                invoice.Incoterm_1__c = incoterm1;
                invoice.Tax_Amount__c = taxAmount;
                invoice.Total_Amount__c = totalAmount;
                
                system.debug('update invoice '+invoice);
                Database.SaveResult invoiceResult = Database.update(invoice, false);
                if (invoiceResult.isSuccess())
                {
                    invoiceId = invoiceResult.getId();
                    System.debug('Invoice updated successfully: ' + invoiceId);
                    
                    //-----------Update Invoice Line Items------------------//
                    if (!InvoiceItems.isEmpty())
                    { 
                        for(InvoiceDeltaWebservice.InvoiceItem item : InvoiceItems)
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
                            Schema.SObjectField ftoken = Invoice_Item__c.Fields.Invoice_Item_ID__c;
                            Database.UpsertResult[] invoiceItemResultList = Database.upsert(invoiceItemList,ftoken,false);
                            for (Database.UpsertResult sr : invoiceItemResultList) 
                            {
                                if (sr.isSuccess())
                                {
                                    invoiceItemSuccess = invoiceItemSuccess+1;
                                    System.debug('InvoiceItems updated successfully: ' + sr.getId());
                                }
                                else
                                {              
                                    for(Database.Error err : sr.getErrors())
                                    {                 
                                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                        System.debug('InvoiceItems fields that affected this error: ' + err.getFields());
                                        result.errorMessage = 'Update InvoiceItems '+err.getStatusCode() + ': ' + err.getMessage();
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
                                }
                            }
                        } 
                    } 
                }
                else // Update Invoice Fail
                {              
                    for(Database.Error err : invoiceResult.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Invoice fields that affected this error: ' + err.getFields());
                        result.errorMessage = 'Update Invoice '+err.getStatusCode() + ': ' + err.getMessage();
                    }
                    Database.rollback(sp);
                    createErrorMessage(result.errorMessage, deliveryERPID, accountERPID, invoiceERPID);
                }
                
            }
        }            
        System.debug('ReturnValue '+result);
        return result;  
        
    }
    
    public static void createErrorMessage(String errMessage, String deliveryERPID, String accountERPID, String invoiceERPID)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = 'Invoice Delta';
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