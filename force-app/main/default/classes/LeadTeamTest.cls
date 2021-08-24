@isTest
public class LeadTeamTest 
{
	static final String TEST_USERNAME = 'testuser@mail.weir.invalid';    
    static final String LEAD_NAME = 'Test';
    static final String SHARING_REASON = 'Manual';
    static final String TEAM_ACCESS_EDIT = 'Edit';
    static final String TEAM_ROLE_ACCOUNT_MANAGER = 'Account Manager';
    static final String TEAM_ROLE_CHANNEL_MANAGER = 'Channel Manager';
    
    @testSetup
    static void setupData()
    {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User user = new User(Alias = 'standt', Email='standarduser@example.com', EmailEncodingKey='UTF-8', 
                          LastName='Testing', LanguageLocaleKey='en_US',LocaleSidKey='en_US', ProfileId = profile.Id,
        				  TimeZoneSidKey='America/Los_Angeles', UserName = TEST_USERNAME);
        insert user;        
        Lead lead = new Lead(LastName = LEAD_NAME, Company = LEAD_NAME);
        insert lead; 
    }
    
    @isTest
    static void testInsertLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT);
        
        Test.startTest();
        insert leadTeam;
        Test.stopTest();
        
        List<LeadShare> leadShares = [SELECT Id FROM LeadShare WHERE LeadId = :lead.Id AND UserOrGroupId = :user.Id AND RowCause = :SHARING_REASON];
        System.assertEquals(1, leadShares.size());
    }
    
    @isTest
    static void testUpdateLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT);
        
        Test.startTest();
        insert leadTeam;        
        update leadTeam;
        Test.stopTest();
        
        List<LeadShare> leadShares = [SELECT Id FROM LeadShare WHERE LeadId = :lead.Id AND UserOrGroupId = :user.Id AND RowCause = :SHARING_REASON];
        System.assertEquals(1, leadShares.size());
    }

    @isTest
    static void testDeleteLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT);
        
        Test.startTest();
        insert leadTeam;        
        delete leadTeam;
        Test.stopTest();
        
        List<LeadShare> leadShares = [SELECT Id FROM LeadShare WHERE LeadId = :lead.Id AND UserOrGroupId = :user.Id AND RowCause = :SHARING_REASON];
        System.assertEquals(0, leadShares.size());
    }

	@isTest
	static void testDeleteDefaultLeadTeam()
    {
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
        insert defaultLeadTeam;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(defaultLeadTeam);
        DeleteDefaultLeadTeamController ctrl = new DeleteDefaultLeadTeamController(sc);
        ctrl.deleteRecord();
        Test.stopTest();
        
        List<Default_Lead_Team__c> defaultLeadTeams = [SELECT Id FROM Default_Lead_Team__c WHERE Id = :defaultLeadTeam.Id];
        System.assertEquals(0, defaultLeadTeams.size());        
    }
    
	@isTest
	static void testDeleteDefaultLeadTeam_WithDeleteLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
        insert defaultLeadTeam;        
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT);
        insert leadTeam;

        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(defaultLeadTeam);
        DeleteDefaultLeadTeamController ctrl = new DeleteDefaultLeadTeamController(sc);
        ctrl.deleteLeadTeam = true;
        ctrl.deleteRecord();
        ctrl.cancel();
        Test.stopTest();
        
        List<Default_Lead_Team__c> defaultLeadTeams = [SELECT Id FROM Default_Lead_Team__c WHERE Id = :defaultLeadTeam.Id];
        System.assertEquals(0, defaultLeadTeams.size()); 
        List<Lead_Team__c> leadTeams = [SELECT Id FROM Lead_Team__c WHERE Lead__c = :lead.Id];
        System.assertEquals(0, leadTeams.size());          
    } 
    
	@isTest
	static void testCreateDefaultLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);        		        
        
        Test.startTest();
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultLeadTeams);
        CreateDefaultLeadTeamController ctrl = new CreateDefaultLeadTeamController(sc);    
        ctrl.defaultLeadTeams.add(defaultLeadTeam);        
        ctrl.save();        
        Test.stopTest();
        
        List<Default_Lead_Team__c> defaultLeadTeamsInDB = [SELECT Id FROM Default_Lead_Team__c WHERE OwnerId = :System.UserInfo.getUserId()];
        System.assertEquals(1, defaultLeadTeamsInDB.size());        
    }

	@isTest
	static void testCreateDefaultLeadTeam_WithUpdateLeadTeam_ExistingLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);        		          
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT);
        insert leadTeam;       
        
        Test.startTest();
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultLeadTeams);
        CreateDefaultLeadTeamController ctrl = new CreateDefaultLeadTeamController(sc);    
        ctrl.defaultLeadTeams.add(defaultLeadTeam);
		ctrl.updateLeadTeam = true;        
        ctrl.saveAndMore();
		ctrl.cancel();        
        Test.stopTest();
        
        List<Lead_Team__c> leadTeamsInDB = [SELECT Id FROM Lead_Team__c WHERE Lead__c = :lead.Id];
        System.assertEquals(1, leadTeamsInDB.size());        
    }
    
	@isTest
	static void testCreateDefaultLeadTeam_WithUpdateLeadTeam_NewLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);  		                  
        
        Test.startTest();
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultLeadTeams);
        CreateDefaultLeadTeamController ctrl = new CreateDefaultLeadTeamController(sc);    
        ctrl.defaultLeadTeams.add(defaultLeadTeam);
		ctrl.updateLeadTeam = true;        
        ctrl.saveAndMore();
		ctrl.cancel();        
        Test.stopTest();
        
        List<Lead_Team__c> leadTeamsInDB = [SELECT Id FROM Lead_Team__c WHERE Lead__c = :lead.Id];
        System.assertEquals(1, leadTeamsInDB.size());        
    }    
    
	@isTest
	static void testCreateDefaultLeadTeam_ExistingDefaultLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
		insert defaultLeadTeam;     
        
        Test.startTest();
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultLeadTeams);
        CreateDefaultLeadTeamController ctrl = new CreateDefaultLeadTeamController(sc);    
        defaultLeadTeam.Id = null;
        defaultLeadTeam.Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER;
        ctrl.defaultLeadTeams.add(defaultLeadTeam);		        
        ctrl.save();		
        Test.stopTest();
        
        List<Default_Lead_Team__c> defaultLeadTeamsInDB = [SELECT Team_Role__c FROM Default_Lead_Team__c WHERE OwnerId = :System.UserInfo.getUserId()];
        System.assertEquals(1, defaultLeadTeamsInDB.size()); 
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, defaultLeadTeamsInDB.get(0).Team_Role__c); 
    }
    
	static void testCreateDefaultLeadTeam_ExistingLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);		        		          
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER);
        insert leadTeam;       
        
        Test.startTest();
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(defaultLeadTeams);
        CreateDefaultLeadTeamController ctrl = new CreateDefaultLeadTeamController(sc);    
        ctrl.updateLeadTeam = true;
        defaultLeadTeam.Id = null;        
        ctrl.defaultLeadTeams.add(defaultLeadTeam);		        
        ctrl.save();		
        Test.stopTest();
        
        List<Lead_Team__c> leadTeamsInDB = [SELECT Team_Role__c FROM Lead_Team__c WHERE Lead__c = :lead.Id];
        System.assertEquals(1, leadTeamsInDB.size());  
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, leadTeamsInDB.get(0).Team_Role__c);
    }
    
	@isTest
	static void testEditDefaultLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Default_Lead_Team__c defaultLeadTeam = new Default_Lead_Team__c(Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);        		        
        insert defaultLeadTeam;
        
        Test.startTest();
        List<Default_Lead_Team__c> defaultLeadTeams = new List<Default_Lead_Team__c>();
        ApexPages.StandardController sc = new ApexPages.StandardController(defaultLeadTeam);
        EditDefaultLeadTeamController ctrl = new EditDefaultLeadTeamController(sc);  
        defaultLeadTeam.Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER;
        ctrl.defaultLeadTeam = defaultLeadTeam;
        ctrl.save();     
        ctrl.cancel();
        Test.stopTest();
        
        List<Default_Lead_Team__c> defaultLeadTeamsInDB = [SELECT Team_Role__c FROM Default_Lead_Team__c WHERE OwnerId = :System.UserInfo.getUserId()];
        System.assertEquals(1, defaultLeadTeamsInDB.size()); 
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, defaultLeadTeamsInDB.get(0).Team_Role__c);
    }

    @isTest
    static void testCreateOrUpdateLeadTeam_NewLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT);
        List<Lead_Team__c> leadTeams = new List<Lead_Team__c>();
        leadTeams.add(leadTeam);
        
        Test.startTest();
        LeadTeamController.createOrUpdateLeadTeam(leadTeams);
        Test.stopTest();
        
        List<Lead_Team__c> leadTeamsInDB = [SELECT Id FROM Lead_Team__c WHERE Lead__c = :lead.Id];
        System.assertEquals(1, leadTeamsInDB.size());
    } 
    
    @isTest
    static void testCreateOrUpdateLeadTeam_ExistingLeadTeam()
    {
        Lead lead = [SELECT Id FROM Lead WHERE LastName = :LEAD_NAME];
        User user = [SELECT Id FROM User WHERE Username = :TEST_USERNAME];
        Lead_Team__c leadTeam = new Lead_Team__c(Lead__c = lead.Id, Team_Member__c = user.Id, Lead_Access__c = TEAM_ACCESS_EDIT, Team_Role__c = TEAM_ROLE_ACCOUNT_MANAGER);
        insert leadTeam;
        List<Lead_Team__c> leadTeams = new List<Lead_Team__c>();
        leadTeams.add(leadTeam);
        
        Test.startTest();
        leadTeam.Team_Role__c = TEAM_ROLE_CHANNEL_MANAGER;
        LeadTeamController.createOrUpdateLeadTeam(leadTeams);
        Test.stopTest();
        
        List<Lead_Team__c> leadTeamsInDB = [SELECT Team_Role__c FROM Lead_Team__c WHERE Lead__c = :lead.Id];
        System.assertEquals(1, leadTeamsInDB.size());
        System.assertEquals(TEAM_ROLE_CHANNEL_MANAGER, leadTeamsInDB.get(0).Team_Role__c);
    }     
}