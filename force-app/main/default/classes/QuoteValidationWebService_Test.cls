@isTest
private class QuoteValidationWebService_Test {
    static List<Account> mAccounts;
    static User mUser;
    static List<Address__c> mShipTos;
    static List<Sales_Organization__c> mSalesOrgs;
    static List<Sales_Organization_User__c> mSalesOrgUsers;
    static List<Opportunity> mOpportunities;
    static List<Material_Number__c> mMaterials;
    static List<String> materialNumbers = new List<String>();
    static List<Product2> mNewProducts2;
    Static List<PricebookEntry> mNewPricebookEntries = new List<PricebookEntry>();
    static Id STDPriceBookId;
    static Territory2Model terrModel;
    static Territory2 objTerr;
    static List<Territory2Type> terriType;
    static List<Organization_Structure__c> mOrgStructure;
    static List<Sales_Area_Detail__c> mSalesArea;
    
    static void setupTestData()
    {    
        Profile mProfile = [SELECT Id FROM Profile WHERE Name = 'Sales Person']; 
        insert mUser = new User(Alias = 'standt', Email='Integration@testorg.com', 
                                EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                                LocaleSidKey='en_US', ProfileId = mProfile.Id, 
                                TimeZoneSidKey='America/Los_Angeles', UserName='Integration@testorg.com', ERP_Id__c = 'user123');
        
        System.runAs (new User(Id = UserInfo.getUserId())){
            terriType = [SELECT id, DeveloperName from Territory2Type where DeveloperName = 'Managed_Accounts'];
            terrModel = [SELECT id, DeveloperName,State from Territory2Model where DeveloperName = 'Weir_Minerals'];
            insert objTerr = new Territory2(DeveloperName = 'TestTerritory', Territory2ModelId = terrModel.Id, Name='AM1_AM01_GB01', Territory2TypeId=terriType[0].Id);
        }
        
        System.runAs(mUser) 
        {
            STDPriceBookId = TestUtility.createSTDPriceBookRecords();
            mAccounts = TestUtility.createAccountRecords(1, True);
            mShipTos = TestUtility.createShippingRecords(1, mAccounts[0].id, True);
            mSalesOrgs = TestUtility.createSalesOrgRecords(1, 'GB01', True);
            mSalesOrgUsers = TestUtility.createSalesOrgUserRecords(1, mUser.Id, mSalesOrgs[0].id, True);
            mOrgStructure = TestUtility.createOrgStructureRecords(1,'GB01','AM01','AM1', null, '30', '00', True, objTerr.Id, True);
            mSalesArea = TestUtility.createSalesAreaRecords(1, mAccounts[0].Id, mOrgStructure[0].id, True);
            mOpportunities = TestUtility.createOpportunityRecords(1, mAccounts[0].id, mShipTos[0].id, mSalesOrgUsers[0].id, STDPriceBookId, 'AUD','30', '00',True, True);
            mMaterials = TestUtility.createMaterialRecords(2, 'Mat123', True);
            mNewProducts2 = TestUtility.createProductRecords(1, 'Z0003S0012CC000001', True);
            mNewPricebookEntries = TestUtility.createPricebookEntryRecords(1, mNewProducts2[0].Id, STDPriceBookId,'AUD', True);
        } 
    }
    
    @isTest static void QuoteUserValidated() 
    {              
        setupTestData();
        materialNumbers.add(mMaterials[0].Name);
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteValidationWebService.ValidationResult result = QuoteValidationWebService.QuoteValidation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c , opp.Opportunity_ID__c, materialNumbers);
        Test.stopTest();   
    }
    
    @isTest static void QuoteUserNotValidated() 
    {              
        setupTestData();
        materialNumbers.add(mMaterials[0].Name);
        String userERPID = mUser.ERP_Id__c+'1';
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteValidationWebService.ValidationResult result = QuoteValidationWebService.QuoteValidation(
            mAccounts[0].ERP_Id__c, userERPID, mShipTos[0].ERP_Id__c , opp.Opportunity_ID__c, materialNumbers);
        Test.stopTest();   
    }
    
    @isTest static void QuoteAccountNotValidated() 
    {              
        setupTestData();
        materialNumbers.add(mMaterials[0].Name);
        String accERPID = mAccounts[0].ERP_Id__c+'1';
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteValidationWebService.ValidationResult result = QuoteValidationWebService.QuoteValidation(
            accERPID, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c , opp.Opportunity_ID__c, materialNumbers);
        Test.stopTest();   
    }
    
    @isTest static void QuoteShipToNotValidated() 
    {              
        setupTestData();
        materialNumbers.add(mMaterials[0].Name);
        String shipToERPID = mShipTos[0].ERP_Id__c+'1';
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteValidationWebService.ValidationResult result = QuoteValidationWebService.QuoteValidation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, shipToERPID , opp.Opportunity_ID__c, materialNumbers);
        Test.stopTest();   
    }
    
    
    @isTest static void QuoteMaterialNotValidated() 
    {              
        setupTestData();
        materialNumbers.add(mMaterials[0].Name+'1');
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        Test.startTest();
        QuoteValidationWebService.ValidationResult result = QuoteValidationWebService.QuoteValidation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c , opp.Opportunity_ID__c, materialNumbers);
        Test.stopTest();   
    }
    
    @isTest static void OppIdNotValidated() 
    {              
        setupTestData();
        materialNumbers.add(mMaterials[0].Name);
        Opportunity opp = [SELECT Id, Opportunity_ID__c FROM Opportunity WHERE id =: mOpportunities[0].id];
        String OppId = opp.Opportunity_ID__c+'1';
        Test.startTest();
        QuoteValidationWebService.ValidationResult result = QuoteValidationWebService.QuoteValidation(
            mAccounts[0].ERP_Id__c, mUser.ERP_Id__c, mShipTos[0].ERP_Id__c , OppId, materialNumbers);
        Test.stopTest();   
    }
}