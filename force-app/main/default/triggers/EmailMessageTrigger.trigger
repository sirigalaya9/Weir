trigger EmailMessageTrigger on EmailMessage (after insert) 
{
    //Support single email message only no bulk.
    try
    {
        EmailMessage em = Trigger.new[0];
        String relatedToId = em.RelatedToId;
        if (String.isNotBlank(relatedToId) && relatedToId.startsWith('006'))
        {
            Map<String, Object> params = new Map<String, Object>();
            params.put('EmailMessageID', em.Id);
            params.put('whatId', em.RelatedToId);
            Flow.Interview.Email_Message_Assign_Opportunity_Contact_Role flow = new Flow.Interview.Email_Message_Assign_Opportunity_Contact_Role(params);
            flow.start();
        }
    }
    catch (Exception e)
    {
        System.debug(e.getMessage());
    }

}