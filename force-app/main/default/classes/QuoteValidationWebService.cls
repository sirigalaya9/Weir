global class QuoteValidationWebService
{
    global class ValidationResult
    {
        webservice Boolean isValidated;
        webservice String errorMessage;
    }
    
    webservice static ValidationResult QuoteValidation(String accountERPID, String userERPID, String shipToERPID, String oppRefId, List<String> materialNumber)
    {
        ValidationResult result =  new ValidationResult();
        result.isValidated = false;
        result.errorMessage = '';
        List<Material_Number__c> queryMatchedMaterial;
        List<Account> accList = [SELECT Id, Name, ERP_Id__c FROM Account WHERE ERP_Id__c =: accountERPID];
        if(!accList.isEmpty())
        {
            result.isValidated = true;
            system.debug('Account validated: '+result.isValidated+' ERP ID: '+accountERPID);
            
            List<User> userList = [SELECT Id, Name, ERP_Id__c FROM User WHERE ERP_Id__c =: userERPID];
            if(!userList.isEmpty())
            {
                result.isValidated = true;
                system.debug('User validated: '+result.isValidated+' ERP ID: '+userERPID);
                
                List<Address__c> shipTo = [SELECT Id, Name, Account__r.ERP_Id__c, Street__c, City__c, State__c, PostalCode__c, Country__c, ERP_ID__c
                                           FROM Address__c WHERE ERP_Id__c =: shipToERPID AND Account__r.ERP_Id__c =: accountERPID];
               /* if (!shipTo.isEmpty())
                {
                    result.isValidated = true;
                    system.debug('shipTo validated: '+result.isValidated+' ERP ID: '+shipToERPID);
				*/
                    
                    if (!materialNumber.isEmpty())
                    { 
                        system.debug('Material Size: '+materialNumber.size());
                        String errMsg;
                        Boolean Validated = true;
                        for(Integer i=0; i<materialNumber.size(); i++)
                        {  
                            Integer itemNo = i+1;
                            queryMatchedMaterial = [SELECT Id, Name, ERP_ID__c FROM Material_Number__c WHERE ERP_ID__c =: materialNumber.get(i)];
                            if(!queryMatchedMaterial.isEmpty())
                                system.debug('Material : '+itemNo+' validated '+result.isValidated+' -- ERP ID: '+materialNumber.get(i));
                            else
                            {
                                Validated = false;
                                errMsg = errMsg + materialNumber.get(i)+' ';  
                            }
                        }
                        if(Validated == false)
                        {
                            result.errorMessage ='Material : '+errMsg+'do not exist';
                            createErrorMessage(result.errorMessage, oppRefId, accountERPID, ShipToERPID, userERPID);
                            result.isValidated = false;
                        }
                        else
                            result.isValidated = true;
                    }
                /*}
                else
                {
                    result.isValidated = false;
                    result.errorMessage = 'The shipTo: '+shipToERPID+' does not exist in '+accountERPID;
                    createErrorMessage(result.errorMessage, oppRefId, accountERPID, ShipToERPID, userERPID);
                }*/  
            }
            else
            {
                result.isValidated = false;
                result.errorMessage = 'The User: '+userERPID+' does not exist';
                createErrorMessage(result.errorMessage, oppRefId, accountERPID, ShipToERPID, userERPID);
            }
            
        }
        else
        {
            result.isValidated = false;
            result.errorMessage = 'Account : '+accountERPID+' does not exist';
            createErrorMessage(result.errorMessage, oppRefId, accountERPID, ShipToERPID, userERPID);
        }
        //----------Indirect Quote : Validate Opportunity!
        if(oppRefId != '' && oppRefId != null)
        {
            List<Opportunity> oppList = [SELECT Id, Name, ERP_Id__c, Opportunity_ID__c FROM Opportunity WHERE Opportunity_ID__c =: oppRefId];
            if (!oppList.isEmpty())
            {
                result.isValidated = true;
                System.debug('Indirect Quote: Refer to the existing opportunity!!');
            }
            else
            {
                result.isValidated = false;
                System.debug('The existing opportunity record is not found from '+oppRefId);
                result.errorMessage = 'The existing opportunity record is not found from '+oppRefId;
                createErrorMessage(result.errorMessage, oppRefId, accountERPID, ShipToERPID, userERPID);
            }
        }
        system.debug('Quote Validation: '+result.isValidated+' '+result.errorMessage);
        return result;
    }
    
    public static void createErrorMessage(String errMessage, String oppID, String accountERPID, String ShipToERPID, String userERPID)
    {
        try
        {
            Error_Message__c mError = new Error_Message__c();
            mError.Scenario__c = 'Input Validation';
            mError.Error_Message_Detail__c = errMessage;
            mError.Opportunity_ID__c = oppID;
            //mError.Quote_ERP_ID__c = quoteERPID;
            mError.Account_ERP_ID__c = accountERPID;
            mError.ShipTo_ERP_ID__c = shipToERPID;
            mError.User_ERP_ID__c = userERPID;
            //mError.Sale_Organization__c = SaleOrg;
            insert mError;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}