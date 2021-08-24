@isTest
public class DirectIndustryAPITest 
{
    @TestSetup
    static void setupData()
    {
        Direct_Industry__c setting = new Direct_Industry__c();
        setting.Key__c = 'test';
        setting.Active__c = true;
        setting.Live_Mode__c = true;
        Date dt = Date.newInstance(2021, 4, 5);
        setting.Start_Date__c = dt;
        setting.End_Date__c = dt;        
        insert setting;
    }

    @isTest
    static void test_single_success()
    {
        Test.startTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock ();
            multiMock.setStaticResource('callout:Direct_Industry/2021-04-05/2021-04-05/test?lang=en','DirectIndustryAPIMockResponse');           
            multiMock.setStatusCode(200);        
            Test.setMock(HttpCalloutMock.class, multiMock);            
            DirectIndustryAPIController.sync();
        }
        Test.stopTest();
        List<Direct_Industry_Log__c> logs = [SELECT Id FROM Direct_Industry_Log__c];
        System.assertEquals(1, logs.size(), '1 log should be created');
        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(1, leads.size(), '1 lead should be created');
    }

    @isTest
    static void test_batch_success()
    {
        Date dt = Date.newInstance(2021, 4, 5);                
        Test.startTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock ();
            multiMock.setStaticResource('callout:Direct_Industry/2021-04-05/2021-04-05/test?lang=en','DirectIndustryAPIMockResponse');            
            multiMock.setStatusCode(200);        
            Test.setMock(HttpCalloutMock.class, multiMock);            
            Database.executeBatch(new DirectIndustryAPISchedulableBatch(dt, dt), 1); 
        }
        Test.stopTest();
        List<Direct_Industry_Log__c> logs = [SELECT Id FROM Direct_Industry_Log__c];
        System.assertEquals(1, logs.size(), '2 log should be created');
        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(1, leads.size(), '2 lead should be created');
    }    

    @isTest
    static void test_error()
    {
        Test.startTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock ();
            multiMock.setStaticResource('callout:Direct_Industry/2021-04-05/2021-04-05/test?lang=en','DirectIndustryAPIMockResponse');           
            multiMock.setStatusCode(200);        
            Test.setMock(HttpCalloutMock.class, multiMock);            
            DirectIndustryAPIController.sync();
            DirectIndustryAPIController.sync(); //Again process same thing
        }
        Test.stopTest();
        List<Direct_Industry_Log__c> logs = [SELECT Id, Error__c FROM Direct_Industry_Log__c];
        System.assertEquals(2, logs.size(), '2 logs should be created');        
        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(1, leads.size(), '1 lead should be created');
    }
    
    @isTest
    static void test_manual_success()
    {
        Test.startTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock ();
            multiMock.setStaticResource('callout:Direct_Industry/2021-04-05/2021-04-05/test?lang=en','DirectIndustryAPIMockResponse');           
            multiMock.setStatusCode(200);        
            Test.setMock(HttpCalloutMock.class, multiMock);        
            List<Direct_Industry_Log__c> logs = new List<Direct_Industry_Log__c>();
            ApexPages.StandardSetController stdSetCtrl = new ApexPages.StandardSetController(logs);            
            DirectIndustryAPIController ctrl = new DirectIndustryAPIController(stdSetCtrl);
            ctrl.runSync();
        }
        Test.stopTest();
        List<Direct_Industry_Log__c> logs = [SELECT Id FROM Direct_Industry_Log__c];
        System.assertEquals(1, logs.size(), '1 log should be created');
        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(1, leads.size(), '1 lead should be created');
    }  
    
    @isTest
    static void test_single_inactive()
    {
        Direct_Industry__c setting = Direct_Industry__c.getOrgDefaults();        
        setting.Active__c = false;        
        update setting;        
        Test.startTest();
        {
            MultiStaticResourceCalloutMock multiMock = new MultiStaticResourceCalloutMock ();
            multiMock.setStaticResource('callout:Direct_Industry/2021-04-05/2021-04-05/test?lang=en','DirectIndustryAPIMockResponse');           
            multiMock.setStatusCode(200);        
            Test.setMock(HttpCalloutMock.class, multiMock);            
            DirectIndustryAPIController.sync();
        }
        Test.stopTest();
        List<Direct_Industry_Log__c> logs = [SELECT Id FROM Direct_Industry_Log__c];
        System.assertEquals(1, logs.size(), '1 log should be created');
        List<Lead> leads = [SELECT Id FROM Lead];
        System.assertEquals(0, leads.size(), '0 lead should be created');
    }  
}