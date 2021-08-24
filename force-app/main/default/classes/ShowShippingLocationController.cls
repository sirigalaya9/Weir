public class ShowShippingLocationController {
    @AuraEnabled
    public static List<Location> getShippingLocation(Id arecordId) {
        List<Address__c> shipAddress = [SELECT Id, Name, Account__c, Street__c, City__c, State__c, PostalCode__c, Country__c FROM Address__c where Id = :arecordId];
        List<Location> locations = new List<Location>();
        for(Address__c pdt : shipAddress){
            GeoLocation geoInfo = new GeoLocation();
            geoInfo.Street = pdt.Street__c;
            geoInfo.PostalCode = pdt.PostalCode__c;
            geoInfo.City = pdt.City__c;
            geoInfo.State = pdt.State__c;
            geoInfo.Country = pdt.Country__c;
            Location locDetail = new Location();
            locDetail.icon = 'action:map'; 
            locDetail.title = pdt.Name;
            locDetail.description = pdt.Name;
            locDetail.location = geoInfo;
            
            locations.add(locDetail);
        }
        return locations ;
    }
    
    public class Location{
        @AuraEnabled 
        public String icon{get;set;} 
        @AuraEnabled 
        public String title{get;set;} 
        @AuraEnabled
        public String description{get;set;} 
        @AuraEnabled 
        public GeoLocation location{get;set;} 
    }
    public class GeoLocation{
        @AuraEnabled 
        public String Street{get;set;}
        @AuraEnabled 
        public String PostalCode{get;set;}
        @AuraEnabled 
        public String City{get;set;}
        @AuraEnabled 
        public String State{get;set;}
        @AuraEnabled 
        public String Country{get;set;}
    }

}