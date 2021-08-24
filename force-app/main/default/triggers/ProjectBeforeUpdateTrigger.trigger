trigger ProjectBeforeUpdateTrigger on Project__c (Before update, Before delete) {
    
    Set<String> currencyISoCodes = new Set<String>();
    List<Project_Account__c> projectAccounts = new  List<Project_Account__c>();
    Set<Id> ProjectIds = Trigger.oldMap.keySet();
    
    if(Trigger.isDelete)
    {
        for(Project_Account__c projectAccount :[SELECT Id, Name, Project__c, Account__c FROM Project_Account__c where Project__c IN: ProjectIds])
        {    
            system.debug(projectAccount);
            projectAccounts.add(projectAccount);          
        }
        if(!projectAccounts.isEmpty())
            delete projectAccounts;
        
    }
    
    if(Trigger.isUpdate)
    {
        for(Project__c proj: Trigger.New){
            
            if( proj.CurrencyISOCode != Trigger.oldMap.get(proj.Id).CurrencyISOCode)  
            {
                currencyISoCodes.add(proj.currencyISOCode);
                currencyISoCodes.add(Trigger.oldMap.get(proj.Id).CurrencyISOCode);
            } 
        }
        if (currencyISoCodes.size() >0 ){     
            
            Map<String, Double> codeCurrencyTypeMap = new Map<String, Double>();
            
            for(CurrencyType currType : [Select conversionRate, ISOCode from CurrencyType where ISOCode = :currencyISOCodes and isActive = TRUE]){
                
                codeCurrencyTypeMap.put(currType.ISOCode, currType.conversionRate.doubleValue());
                
            }
            
            for(Project__c proj: Trigger.New){
                
                if(proj.CurrencyISOCode != Trigger.oldMap.get(proj.Id).CurrencyISOCode)  
                {
                    proj.Total_Opportunity_Sum__c = proj.Total_Opportunity_Sum__c * codeCurrencyTypeMap.get(proj.currencyISOCode)/codeCurrencyTypeMap.get(Trigger.oldMap.get(proj.Id).CurrencyISOCode);   
                }
                
            }
            
        }
    }
    
}