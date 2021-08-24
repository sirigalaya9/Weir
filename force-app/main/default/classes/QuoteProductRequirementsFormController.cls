public without sharing class QuoteProductRequirementsFormController 
{
    @AuraEnabled
    public static Cyclone_Master__c getMasterData(String location, String modelName, String modelSize)
    {
        return 
        [SELECT Id,
        Plasson_Nut__c,
        Feed_Matching_Piece__c,
        Feed_Flange__c,
        Vortex_Finder__c,
        Cover__c,
        Cover_Line__c,
        Wedge__c,
        Feed_Chamber__c,
        Feed_Chamber_Liner__c,
        Cone__c,
        Coner_Liner__c,
        Spigot_Holder__c,
        Spigot_Liner__c,
        Spray_Guard_Holder__c,
        Spray_Guard_Liner__c,
        Quick_Release_Clamp__c,
        Fasteners__c,
        DWKit__c,
        Overflow_Bend__c,
        Mounting_Plate__c,
        Lip_Seal__c,
        Pressure_Flange__c,
        Commissioning_Kit__c,
        Overflow_Adaptor__c,
        Synertrex__c,
        ACB_Core_Booster__c,
        Extension__c,
        Extension_Liner__c
        FROM 
        Cyclone_Master__c 
        WHERE
        Location__c = :location
        AND Model_Name__c = :modelName
        AND Model_Size__c = :modelSize];
    }

    @AuraEnabled
    public static List<Product_Price__c> getPriceData()
    {
        return 
        [SELECT Id,
        Name,
        Amount__c
        FROM 
        Product_Price__c];
    }    
}