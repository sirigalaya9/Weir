public class RussiaApprovalController {

    public static Boolean Success {get; set;}
    
    @AuraEnabled
    public static Boolean SubmitForApproval(Opportunity opp, String comments)
    {
        Boolean Success = false;  
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments(comments);
        req.setObjectId(opp.id);
        Approval.ProcessResult result = Approval.process(req);
        Success = result.isSuccess();
        return Success;
    }

}