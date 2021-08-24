public without sharing class DirectIndustryAPIController
{
    private static final Direct_Industry__c setting = Direct_Industry__c.getOrgDefaults();

    public DirectIndustryAPIController(ApexPages.StandardSetController controller) 
    {
        
    }

    public PageReference runSync()
    {        
        DirectIndustryAPIController.sync();
        return new ApexPages.Action('{!List}').invoke();
    }

    public static Boolean canRun()
    {
        if (setting.Last_Run_Start_Date__c == null)
            return true;
        else if (setting.Last_Run_End_Date__c == null || setting.Last_Run_End_Date__c < setting.Last_Run_Start_Date__c)
            return false;
        else 
            return true;        
    }    

    public static void sync()
    {
        if (DirectIndustryAPIController.canRun())
        {            
            setting.Last_Run_Start_Date__c = System.now();
            Date startDate = setting.Start_Date__c == null ? System.today() : setting.Start_Date__c;
            Date endDate = setting.End_Date__c == null ? System.today() : setting.End_Date__c;
            if (startDate == endDate && !System.isScheduled())
            {                
                DirectIndustryAPIController.exportLeads(endDate);
                setting.Last_Run_End_Date__c = System.now();
                setting.Start_Date__c = System.today();
                setting.End_Date__c = null;                
            }
            else if (startDate <= endDate)
            {                                                
                Database.executeBatch(new DirectIndustryAPISchedulableBatch(startDate, endDate), 1);                   
            }
            update setting;
        }
        else
        {
            DirectIndustryAPIController.logRequest(null, null, 'Cannot run sync, a sync is already in-progress', true);
        }
    }

    public static void exportLeads(Date dt)
    {        
        String resultMessage = '';
        Boolean error = false;
        String endPoint = '';
        String body = '';
        try
        {
            if (setting.Active__c == false)
            {
                CalloutException e = new CalloutException();
                e.setMessage('Direct Industry is not activated in custom setting.');
                throw e;
            }            
            endPoint = DirectIndustryAPIService.constructRequest(dt, dt);
            body = DirectIndustryAPIService.getRequest(endPoint);        
            List<Lead> leads = DirectIndustryAPIService.parseResponse(body);            
            for (Lead lead : leads)
            {
                lead.LeadSource = 'Direct Industry';
                if (setting.Live_Mode__c == false)
                {
                    lead.Phone = lead.Phone != null ? (lead.Phone + '.invalid') : null;
                    lead.Email = lead.Email != null ? (lead.Email + '.invalid') : null;
                }
            }              

            Database.SaveResult[] saveResults = Database.insert(leads, false);
            for (Integer i=0; i<leads.size(); i++)
            {
                Database.SaveResult sr = saveResults.get(i);
                Lead lead = leads.get(i);                
                resultMessage += 'Direct Industry Visitor Id: ' + lead.Direct_Industry_Visitor_Id__c + ' Request Id: ' + lead.Direct_Industry_Request_Id__c;
                resultMessage += '\n';
                if (!sr.isSuccess()) 
                {              
                    error = true;
                    for(Database.Error err : sr.getErrors())
                    {                 
                        resultMessage += 'Error: ' + err.getStatusCode() + ': ' + err.getMessage() + '.';
                        if (err.getFields() != null && err.getFields().size() > 0)
                        {
                            resultMessage += ' Fields that affected this error: ';
                            for (String field : err.getFields())
                            {
                                resultMessage += field;
                            }                            
                        }                         
                    }
                    resultMessage += '\n\n';
                }
                else
                {                    
                    resultMessage += 'Success: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + sr.getId();
                    resultMessage += '\n\n';
                }
            }                        
        }
        catch (Exception e)
        {
            resultMessage = e.getMessage() + '\n' + e.getStackTraceString();
            error = true;
        }
        DirectIndustryAPIController.logRequest(endPoint, body, resultMessage, error);
    }

    public static Id logRequest(String request, String response, String logMessage, Boolean error)
    {        
        if (setting.Log_Errors_Only__c == true && error == false)
        {
            return null;
        }
        Direct_Industry_Log__c log = new Direct_Industry_Log__c();        
        log.Request__c = request?.abbreviate(100000);
        log.Response__c = response?.abbreviate(100000);
        log.Log_Message__c = logMessage?.abbreviate(100000);
        log.Error__c = error;
        insert log;
        return log.Id;
    }    
}