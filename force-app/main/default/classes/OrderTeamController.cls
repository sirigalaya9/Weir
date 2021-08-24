public class OrderTeamController 
{
    public static final String SHARING_REASON = 'Manual';
    public static final String ACCESS_READ = 'Read';
    
    public static void createShares(List<Order_Team__c> OrderTeams)
    {                
        //If current user is not Order owner or above owner in role hierarchy then need to prevent them from managing team
        Map<Id, UserRecordAccess> userAccessMap = new Map<Id, UserRecordAccess>();
        for (Order_Team__c OrderTeam : OrderTeams)
        {
            userAccessMap.put(OrderTeam.Order__c, null);
        }
        List<UserRecordAccess> userAccesses = [SELECT RecordId, HasEditAccess, HasTransferAccess, MaxAccessLevel FROM UserRecordAccess 
                                               WHERE UserId = :System.UserInfo.getUserId() AND RecordId IN :userAccessMap.keySet()];
        for (UserRecordAccess userAccess : userAccesses)
        {            
			userAccessMap.put(userAccess.RecordId, userAccess);
        }

        //Get OWD of Order
        //Organization org = [Select DefaultOrderAccess from Organization];
            
        List<OrderShare> OrderShares = new List<OrderShare>();
        for (Order_Team__c OrderTeam : OrderTeams)
        {            
            UserRecordAccess userAccess = userAccessMap.get(OrderTeam.Order__c);            
            if (!userAccess.MaxAccessLevel.equalsIgnoreCase('All')) //Only owners and users above Order owner in role hierarchy have 'All', team members have 'Edit'
            {
                OrderTeam.addError('insufficient access rights on object id');
                continue;
            }        
            //if (org.DefaultOrderAccess.equalsIgnoreCase(ACCESS_READ) && OrderTeam.Order_Access__c.equalsIgnoreCase(ACCESS_READ))
            if (OrderTeam.Order_Access__c.equalsIgnoreCase(ACCESS_READ))
            {
                continue;
            }
            OrderShare OrderShare = new OrderShare();
            OrderShare.OrderAccessLevel = OrderTeam.Order_Access__c;
            OrderShare.UserOrGroupId = OrderTeam.Team_Member__c;
            OrderShare.OrderId = OrderTeam.Order__c;
            OrderShare.RowCause = SHARING_REASON;
            OrderShares.add(OrderShare);
        }
        insert OrderShares;        
    }
    
    public static void deleteShares(List<Order_Team__c> OrderTeams)
    {        
        //If current user is not Order owner or above owner in role hierarchy then need to prevent them from managing team
        Map<Id, UserRecordAccess> userAccessMap = new Map<Id, UserRecordAccess>();
        for (Order_Team__c OrderTeam : OrderTeams)
        {
			userAccessMap.put(OrderTeam.Order__c, null);            
        }
        List<UserRecordAccess> userAccesses = [SELECT RecordId, HasEditAccess, HasTransferAccess, MaxAccessLevel FROM UserRecordAccess 
                                               WHERE UserId = :System.UserInfo.getUserId() AND RecordId IN :userAccessMap.keySet()];
        for (UserRecordAccess userAccess : userAccesses)
        {            
			userAccessMap.put(userAccess.RecordId, userAccess);
        }
        
        List<Id> userIds = new List<Id>();        
        for (Order_Team__c OrderTeam : OrderTeams)
        {
            UserRecordAccess userAccess = userAccessMap.get(OrderTeam.Order__c);            
            if (!userAccess.MaxAccessLevel.equalsIgnoreCase('All')) //Only owners and users above Order owner in role hierarchy have 'All', team members have 'Edit'
            {
                OrderTeam.addError('insufficient access rights on object id');                
                continue;
            }
            userIds.add(OrderTeam.Team_Member__c);
        }
        
        List<OrderShare> OrderShares = [SELECT Id FROM OrderShare WHERE UserOrGroupId IN :userIds AND OrderId IN :userAccessMap.keySet() AND RowCause = :SHARING_REASON];
        delete OrderShares;         
    }
    
    @AuraEnabled
    public static void createOrUpdateOrderTeam(List<Order_Team__c> OrderTeams)
    {
        System.debug(OrderTeams);
        
        Map<Id, Order_Team__c> OrderTeamMap = new Map<Id, Order_Team__c>();
        Id OrderId;
        for(Order_Team__c OrderTeam : OrderTeams)
        {
            OrderTeamMap.put(OrderTeam.Team_Member__c, OrderTeam);
            OrderId = OrderTeam.Order__c;
        }
        
        {
            List<Order> ownedOrders = [SELECT Id, (SELECT Team_Member__c FROM Order_Teams__r WHERE Team_Member__c IN :OrderTeamMap.keySet()) FROM Order WHERE Id = :OrderId];
            List<Order_Team__c> newOrderTeams = new List<Order_Team__c>();
            List<Order_Team__c> existingOrderTeams = new List<Order_Team__c>();
            List<Id> ownedOrderIds = new List<Id>();
            for (Order ownedOrder : ownedOrders)
            {
                Set<Id> teamMemberExisting = new Set<Id>();
                if (ownedOrder.Order_Teams__r != NULL && ownedOrder.Order_Teams__r.size() > 0)
                {                        
                    for (Order_Team__c existingOrderTeam : ownedOrder.Order_Teams__r)
                    {
                        if (OrderTeamMap.containsKey(existingOrderTeam.Team_Member__c))
                        {
                            Order_Team__c OrderTeam = OrderTeamMap.get(existingOrderTeam.Team_Member__c);
                            existingOrderTeam.Order_Access__c = OrderTeam.Order_Access__c;
                            existingOrderTeam.Team_Role__c = OrderTeam.Team_Role__c;
                            existingOrderTeams.add(existingOrderTeam);
                            teamMemberExisting.add(existingOrderTeam.Team_Member__c);
                        }
                    }                       
                }
                for (Id teamMemberId : OrderTeamMap.keySet())
                {
                    if (!teamMemberExisting.contains(teamMemberId))
                    {
                        Order_Team__c OrderTeam = OrderTeamMap.get(teamMemberId);
                        Order_Team__c newOrderTeam = new Order_Team__c(Order__c = ownedOrder.Id);
                        newOrderTeam.Team_Member__c = teamMemberId;
                        newOrderTeam.Order_Access__c = OrderTeam.Order_Access__c;
                        newOrderTeam.Team_Role__c = OrderTeam.Team_Role__c;
                        newOrderTeams.add(newOrderTeam);
                    }                          
                }
            }
            insert newOrderTeams;
            update existingOrderTeams;
        }        
	}
    
    @AuraEnabled
    public static boolean createOrUpdateDefaultOrderTeam(List<Default_Order_Team__c> defaultOrderTeams, Id userId, boolean updateOrderTeam)
    {        
        Map<Id, Default_Order_Team__c> allDefaultOrderTeamMap = new Map<Id, Default_Order_Team__c>();   
        Map<Id, Default_Order_Team__c> newDefaultOrderTeamMap = new Map<Id, Default_Order_Team__c>();
        for (Default_Order_Team__c item : defaultOrderTeams)
        {
            if (item.Team_Member__c == NULL)
            {
                continue;
            }
            if (item.Team_Member__c != NULL && (item.Team_Role__c == null || item.Order_Access__c == null))
            {
                return false;
            }            
            allDefaultOrderTeamMap.put(item.Team_Member__c, item); 
            newDefaultOrderTeamMap.put(item.Team_Member__c, item);
        }
        if (allDefaultOrderTeamMap.size() > 0)
        {    
            List<Default_Order_Team__c> existingDefaultOrderTeams = [SELECT Team_Member__c FROM Default_Order_Team__c WHERE Team_Member__c IN :allDefaultOrderTeamMap.keySet() AND OwnerId = :userId];
            List<Default_Order_Team__c> newDefaultOrderTeams = new List<Default_Order_Team__c>();
            for (Default_Order_Team__c item : existingDefaultOrderTeams)
            {
                Default_Order_Team__c matchedDefaultOrderTeam = allDefaultOrderTeamMap.get(item.Team_Member__c);
                item.Order_Access__c = matchedDefaultOrderTeam.Order_Access__c;
                item.Team_Role__c = matchedDefaultOrderTeam.Team_Role__c;
                newDefaultOrderTeamMap.remove(item.Team_Member__c);
            }
            newDefaultOrderTeams = newDefaultOrderTeamMap.values();
            insert newDefaultOrderTeams;             
            update existingDefaultOrderTeams;
            if (updateOrderTeam == true)
            {
                List<Order> ownedOrders = [SELECT Id, (SELECT Team_Member__c FROM Order_Teams__r WHERE Team_Member__c IN :allDefaultOrderTeamMap.keySet()) FROM Order WHERE OwnerId =: userId];
                List<Order_Team__c> newOrderTeams = new List<Order_Team__c>();
                List<Order_Team__c> existingOrderTeams = new List<Order_Team__c>();
                List<Id> ownedOrderIds = new List<Id>();
                for (Order ownedOrder : ownedOrders)
                {
                    Set<Id> teamMemberExisting = new Set<Id>();
                    if (ownedOrder.Order_Teams__r != NULL && ownedOrder.Order_Teams__r.size() > 0)
                    {                        
                        for (Order_Team__c existingOrderTeam : ownedOrder.Order_Teams__r)
                        {
                            if (allDefaultOrderTeamMap.containsKey(existingOrderTeam.Team_Member__c))
                            {
                                Default_Order_Team__c defaultOrderTeam = allDefaultOrderTeamMap.get(existingOrderTeam.Team_Member__c);
                                existingOrderTeam.Order_Access__c = defaultOrderTeam.Order_Access__c;
                                existingOrderTeam.Team_Role__c = defaultOrderTeam.Team_Role__c;
                                existingOrderTeams.add(existingOrderTeam);
                                teamMemberExisting.add(existingOrderTeam.Team_Member__c);
                            }
                        }                       
                    }
                    for (Id teamMemberId : allDefaultOrderTeamMap.keySet())
                    {
                        if (!teamMemberExisting.contains(teamMemberId))
                        {
                            Default_Order_Team__c defaultOrderTeam = allDefaultOrderTeamMap.get(teamMemberId);
                            Order_Team__c newOrderTeam = new Order_Team__c(Order__c = ownedOrder.Id);
                            newOrderTeam.Team_Member__c = teamMemberId;
                            newOrderTeam.Order_Access__c = defaultOrderTeam.Order_Access__c;
                            newOrderTeam.Team_Role__c = defaultOrderTeam.Team_Role__c;
                            newOrderTeams.add(newOrderTeam);
                        }                          
                    }
                }
                insert newOrderTeams;
                update existingOrderTeams;
            }            
        }        
        return true;
    }
}