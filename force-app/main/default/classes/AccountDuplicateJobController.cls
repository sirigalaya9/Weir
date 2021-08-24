public without sharing class AccountDuplicateJobController 
{
    public AccountDuplicateJobController(ApexPages.StandardSetController controller) 
    {
    }

    public PageReference runJob()
    {
        Boolean hasPermission = FeatureManagement.checkPermission('Duplicate_Job');
        if (hasPermission)
        {
            DuplicateJob batch = new DuplicateJob('Account');        
            Database.executeBatch(batch, 50);        
            PageReference pr = new PageReference('/0GK');
            pr.setRedirect(true);
            return pr;
        }
        else 
        {
            return null;
        }
    }

}