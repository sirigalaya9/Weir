@isTest
global class CalloutSAPMock implements WebServiceMock {
    global void doInvoke(
        Object stub, Object request, Map<String, Object> response,
        String endpoint, String soapAction, String requestName,
        String responseNS, String responseName, String responseType)
    {
        
        if (requestName == 'DEBMAS06')
        {
            sapComDocumentSapIdocSoapMsg.DEBMAS06Response_element response_x = new sapComDocumentSapIdocSoapMsg.DEBMAS06Response_element();
            sapComDocumentSapIdocSoapMsg.IdocAssign IdocAssign = new sapComDocumentSapIdocSoapMsg.IdocAssign();
            IdocAssign.DbId = '0000000';
            response_x.IdocAssign = IdocAssign;
            system.debug('DEBMAS06 DbId : '+response_x.IdocAssign.DbId);
            response.put('response_x', response_x);
        }
        else if(requestName == 'SALESORDER_CREATEFROMDAT202')
        {
            sapComDocumentSapIdocSoapMsgOpp.SALESORDER_CREATEFROMDAT202Response_element response_x = new sapComDocumentSapIdocSoapMsgOpp.SALESORDER_CREATEFROMDAT202Response_element();
            sapComDocumentSapIdocSoapMsgOpp.IdocAssign IdocAssign = new sapComDocumentSapIdocSoapMsgOpp.IdocAssign();
            IdocAssign.DbId = '00000001';
            response_x.IdocAssign = IdocAssign;
            system.debug('SALESORDER_CREATEFROMDAT202 DbId : '+response_x.IdocAssign.DbId);
            response.put('response_x', response_x);
        }
        else if(requestName == 'QUOTATION_CREATEFROMDATA202')
        {
            sapComDocumentSapIdocSoapMsgQuote.QUOTATION_CREATEFROMDATA202Response_element response_x = new sapComDocumentSapIdocSoapMsgQuote.QUOTATION_CREATEFROMDATA202Response_element();
            sapComDocumentSapIdocSoapMsgQuote.IdocAssign IdocAssign = new sapComDocumentSapIdocSoapMsgQuote.IdocAssign();
            IdocAssign.DbId = '00000002';
            response_x.IdocAssign = IdocAssign;
            system.debug('SALESORDER_CREATEFROMDAT202 DbId : '+response_x.IdocAssign.DbId);
            response.put('response_x', response_x);
        }
        
    }   
}