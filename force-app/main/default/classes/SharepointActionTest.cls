@isTest
public class SharepointActionTest 
{
    @testSetup
    static void setupData()
    {
        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Qualification';
        opp.CloseDate = System.today();
        insert opp;
    }

    @isTest
    static void testAccess()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        Boolean result = SharepointActionController.userHasAccess(opp.Id);
        System.assertEquals(true, result, 'Current user should have access to the Opportunity.');
    }
}