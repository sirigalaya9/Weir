//System.schedule('DirectIndustryAPIJob', '0 0 * * * ?', new DirectIndustryAPISchedulableBatch() );
public without sharing class DirectIndustryAPISchedulableBatch implements Database.Batchable<Date>,Schedulable, Database.AllowsCallouts
{    
    private Date startDate;
    private Date endDate;

    public DirectIndustryAPISchedulableBatch() 
    {
        
    }    

    public DirectIndustryAPISchedulableBatch(Date startDt, Date endDt) 
    {
        startDate = startDt;
        endDate = endDt;
    }

    public void execute(SchedulableContext SC) 
    {
        DirectIndustryAPIController.sync();
    }    

    public Iterable<Date> start(Database.BatchableContext BC)
    {
        List<Date> dates = new List<Date>();        
        Date currentDate = startDate;
        while (currentDate <= endDate)
        {
            dates.add(currentDate);
            currentDate = currentDate.addDays(1);
        }
        return dates;
    }

    public void execute(Database.BatchableContext info, List<Date> dates)
    {
        //Batch size is always 1 so 
        Date dt = dates.get(0);
        DirectIndustryAPIController.exportLeads(dt);
    }

    public void finish(Database.BatchableContext info)
    {
        Direct_Industry__c setting = Direct_Industry__c.getOrgDefaults();
        setting.Last_Run_End_Date__c = System.now();
        setting.Start_Date__c = System.today();
        setting.End_Date__c = null;   
        update setting;        
    }
}