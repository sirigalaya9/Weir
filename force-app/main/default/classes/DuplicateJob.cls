/**
* A batch for Duplicate Jobs (Standard Duplicate Job feature only available in Unlimieted and Performance Editions of Salesforce.)
* Test batch using:
DuplicateJob batch = new DuplicateJob('Account');        
Database.executeBatch(batch, 50);
* Test schedule using:
SchedulableContext sc = null;
DuplicateJob job = new DuplicateJob();
job.execute(sc);
*
* @author manu.voramontri@kliqxe.com
* @since 02.10.2020
* @version 16.10.2020
**/
public without sharing class DuplicateJob implements Database.Batchable<sobject>, Schedulable, Database.Stateful
{
    //Statics
    public static final Integer BATCH_SIZE = 50;
    public static final String CLASS_NAME = 'DuplicateJob';    

    //Instances    
    public String results = '';
    public Integer totalSuccess = 0;
    public Integer totalError = 0;   
    public Integer totalDetail = 0;
    public String objectName;
    public Set<Id> duplicateIds; 

    //Default no-org constructor for Scheduling Job via UI
    public DuplicateJob() 
    {
        
    }

    //Constructor for Batch
    public DuplicateJob(String sobj) 
    {
        objectName = sobj;
        results = '\n';
        duplicateIds = new Set<Id>();
    }

    //Scheduled implemented
    public void execute(SchedulableContext sc)
    {
        System.debug('Execute Schedule');
        DuplicateJob accountJob = new DuplicateJob('Account');
        Database.executeBatch(accountJob, BATCH_SIZE);
        DuplicateJob contactJob = new DuplicateJob('Contact');
        Database.executeBatch(contactJob, BATCH_SIZE);
    }    

    //Get all records in system based on object
    public Database.QueryLocator start(Database.BatchableContext bc) 
    {
        System.debug('Start');
        List<DuplicateRecordSet> duplicates = [SELECT Id FROM DuplicateRecordSet WHERE DuplicateRule.SobjectType = :objectName LIMIT 10000];
        delete duplicates;
        return Database.getQueryLocator('SELECT Id FROM ' + objectName);
    }
    
    //Find duplicates in batch
    public void execute(Database.BatchableContext bc, List<sObject> sobjs) 
    {
        System.debug('Execute Batch');
        
        List<Id> ids = new List<Id>();
        for (sObject sobj : sobjs)
        {
            if (!duplicateIds.contains(sobj.Id))
            {
                ids.add(sobj.Id);
            }            
        }
        List<DuplicateFinder.DuplicateSetInfo> results = DuplicateFinder.findDuplicatesByIds(ids, objectName);

        for (DuplicateFinder.DuplicateSetInfo result : results) 
        {
            duplicateIds.add(result.duplicateSet.Id);            
            totalSuccess++;
            totalDetail = totalDetail + result.duplicateItems.size();
        }        
    }

    // Finish - send email to running user
    public void finish(Database.BatchableContext bc) 
    {
        System.debug('Finish');
        /*
        String summary = 'Total Duplicate Sets Found: ' + totalSuccess;           
        summary += '\nTotal Duplicate Items Found: ' + totalDetail;
        //summary += '\nTotal Error: ' + totalError;
        results = summary + results;
        
        List<String> sendToEmails = new List<String>();
        User user = [SELECT Email FROM User WHERE Id = :System.UserInfo.getUserId()];
        sendToEmails.add(user.Email);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(sendToEmails);
        mail.setSubject(CLASS_NAME + ' for ' + objectName + ' is complete');            
        mail.setPlainTextBody(results);
        mails.add(mail);
        Messaging.sendEmail(mails);
        */
    }
}