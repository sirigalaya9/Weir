trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update) 
{    
    if(trigger.isBefore)
    {
        if(Trigger.IsInsert)
        {
            OpportunityLineItemTriggerHandler.ValidateSalesOrgMaterialmethod(Trigger.New,'IsInsert');
        }
        else if(Trigger.IsUpdate)
        {
            OpportunityLineItemTriggerHandler.ValidateSalesOrgMaterialmethod(Trigger.New,'IsUpdate');
        }
    }
}