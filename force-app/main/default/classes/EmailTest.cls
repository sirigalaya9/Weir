@isTest
public class EmailTest 
{
    @testSetup
    static void setupData()
    {
        Case case1 = new Case();
        case1.Subject = 'Test';
        insert case1;
    }
    
    @isTest
    static void testSendEmailSingle()
    {
        EmailService.EmailRequest request = new EmailService.EmailRequest();
        request.templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_NPS_Survey_1st_Level_Escalation'].Id;
        request.whatId = [SELECT Id FROM Case WHERE Subject = 'Test'].Id;
        request.toId = UserInfo.getUserId();
        List<EmailService.EmailRequest> requests = new List<EmailService.EmailRequest>();
        requests.add(request);
        Test.startTest();
        EmailService.send(requests);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();        
        System.assertEquals(1, invocations, 'An email should be sent');
    }
    
    @isTest
    static void testSendEmailMultiple()
    {
        EmailService.EmailRequest request = new EmailService.EmailRequest();
        request.templateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Case_NPS_Survey_1st_Level_Escalation'].Id;
        request.whatId = [SELECT Id FROM Case WHERE Subject = 'Test'].Id;
        request.toId = UserInfo.getUserId();
        List<Id> ccIds = new List<Id>();
        ccIds.add(request.toId);
        request.ccIds = ccIds;
        List<EmailService.EmailRequest> requests = new List<EmailService.EmailRequest>();
        requests.add(request);
        Test.startTest();
        EmailService.send(requests);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();        
        System.assertEquals(1, invocations, 'An email should be sent');
    }     
    
    @isTest
    static void testSendEmailWrongTemplate()
    {
        EmailService.EmailRequest request = new EmailService.EmailRequest();
        request.templateId = '00X0w000000OXXX';
        request.whatId = [SELECT Id FROM Case WHERE Subject = 'Test'].Id;
        request.toId = UserInfo.getUserId();
        List<EmailService.EmailRequest> requests = new List<EmailService.EmailRequest>();
        requests.add(request);
        Test.startTest();
        EmailService.send(requests);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();        
        System.assertEquals(0, invocations, 'An email should be not sent');
    }     
}