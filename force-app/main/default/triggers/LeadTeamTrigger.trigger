trigger LeadTeamTrigger on Lead_Team__c (before insert, before update, before delete) 
{

    if (Trigger.isInsert || Trigger.isUpdate)
    {
        LeadTeamController.createShares(Trigger.new);
    }
    else if (Trigger.isDelete)
    {
        LeadTeamController.deleteShares(Trigger.old);
    }
}