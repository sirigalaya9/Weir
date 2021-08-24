public class TaskHelper 
{
    @InvocableMethod(label='Get Email from Body' description='Returns email from passed in string of email body')
    public static List<String> getEmailFromBody(List<String> comments) 
    {
        List<String> emails = new List<String>();
        if (comments == null || comments.size() == 0)
        {
            return emails;
        }
        //Not bulkified because this will be invocked when a user logs an email as task
        try 
        {
            String comment = comments.get(0);
            //Integer index = comment.indexOf('To:');
            comment = comment.substringBetween('To:','\n');
            comment = comment.split(',')[0];
            comment = comment.trim();
            String email = comment.substringBetween('<','>');
            if (email == NULL)
            {
                email = comment; 
            }
            //Integer endIndex = comment.indexOf('>');        
            //String email = comment.substring(0, endIndex);
            System.debug(email);
            //Assume first result is match        
            if (email != NULL)
            {
               emails.add(email); 
            }
        }
        catch (Exception e)
        {
            System.debug(e.getMessage());
        }
		return emails;        
    }
}