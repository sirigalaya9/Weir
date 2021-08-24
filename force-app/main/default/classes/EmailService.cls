public class EmailService 
{
    //public static final String ORG_WIDE_EMAIL_ADDRESS = '';
    
    @InvocableMethod 
    public static void send(List<EmailRequest> requests)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();        
        Id orgWideEmailAddressId; 
        /*
        try
        {
            orgWideEmailAddressId = [SELECT Id FROM OrgWideEmailAddress WHERE Address =: ORG_WIDE_EMAIL_ADDRESS].id;            
        }
        catch (Exception e)
        {
            System.debug('Error while trying to set org wide email address. Error Message: ' + e.getMessage()); 
        }
        */
        try
        {
            for (EmailRequest request : requests)
            {           
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                //mail.setTemplateId(templateId);
                //mail.setSaveAsActivity(false);
                List<Id> ccIds = new List<Id>();
                if (request.ccIds != NULL)
                {
                    for (Id ccId : request.ccIds)
                    {
                        if (ccId != NULL)
                        {
                            ccIds.add(ccId);
                        }
                    }
                    mail.setCcAddresses(ccIds);
                }
                mail.setToAddresses(new List<Id> { request.toId });
                
                //mail.setCcAddresses(request.ccIds);
                //mail.setTargetObjectId(targetObjectId); 
                 
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(request.templateId, request.toId, request.whatId);
                String emailSubject = email.getSubject();
                String emailTextBody = email.getPlainTextBody();
                mail.setSubject(emailSubject);
                mail.setPlainTextBody(emailTextBody);
                
                //if (orgWideEmailAddressId != null)
                //  mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
                mails.add(mail);
            }

            {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(mails, false);
                for (Messaging.SendEmailResult result : results)
                {
                    if (!result.isSuccess())
                    {
                        System.debug('sendEmail not success.');
                        /*
                        List<Messaging.SendEmailError> errors = result.getErrors();
                        for (Messaging.SendEmailError error : errors)
                        {
                            String errorMsg = 'Errors occured during sending emails. Please notify your Administrator. ';
                            errorMsg += 'Error Message: ' + error.getMessage() + ' Status Code: ' + error.getStatusCode();
                            System.debug(errorMsg);
                        }
                        */
                    }
                }
            }
        }
        catch (Exception e)
        {
            String errorMsg = 'Error while trying to send mail. Please notify your Administrator. Error Message: ' + e.getMessage();
            System.debug(errorMsg);
        }
    }
    
    public class EmailRequest
    {
        @InvocableVariable
        public Id templateId;
        
        @InvocableVariable
        public Id whatId;
        
        @InvocableVariable
        public Id toId;
        
        @InvocableVariable
        public List<Id> ccIds;      
    }    
}