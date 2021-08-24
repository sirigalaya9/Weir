public with sharing class QuoteProductFormController {

    @AuraEnabled
    public static sObject getMasterData(String objectApiName, String buildCode)
    {
        objectApiName = objectApiName.replace('__c', '_Master__c');
        //objectApiName = 'Schema.' + objectApiName;
        SObjectType sobjType = ((SObject)(Type.forName(objectApiName).newInstance())).getSObjectType();        
        Map<String,Schema.SObjectField> fields = sobjType.getDescribe().fields.getMap();

        String query = 'SELECT Id, Name, CreatedDate, LastModifiedDate';
        for (String fieldName : fields.keySet())
        {
            Schema.SObjectField field = fields.get(fieldName);
            if (field.getDescribe().isCustom())
                query += ', ' + fieldName;
        }    
        query += ' FROM ' + objectApiName;        
        query += ' WHERE AH_Build_Code__c = :buildCode';
        query += ' ORDER BY CreatedDate DESC';

        List<sObject> sobjs = Database.query(query);
        if (sobjs.size() > 0)
        {
            return sobjs.get(0);
        }
        else
        {
            return null;
        }
    }
}