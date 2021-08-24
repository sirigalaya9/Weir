trigger FeedCommentTrigger on FeedComment (after insert) {
    Set<Id> caseIdSet = new Set<Id>();
    List<Case> cases = new List<Case>();
    for (FeedComment feed: Trigger.new)
    {
        if(String.valueof(feed.ParentId).startsWith('500'))
            caseIdSet.add(feed.ParentId);
    }
    
    for (FeedComment feed: Trigger.new)
    {
        if(!caseIdSet.isEmpty())
        {
            system.debug('caseIdSet '+caseIdSet);
            for(Case mCase : [SELECT Id,Last_Activity_Date__c FROM Case where Id IN: caseIdSet])
            {
                mCase.Last_Activity_Date__c = system.now();
                cases.add(mCase);
            }
        }
    }
    
    if(cases.size() > 0)
    {
        try
        {
            update cases;
        }
        catch (DmlException e)
        {
            System.debug(e.getMessage() + ': ' + e.getLineNumber());
        }
    }
}