public with sharing class SharepointActionController 
{
    @AuraEnabled
    public static Boolean userHasAccess(Id recordId)
    {
        UserRecordAccess access = [SELECT RecordId, MaxAccessLevel FROM UserRecordAccess WHERE RecordId = :recordId AND UserId = :System.UserInfo.getUserId()];
        if (access.MaxAccessLevel.equalsIgnoreCase('All') || 
            access.MaxAccessLevel.equalsIgnoreCase('Edit') || 
            access.MaxAccessLevel.equalsIgnoreCase('Transfer'))            
        {
            return true;
        }
        else 
        {
            return false;    
        }       
    }
}