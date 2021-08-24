public without sharing class DirectIndustryAPIService 
{
    private static final Direct_Industry__c setting = Direct_Industry__c.getOrgDefaults();
    private static final String LANG = 'en';

    public static String constructRequest(Date startDate, Date endDate)
    {
        Time t = Time.newInstance(0, 0, 0, 0);
        Datetime startDateTime = Datetime.newInstanceGmt(startDate, t);
        Datetime endDateTime = Datetime.newInstanceGmt(endDate, t);
        String startDateStr = startDateTime.format('yyyy-MM-dd');
        String endDateStr = endDateTime.format('yyyy-MM-dd');
        String endpoint = '/' + startDateStr + '/' + endDateStr + '/' + setting.Key__c + '?lang=' + LANG;
        return endpoint;
    }

    public static String getRequest(String endpoint)
    {     
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Direct_Industry' + endPoint);
        req.setMethod('GET');        
        req.setTimeout(120000);
                
        Http http = new Http();
        HttpResponse res = null;
        String resBody = null;
        res = http.send(req);
        System.debug('resBody: ' + resBody);

        if (res.getStatusCode() == 200)
        {
            resBody = res.getBody();
        }
        else
        {            
            CalloutException e = new CalloutException();
            e.setMessage('Status: ' + res.getStatusCode() + ' ' + res.getStatus() + '\nBody:\n' + res.getBody());
            throw e;
        }
        return resBody;
    }
    
    public static List<Lead> parseResponse(String body)
    {
        List<Lead> leads = new List<Lead>();

        DOM.Document doc = new DOM.Document();
        doc.load(body);        
        Dom.XmlNode envelope = doc.getRootElement();
        String namespace = 'http://www.virtual-expo.com/XMLSchema/En/BoothDataExport/V3.0';
        {
            Dom.XmlNode visitors = envelope.getChildElement('visitors', namespace);

            if (visitors != null)
            {
                Dom.XmlNode[] visitorList = visitors.getChildElements(); 
                for (Dom.XmlNode visitor : visitorList)
                {                
                    Dom.XmlNode lastVisitDate = visitor.getChildElement('lastVisitDate', namespace); //TBC
                    Dom.XmlNode lastRequestDate = visitor.getChildElement('lastRequestDate', namespace); //TBC               
                    Dom.XmlNode company = visitor.getChildElement('company', namespace);               
                    Dom.XmlNode name = visitor.getChildElement('name', namespace);
                    Dom.XmlNode firstname = visitor.getChildElement('firstname', namespace);
                    Dom.XmlNode phoneNumber = visitor.getChildElement('phoneNumber', namespace);
                    Dom.XmlNode email = visitor.getChildElement('email', namespace);
                    Dom.XmlNode webSite = visitor.getChildElement('webSite', namespace);
                    Dom.XmlNode city = visitor.getChildElement('city', namespace);
                    Dom.XmlNode address = visitor.getChildElement('address', namespace);
                    Dom.XmlNode postalCode = visitor.getChildElement('postalCode', namespace);                
                    Dom.XmlNode country = visitor.getChildElement('country', namespace);
                    Dom.XmlNode businessSector = visitor.getChildElement('businessSector', namespace); //TBC
                    Dom.XmlNode businessCompanyType = visitor.getChildElement('businessCompanyType', namespace); //TBC    
                    
                    Lead lead = new Lead();
                    lead.Direct_Industry_Visitor_Id__c = visitor.getAttribute('id', null);
                    lead.Company = company?.getText();
                    lead.LastName = name?.getText();
                    lead.FirstName = firstname?.getText();
                    lead.Phone = phoneNumber?.getText();
                    lead.Email = email?.getText();              
                    lead.Website = webSite?.getText();
                    lead.City = city?.getText();
                    lead.Street = address?.getText();
                    lead.PostalCode = postalCode?.getText();
                    lead.Country = country?.getText();                

                    Dom.XmlNode requests = visitor.getChildElement('requests', namespace);

                    if (requests != null)
                    {
                        Dom.XmlNode[] requestList = requests.getChildElements();

                        for (Dom.XmlNode request : requestList)
                        {
                            lead.Direct_Industry_Request_Id__c = request.getAttribute('id', null);
                            Dom.XmlNode label = request.getChildElement('label', namespace);
                            Dom.XmlNode type = request.getChildElement('type', namespace);
                            Dom.XmlNode message = request.getChildElement('message', namespace);
                            Dom.XmlNode sentDate = request.getChildElement('sentDate', namespace);
        
                            lead.Product__c = label?.getText();
                            lead.Request_Type__c = type?.getText();
                            lead.Request_Message__c = message?.getText();
                            lead.Request_Send_Date__c = Date.valueOf(sentDate?.getText());

                            leads.add(lead);
                        }                    
                    }

                    Dom.XmlNode prospects = visitor.getChildElement('prospects', namespace);

                    if (prospects != null)
                    {
                        Dom.XmlNode[] prospectList = prospects.getChildElements();

                        for (Dom.XmlNode prospect : prospectList)
                        {
                            lead.Direct_Industry_Prospect_Id__c = prospect.getAttribute('id', null);                        
                            Dom.XmlNode kind = prospect.getChildElement('kind', namespace);                        
        
                            lead.Prospect_Kind__c = kind?.getText();                        

                            if (requests == null)
                                leads.add(lead);
                        }                    
                    }                
                }
            }
        }
        return leads;
    }    
}