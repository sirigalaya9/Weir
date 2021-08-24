@isTest
public class TaskHelperTest 
{

    @isTest
    static void testEmail_Positive_Case_Android() {
        List<String> comments = new List<String>();
        String comment = 'Test\n\r To: <test@example.com>\n\rTestTest';
        comments.add(comment);
        List<String> emails = TaskHelper.getEmailFromBody(comments);
        System.assertEquals(1, emails.size(), '1 email should be returned');
    }
    
    @isTest
    static void testEmail_Positive_Case_IPhone() {
        List<String> comments = new List<String>();
        String comment = 'Test\n\r To: test@example.com\n\rTestTest';
        comments.add(comment);
        List<String> emails = TaskHelper.getEmailFromBody(comments);
        System.assertEquals(1, emails.size(), '1 email should be returned');
    }    
    
    @isTest
    static void testEmail_Negative() {
        List<String> comments = new List<String>();
        String comment = 'Test\n\r no email \n\rTestTest';
        comments.add(comment);
        List<String> emails = TaskHelper.getEmailFromBody(comments);
        System.assertEquals(0, emails.size(), '0 email should be returned');
    }    
}