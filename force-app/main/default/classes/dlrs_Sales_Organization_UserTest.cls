/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_Sales_Organization_UserTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_Sales_Organization_UserTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Sales_Organization_User__c());
    }
}