public class FlowHelper_SplitString 
{
    @InvocableMethod(label = 'Split String By Character')
    public static List<List<String>> execute(List<FlowRequest> requests) 
    {
        List<List<String>> bulkValues = new List<List<String>>();

        for (FlowRequest request : requests) 
        {
            String character = request.delimiter;            
            String value = request.value;
            List<String> values = value.split(character);
            List<String> trimmedValues = new List<String>();
            for (String val : values)
            {
                if (String.isNotBlank(val))
                {
                    trimmedValues.add(val.trim());
                }
            }
            if(request.unique)
            {                
                bulkValues.add(new List<String>(new Set<String>(trimmedValues)));
            } 
            else
            {
                bulkValues.add(values);
            }
        }
        return bulkValues;
    }

    public class FlowRequest 
    {
        @InvocableVariable(label = 'String To Split' required = true)
        public String value;

        @InvocableVariable(label = 'Character To Split By' required = true)
        public String delimiter;

        @InvocableVariable(label = 'Return Only Unique Values' required = true)
        public Boolean unique;
    }

}