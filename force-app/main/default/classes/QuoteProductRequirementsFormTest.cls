@isTest
public class QuoteProductRequirementsFormTest 
{
    @TestSetup
    static void setupData()
    {        
        Cyclone_Master__c data = new Cyclone_Master__c();
        data.Location__c = 'Istanbul';
        data.Model_Name__c = 'CVX';
        data.Model_Size__c = '100';
        insert data;

        Product_Price__c price = new Product_Price__c();
        price.Name = 'U02';
        price.Amount__c = 1;
        insert price;
    }

    @isTest
    static void testGetMasterData()
    {
        Cyclone_Master__c data = [SELECT Id FROM Cyclone_Master__c];
        Cyclone_Master__c result = QuoteProductRequirementsFormController.getMasterData('Istanbul', 'CVX', '100');
        System.assertEquals(data.Id, result.Id, 'Return Id must match');
    }

    @isTest
    static void testGetPriceData()
    {
        List<Product_Price__c> prices = QuoteProductRequirementsFormController.getPriceData();
        System.assertEquals(1, prices.size(), '1 Price should be returned');
    }    
}