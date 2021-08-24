trigger OpportunityAfterUpdateTrigger on Opportunity (After update, After insert, After delete) {
    List<Id> projectIds = new List<Id>();
    
    if(Trigger.isInsert || Trigger.isUpdate){
        for( Opportunity opp: Trigger.New){
            if(((Trigger.IsInsert ||
                 opp.Project__c != Trigger.oldMap.get(opp.Id).Project__c ||
                 opp.Amount != Trigger.oldMap.get(opp.Id).Amount ||
                 opp.Publish_to_Forecast__c!= Trigger.oldMap.get(opp.Id).Publish_to_Forecast__c ||
                 opp.CurrencyISOCode != Trigger.oldMap.get(opp.Id).CurrencyISOCode ||
                 opp.StageName != Trigger.oldMap.get(opp.Id).StageName   
                ) && opp.Project__c!=null)
              )  
            {
                projectIds.add(opp.project__c); 
            }
            
            if(Trigger.isUpdate && opp.Project__c != Trigger.oldMap.get(opp.Id).Project__c && 
               opp.Project__c == null && Trigger.oldMap.get(opp.Id).Project__c !=null){
                projectIds.add(Trigger.oldMap.get(opp.Id).project__c); 
            }
        }
    }
    
    if(Trigger.isDelete){
        for( Opportunity opp: Trigger.old){
            projectIds.add(opp.project__c);
        }
    }
    
    Map<Id, List<Opportunity>> projectIdOppsMap = new Map<Id, List<Opportunity>>();
    Set<String> currencyISoCodes = new Set<String>();
    Map<String, Double> codeCurrencyTypeMap = new Map<String, Double>();
    
    if (projectIds.size() >0 ){
        system.debug('projectIds '+projectIds);
        for(Opportunity opp : [Select Amount, CurrencyISOCode, Publish_to_Forecast__c, Project__r.currencyISOCode, Project__c from Opportunity 
                               where project__c = :projectIds and Publish_to_Forecast__c = TRUE AND StageName != 'Stopped' AND StageName != 'Closed Lost']){
                                   if(!projectIdOppsMap.containsKey(opp.Project__c)){
                                       projectIdOppsMap.put(opp.Project__c, new List<Opportunity>());
                                   } 
                                   projectIdOppsMap.get(opp.Project__c).add(opp);
                                   currencyISoCodes.add(opp.currencyISOCode);
                                   currencyISoCodes.add(opp.Project__r.currencyISOCode);   
                               }
        for(CurrencyType currType : [Select conversionRate, ISOCode from CurrencyType where ISOCode = :currencyISOCodes and isActive = TRUE]){
            codeCurrencyTypeMap.put(currType.ISOCode, currType.conversionRate.doubleValue());   
        }
        
        List<Project__c> projs = [Select Total_Opportunity_Sum__c, Id from Project__c where Id = :projectIds];
        List<Project__c> updatedProjs = new List<Project__c>();
        for(Project__c proj:projs){
            //calculate total sum for each project
            Double totalSum = 0.00;
            List<Opportunity> opps = new List<Opportunity>();
            
            if(projectIdOppsMap.containsKey(proj.Id)){
                opps = projectIdOppsMap.get(proj.Id);
                
                for(Opportunity opp: opps){
                    totalSum += (opp.Amount==null?0.00:opp.Amount)  * codeCurrencyTypeMap.get(opp.Project__r.currencyISOCode)/codeCurrencyTypeMap.get(opp.currencyISOCode);
                }
            }
            proj.Total_Opportunity_Sum__c = totalSum;
            system.debug('Total_Opportunity_Sum__c '+proj.Total_Opportunity_Sum__c);
            updatedProjs.add(proj);               
        }
        if(!updatedProjs.isEmpty()) update updatedProjs;  
    }
}