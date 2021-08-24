trigger AccountTrigger on Account (before delete) 
{    
    if (Trigger.isDelete)
    {
        AccountController.validateDelete(Trigger.old);
        AccountController.deleteChildRecords(Trigger.oldMap.keySet());
    }
}