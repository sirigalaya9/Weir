@isTest
public class FlowHelperTest 
{
    @isTest
    static void testSplitString_Delimited()
    {
        String value = 'test0@example.com;test1@example.com;test2@example.com';        
        FlowHelper_SplitString.FlowRequest req = new FlowHelper_SplitString.FlowRequest();
        List<FlowHelper_SplitString.FlowRequest> reqs = new List<FlowHelper_SplitString.FlowRequest>{ req };
        req.value = value;
        req.delimiter = ';';
        req.unique = true;
        List<List<String>> bulkResults = FlowHelper_SplitString.execute(reqs);
        System.assertEquals(1, bulkResults.size(), '1 item should be in request');
        List<String> results = bulkResults.get(0);
        System.assertEquals(3, results.size(), '3 values should be returned');
        System.assertEquals('test0@example.com', results.get(0));
        System.assertEquals('test1@example.com', results.get(1));
        System.assertEquals('test2@example.com', results.get(2));        
    }

    @isTest
    static void testSplitString_Delimited_Unique()
    {
        String value = 'test0@example.com;test0@example.com;test2@example.com';        
        FlowHelper_SplitString.FlowRequest req = new FlowHelper_SplitString.FlowRequest();
        List<FlowHelper_SplitString.FlowRequest> reqs = new List<FlowHelper_SplitString.FlowRequest>{ req };
        req.value = value;
        req.delimiter = ';';
        req.unique = true;
        List<List<String>> bulkResults = FlowHelper_SplitString.execute(reqs);
        System.assertEquals(1, bulkResults.size(), '1 item should be in request');
        List<String> results = bulkResults.get(0);
        System.assertEquals(2, results.size(), '2 values should be returned');       
        System.assertEquals('test0@example.com', results.get(0));
        System.assertEquals('test2@example.com', results.get(1));                 
    }    

    @isTest
    static void testSplitString_Delimited_NotUnique()
    {
        String value = 'test0@example.com;test0@example.com;test2@example.com';        
        FlowHelper_SplitString.FlowRequest req = new FlowHelper_SplitString.FlowRequest();
        List<FlowHelper_SplitString.FlowRequest> reqs = new List<FlowHelper_SplitString.FlowRequest>{ req };
        req.value = value;
        req.delimiter = ';';
        req.unique = false;
        List<List<String>> bulkResults = FlowHelper_SplitString.execute(reqs);
        System.assertEquals(1, bulkResults.size(), '1 item should be in request');
        List<String> results = bulkResults.get(0);
        System.assertEquals(3, results.size(), '3 values should be returned');       
        System.assertEquals('test0@example.com', results.get(0));
        System.assertEquals('test0@example.com', results.get(1)); 
        System.assertEquals('test2@example.com', results.get(2));                 
    }      

    @isTest
    static void testSplitString_NotDelimited()
    {
        String value = 'test0@example.com';
        FlowHelper_SplitString.FlowRequest req = new FlowHelper_SplitString.FlowRequest();
        List<FlowHelper_SplitString.FlowRequest> reqs = new List<FlowHelper_SplitString.FlowRequest>{ req };
        req.value = value;
        req.delimiter = ';';
        req.unique = true;
        List<List<String>> bulkResults = FlowHelper_SplitString.execute(reqs);
        System.assertEquals(1, bulkResults.size(), '1 item should be in request');
        List<String> results = bulkResults.get(0);
        System.assertEquals(1, results.size(), '1 value should be returned');      
    }    
}