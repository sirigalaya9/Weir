public class OrderContactRolesController 
{
    @AuraEnabled
    public static List<Contact> fetchData(String searchKeyWord, Id parentId)
    {
        list<Contact> contacts = new list<Contact>();
        List<List<sObject>> searchList;
        if (parentId != null){
            if (searchKeyWord == null) searchKeyWord ='';
            String searchKey = '%'+ searchKeyword + '%';
            Order ord = [SELECT AccountId FROM Order WHERE Id =: parentId];
            String q = 'SELECT Id, Name, AccountId, Account.Name, Phone, Email, Owner.Alias FROM Contact WHERE (Name LIKE \''+searchKey+'\''+
                ' OR Phone LIKE \''+searchKey+'\''+' OR Email LIKE \''+searchKey+'\')';
            if (searchKeyWord == '')
                q = q + 'AND AccountId =\''+ord.AccountId+'\'';
            q = q +' ORDER BY Name ASC';
            //q = q +' LIMIT 30';
            //system.debug('q : '+q);
            for(Contact con : Database.query(q)){
                contacts.add(con);
            }
        }
        return contacts;
    }
    
    @AuraEnabled
    public static Contact fetchDataById(Id recordId)
    {
        return [SELECT Id, Name, AccountId, Account.Name, Phone, Email, Owner.Alias FROM Contact WHERE Id = :recordId];
    }    
    
    @AuraEnabled
    public static List<Order_Contact_Role__c> getPrimaryContact(Id parentId)
    {
        list<Order_Contact_Role__c> orderContactRoles = new list<Order_Contact_Role__c>();
        if (parentId != null){
            orderContactRoles = [SELECT Id, Contact__r.Name, Contact__c, Is_Primary__c, Role__c FROM Order_Contact_Role__c 
                                   WHERE Order__c =: parentId AND Is_Primary__c = TRUE];
        }

        return orderContactRoles;
    }
    
    @AuraEnabled
    public static List<Order_Contact_Role__c> getOrderContactRoles(Id parentId)
    {
        list<Order_Contact_Role__c> orderContactRoles = new list<Order_Contact_Role__c>();
        if (parentId != null){
            orderContactRoles = [SELECT Id, AccountName__c, ContactName__c, Contact__r.Account.Name, Contact__r.Name, Contact__c, Is_Primary__c, Role__c FROM Order_Contact_Role__c 
                                   WHERE Order__c =: parentId ORDER BY ContactName__c];
        }
        
        if(!orderContactRoles.isEmpty())
        {
            for(Order_Contact_Role__c pro : orderContactRoles){
                system.debug(pro.Contact__r.Name); 
            }  
        }
        return orderContactRoles;
    }
    
    @AuraEnabled
    public static void createOrUpdateOrderContactRole(List<Order_Contact_Role__c> ordContactRoles)
    {
        System.debug(ordContactRoles);
        
        Map<Id, Order_Contact_Role__c> orderContactRolesMap = new Map<Id, Order_Contact_Role__c>();
        Id OrderId;
        for(Order_Contact_Role__c orderContactRole : ordContactRoles)
        {
            orderContactRolesMap.put(orderContactRole.Id, orderContactRole);
            OrderId = orderContactRole.Order__c;
        }
        
        {
            List<Order> ownedOrders = [SELECT Id, (SELECT Id, Contact__c FROM Order_Contact_Roles__r
                                                          WHERE Id IN :orderContactRolesMap.keySet()) 
                                              FROM Order WHERE Id = :OrderId];
            List<Order_Contact_Role__c> newOrderContactRoles = new List<Order_Contact_Role__c>();
            List<Order_Contact_Role__c> existingOrderContactRoles = new List<Order_Contact_Role__c>();
            List<Id> ownedOrderIds = new List<Id>();
            for (Order ownedOrder : ownedOrders)
            {
                Set<Id> contactExisting = new Set<Id>();
                if (ownedOrder.Order_Contact_Roles__r != NULL && ownedOrder.Order_Contact_Roles__r.size() > 0)
                {                        
                    for (Order_Contact_Role__c existingOrderContactRole : ownedOrder.Order_Contact_Roles__r)
                    {
                        if (orderContactRolesMap.containsKey(existingOrderContactRole.Id))
                        {
                            
                            Order_Contact_Role__c orderContactRole = orderContactRolesMap.get(existingOrderContactRole.Id);
                            system.debug('existing : '+orderContactRole.Contact__c);
                            existingOrderContactRole.Contact__c = orderContactRole.Contact__c;
                            existingOrderContactRole.Role__c = orderContactRole.Role__c;
                            existingOrderContactRole.Is_Primary__c = orderContactRole.Is_Primary__c;
                            existingOrderContactRoles.add(existingOrderContactRole);
                            contactExisting.add(existingOrderContactRole.Id);
                            system.debug('contactExisting : '+contactExisting);
                        }
                    }                       
                }
                for (Id RecordId : orderContactRolesMap.keySet())
                {
                    if (!contactExisting.contains(RecordId) || RecordId == null)
                    {
                        system.debug('RecordId : '+RecordId);                        
                        Order_Contact_Role__c orderContactRole = orderContactRolesMap.get(RecordId);
                        system.debug('New : '+orderContactRole.Contact__c);
                        Order_Contact_Role__c newOrderContactRole = new Order_Contact_Role__c(Order__c = ownedOrder.Id);
                        newOrderContactRole.Contact__c = orderContactRole.Contact__c;
                        newOrderContactRole.Role__c = orderContactRole.Role__c;
                        newOrderContactRole.Is_Primary__c = orderContactRole.Is_Primary__c;
                        newOrderContactRoles.add(newOrderContactRole);
                    }                          
                }
            }
            
            insert newOrderContactRoles;
            update existingOrderContactRoles;
        }        
    }

}