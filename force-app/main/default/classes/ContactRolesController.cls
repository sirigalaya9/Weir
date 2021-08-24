public class ContactRolesController 
{
    @AuraEnabled
    public static List<Contact> fetchData(String searchKeyWord, Id parentId)
    {
        list<Contact> contacts = new list<Contact>();
        List<List<sObject>> searchList;
        if (parentId != null){
            if (searchKeyWord == null) searchKeyWord ='';
            String searchKey = '%'+ searchKeyword + '%';
            Project__c project = [SELECT Account__c FROM Project__c WHERE Id =: parentId];
            String q = 'SELECT Id, Name, AccountId, Account.Name, Phone, Email, Owner.Alias FROM Contact WHERE (Name LIKE \''+searchKey+'\''+
                ' OR Phone LIKE \''+searchKey+'\''+' OR Email LIKE \''+searchKey+'\')';
            if (searchKeyWord == '')
                q = q + 'AND AccountId =\''+project.Account__c+'\'';
            q = q +' ORDER BY Name ASC';
            //q = q +' LIMIT 30';
            //system.debug('q : '+q);
            for(Contact con : Database.query(q)){
                contacts.add(con);
            }
        }
        return contacts;
    }
    
    @AuraEnabled
    public static Contact fetchDataById(Id recordId)
    {
        return [SELECT Id, Name, AccountId, Account.Name, Phone, Email, Owner.Alias FROM Contact WHERE Id = :recordId];
    }    
    
    @AuraEnabled
    public static List<Project_Contact_Role__c> getPrimaryContact(Id parentId)
    {
        list<Project_Contact_Role__c> ProjectContactRoles = new list<Project_Contact_Role__c>();
        if (parentId != null){
            ProjectContactRoles = [SELECT Id, Contact__r.Name, Contact__c, Is_Primary__c, Role__c FROM Project_Contact_Role__c 
                                   WHERE Project__c =: parentId AND Is_Primary__c = TRUE];
        }

        return ProjectContactRoles;
    }
    
    @AuraEnabled
    public static List<Project_Contact_Role__c> getProjectContactRoles(Id parentId)
    {
        list<Project_Contact_Role__c> ProjectContactRoles = new list<Project_Contact_Role__c>();
        if (parentId != null){
            ProjectContactRoles = [SELECT Id, AccountName__c, ContactName__c, Contact__r.Account.Name, Contact__r.Name, Contact__c, Is_Primary__c, Role__c FROM Project_Contact_Role__c 
                                   WHERE Project__c =: parentId ORDER BY ContactName__c];
        }
        
        if(!ProjectContactRoles.isEmpty())
        {
            for(Project_Contact_Role__c pro : ProjectContactRoles){
                system.debug(pro.Contact__r.Name); 
            }  
        }
        return ProjectContactRoles;
    }
    
    @AuraEnabled
    public static void createOrUpdateProjectContactRole(List<Project_Contact_Role__c> projectContactRoles)
    {
        System.debug(projectContactRoles);
        
        Map<Id, Project_Contact_Role__c> projectContactRolesMap = new Map<Id, Project_Contact_Role__c>();
        Id projectId;
        for(Project_Contact_Role__c projectContactRole : projectContactRoles)
        {
            projectContactRolesMap.put(projectContactRole.Id, projectContactRole);
            projectId = projectContactRole.Project__c;
        }
        
        {
            List<Project__c> ownedProjects = [SELECT Id, (SELECT Id, Contact__c FROM Project_Contact_Roles__r
                                                          WHERE Id IN :projectContactRolesMap.keySet()) 
                                              FROM Project__c WHERE Id = :projectId];
            List<Project_Contact_Role__c> newProjectContactRoles = new List<Project_Contact_Role__c>();
            List<Project_Contact_Role__c> existingProjectContactRoles = new List<Project_Contact_Role__c>();
            List<Id> ownedProjectIds = new List<Id>();
            for (Project__c ownedProject : ownedProjects)
            {
                Set<Id> contactExisting = new Set<Id>();
                if (ownedProject.Project_Contact_Roles__r != NULL && ownedProject.Project_Contact_Roles__r.size() > 0)
                {                        
                    for (Project_Contact_Role__c existingProjectContactRole : ownedProject.Project_Contact_Roles__r)
                    {
                        if (projectContactRolesMap.containsKey(existingProjectContactRole.Id))
                        {
                            
                            Project_Contact_Role__c projectContactRole = projectContactRolesMap.get(existingProjectContactRole.Id);
                            system.debug('existing : '+projectContactRole.Contact__c);
                            existingProjectContactRole.Contact__c = projectContactRole.Contact__c;
                            existingProjectContactRole.Role__c = projectContactRole.Role__c;
                            existingProjectContactRole.Is_Primary__c = projectContactRole.Is_Primary__c;
                            existingProjectContactRoles.add(existingProjectContactRole);
                            contactExisting.add(existingProjectContactRole.Id);
                            system.debug('contactExisting : '+contactExisting);
                        }
                    }                       
                }
                for (Id RecordId : projectContactRolesMap.keySet())
                {
                    if (!contactExisting.contains(RecordId) || RecordId == null)
                    {
                        system.debug('RecordId : '+RecordId);                        
                        Project_Contact_Role__c projectContactRole = projectContactRolesMap.get(RecordId);
                        system.debug('New : '+projectContactRole.Contact__c);
                        Project_Contact_Role__c newProjectContactRole = new Project_Contact_Role__c(Project__c = ownedProject.Id);
                        newProjectContactRole.Contact__c = projectContactRole.Contact__c;
                        newProjectContactRole.Role__c = projectContactRole.Role__c;
                        newProjectContactRole.Is_Primary__c = projectContactRole.Is_Primary__c;
                        newProjectContactRoles.add(newProjectContactRole);
                    }                          
                }
            }
            
            insert newProjectContactRoles;
            update existingProjectContactRoles;
        }        
    }

}