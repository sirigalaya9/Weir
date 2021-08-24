@isTest
public class ShowShippingLocationController_Test {
    public static List<Address__c> shipAddress = new List<Address__c>();
    
    static void init() 
    {
        shipAddress.add(new Address__c(Street__c= 'Street',PostalCode__c= '1234',
                                       City__c= 'City', State__c= 'State', Country__c= 'Thiland'));
        insert shipAddress;
    }
    
    @isTest
    public static void ShowShiipingLocation() 
    {
        init();
        Test.startTest();
        ShowShippingLocationController.getShippingLocation(shipAddress[0].id);
        Test.stopTest();
    }
}