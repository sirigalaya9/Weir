@isTest
public class FeedComment_Test {
    
    @isTest static void UpdateChatter()
    {               
        Test.StartTest();
        Case c = new Case(Subject='Test Case', Status = 'New');
        insert c;
        
        FeedItem f = new FeedItem();
        f.ParentId = c.id;
        f.body = 'test';
        insert f;
        FeedComment fc = new FeedComment();
        fc.CommentBody = 'comment test';
        fc.FeedItemId = f.Id;
        insert fc;
        
        FeedComment fcQ = [Select Id ,CommentBody , FeedItemId ,ParentId from FeedComment];
        System.assertEquals(fcQ.ParentId ,c.Id);
        Test.StopTest();
    }

}