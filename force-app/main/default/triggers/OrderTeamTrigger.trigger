trigger OrderTeamTrigger on Order_Team__c (before insert, before update, before delete) 
{

    if (Trigger.isInsert || Trigger.isUpdate)
    {
        OrderTeamController.createShares(Trigger.new);
    }
    else if (Trigger.isDelete)
    {
        OrderTeamController.deleteShares(Trigger.old);
    }
}