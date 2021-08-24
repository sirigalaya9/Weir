public without sharing class AccountController 
{
	private static Object_Permission__c objectPermission = Object_Permission__c.getInstance();
    
    public static void validateDelete(List<Account> accounts)
    {
        for (Account account : accounts)
        {
            if (account.Prospect__c == TRUE && account.ERP_Id__c == NULL && objectPermission.Account_Delete_Prospect__c == FALSE)
            {
                account.addError(System.Label.Delete_Error);
            }
            else if (((account.Prospect__c == TRUE && account.ERP_Id__c != NULL ) || account.Prospect__c == FALSE) && objectPermission.Account_Delete_Non_Prospect__c == FALSE)
            {
                account.addError(System.Label.Delete_Error);
            }
        }
    }
    
    public static void deleteChildRecords(Set<Id> accounts)
    {
        //system.debug('accounts : '+accounts);
        List<Project_Account__c> projectAccounts = new  List<Project_Account__c>();
        for(Project_Account__c projectAccount :[SELECT Id, Name, Project__c, Account__c FROM Project_Account__c where Account__c IN: accounts])
            projectAccounts.add(projectAccount);
        if(!projectAccounts.isEmpty())
            delete projectAccounts;

    }
}