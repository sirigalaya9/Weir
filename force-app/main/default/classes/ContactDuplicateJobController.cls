public without sharing class ContactDuplicateJobController 
{
    public ContactDuplicateJobController(ApexPages.StandardSetController controller) 
    {
    }

    public PageReference runJob()
    {
        Boolean hasPermission = FeatureManagement.checkPermission('Duplicate_Job');
        if (hasPermission)
        {        
            DuplicateJob batch = new DuplicateJob('Contact');        
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