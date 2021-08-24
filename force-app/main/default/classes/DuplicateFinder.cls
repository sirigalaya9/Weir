public without sharing class DuplicateFinder
{
    private Map<String, DuplicateRule> getDuplicateRules() 
    {
        Map<String, DuplicateRule> ruleMap = new Map<String, DuplicateRule>();        
        List<DuplicateRule> duplicateRules = [SELECT Id, DeveloperName FROM DuplicateRule LIMIT 100];
        for (DuplicateRule dr : duplicateRules) 
        {
            ruleMap.put(dr.DeveloperName, dr);
        }
        return ruleMap;
    }

    public static List<DuplicateSetInfo> findDuplicatesByIds(List<Id> ids, String objectName) 
    {
        DuplicateFinder finder = new DuplicateFinder();
        Map<String, DuplicateRule> ruleMap = finder.getDuplicateRules(); 
        Set<String> currentDupIds = new Set<String>();

        List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicatesByIds.findDuplicatesByIds(ids);

        List<DuplicateSetInfo> duplicateSets = new List<DuplicateSetInfo>();
        List<DuplicateRecordSet> parentRecords = new List<DuplicateRecordSet>(); 
        
        Integer recordSearchSize = ids.size();

        for (Integer i = 0; i<recordSearchSize; i++) 
        {
            String listRecordId = ids[i];
            //If current record already identified as duplicate previously, skip it.
            if (currentDupIds.contains(listRecordId)) 
            {
                continue;
            }

            Datacloud.FindDuplicatesResult findDupeResult = results[i];        
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) 
            {        
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) 
                {                            
                    if (matchResult.getSize() > 0) 
                    {
                        Boolean addToInsertList = false;                        
                        DuplicateSetInfo dsi = new DuplicateSetInfo();
                        DuplicateRecordSet duplicateSet = new DuplicateRecordSet(Custom_Duplicate_Job__c = TRUE, Object_Name__c = objectName);
                        duplicateSet.duplicateRuleId = (ruleMap.get(dupeResult.getDuplicateRule())).Id;
                        dsi.duplicateSet = duplicateSet;

                        DuplicateRecordItem recordItem = new DuplicateRecordItem(RecordId = listRecordId);
                        dsi.duplicateItems.add(recordItem);

                        for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) 
                        {
                            DuplicateRecordItem duplicateItem = new DuplicateRecordItem(RecordId = (matchRecord.getRecord()).Id);
                            currentDupIds.add(duplicateItem.RecordId);
                            dsi.duplicateItems.add(duplicateItem);
                            addToInsertList = true;
                        }
                        if (addToInsertList) 
                        {
                            parentRecords.add(duplicateSet);
                            duplicateSets.add(dsi);
                        }
                    }
                }
            }
        }

        //Save
        if (!parentRecords.isEmpty()) 
        {
            insert parentRecords;
            List<DuplicateRecordItem> childRecords = new List<DuplicateRecordItem>();
            for (DuplicateSetInfo dsi : duplicateSets) 
            {
                dsi.prepareForInsert();
                childRecords.addAll(dsi.duplicateItems);
            }
            insert childRecords;
        }

        return duplicateSets;
    }

    public class DuplicateSetInfo 
    {
        public DuplicateRecordSet duplicateSet;
        public List<DuplicateRecordItem> duplicateItems;

        public DuplicateSetInfo() 
        {
            duplicateItems = new List<DuplicateRecordItem>();
        }

        public void prepareForInsert() 
        {
            for (DuplicateRecordItem recordItem : duplicateItems) 
            {
                recordItem.DuplicateRecordSetId = duplicateSet.Id;
            }
        }
    }


}