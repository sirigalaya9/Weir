global class OpportunityNotificationschedulableBatch implements Database.Batchable<sObject>, schedulable {
    // add Database.Stateful above to make data transcend batches
    Date dateToday = System.today();
    Date dateWeek = System.today() +7 ;
    String stringToday = String.valueOf(dateToday);
    String stringWeek = String.valueOf(dateWeek);
    
    String query = 'SELECT Id, Name, CloseDate, Close_Date_Today__c, Close_Date_Week__c, IsClosed FROM Opportunity '+
        'WHERE (CloseDate ='+ stringToday+ ' OR CloseDate ='+ stringWeek +') AND IsClosed = false';
    List<opportunity> mOppToday = new List<opportunity>();
    List<opportunity> mOppWeek = new List<opportunity>();
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        system.debug('dateToday : '+dateToday);
        system.debug('dateWeek : '+dateWeek);
        
        system.debug('stringToday : '+stringToday);
        system.debug('stringWeek : '+stringWeek);
        system.debug('query : '+query);
        return Database.getQueryLocator(query);  
    }
    global void execute(Database.BatchableContext BC, List<opportunity> opps) {
        if(!opps.isEmpty()){
            for(opportunity opp : opps)
            {
                if(opp.CloseDate == dateToday){
                    opp.Close_Date_Today__c = True;
                    system.debug('Today opp : '+opp);
                }
                else {
                    opp.Close_Date_Week__c = True;
                    system.debug('Week opp : '+opp);
                } 
            }
            
            List<Database.SaveResult> oppResult = Database.update(opps, false);
            for (Database.SaveResult sr : oppResult) 
            {
                if (sr.isSuccess())
                {
                    System.debug('Success Opportunity Id: ' + sr.getId());
                }
                else // Update Opportunity Fail
                {              
                    for(Database.Error err : sr.getErrors())
                    {                 
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Opportunity Field Error: ' + err.getFields());
                    }
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        // finish code
    }
    
    global void execute(SchedulableContext SC) {
        database.executebatch(new OpportunityNotificationschedulableBatch());
    }
    
    global static void start(integer hour){
        string jobName = 'Close Date Notification Job';
        if (hour == 0) database.executebatch(new OpportunityNotificationschedulableBatch(),50);
        else {
            jobName = jobName += ' - ' + datetime.now().format();
            string cron = '0 0 ' + string.valueof(hour) + ' * * ?';
            system.schedule(jobName, cron, new OpportunityNotificationschedulableBatch());
        }
    }
}