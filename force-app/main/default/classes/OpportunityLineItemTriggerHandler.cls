public class OpportunityLineItemTriggerHandler {
    
    public static Set<Id> oppIds = new Set <Id>();
    public static Set<Id> MaterialIds = new Set<Id>();    
    public static String saleOrgCode ;
    public static List<String> saleOrgCodes = new List<String>();
    public static List<String> invalidHierarchyList = new List<String>();
    public static Map<String,Id> pbEntryMap = new Map<String,Id>();
    public static Map<String,String> invalidHierarchyMap = new Map<String,String>();
    public static Map<Id,String> oppSaleOrgMap = new Map<Id,String>();
    public static Map<Id, List<OpportunityLineItem >> oppItemsMap = new Map<Id, List<OpportunityLineItem >>();
    public static Map<String, List<Sales_Organization_Material__c >> saleOrgMaterialMap = new Map<String, List<Sales_Organization_Material__c >>();
    public static Map<String,Sales_Organization_Material__c> saleOrgMaterialChannelMap = new Map<String,Sales_Organization_Material__c>();
    
    public static void ValidateSalesOrgMaterialmethod(List<OpportunityLineItem> mNewOppLineItem, String TriggerEvent)
    {
        Id profileId = userinfo.getProfileId();
        String profileName = [Select Id,Name from Profile where Id=:profileId].Name;
        system.debug('ProfileName: '+profileName);
        
        System.debug('opportunityItem Size: '+mNewOppLineItem.size());            
        for(OpportunityLineItem oli : mNewOppLineItem)
        {
            if (oli.Material_Number__c != null)
            {
                MaterialIds.add(oli.Material_Number__c);
                if(oli.ProductHierarchy__c != oli.MaterialHierarchy__c && oli.MaterialHierarchy__c != null)
                    invalidHierarchyList.add(oli.MaterialHierarchy__c);
            }
            
            if(!oppItemsMap.containsKey(oli.OpportunityId)){
                oppItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem >{oli});
            }
            else{
                oppItemsMap.get(oli.OpportunityId).add(oli);
            }
        }

        System.debug(invalidHierarchyList.size()+'  invalidHierarchyList: '+invalidHierarchyList);
        
        List<Opportunity> opportunities = [SELECT Id, Name, Sales_Organization_User__c ,Sales_Organization_User__r.code__c, 
                                           OwnerId, Recordtype.Name, CurrencyIsoCode, Channel__c, Number_of_Quotations__c, Lock_Opportunity__c
                                           FROM Opportunity WHERE Id IN :oppItemsMap.keySet()];
        
        for (Opportunity opportunity : opportunities)
        {
            if(opportunity.Sales_Organization_User__c != null)
            {
                saleOrgCodes.add(opportunity.Sales_Organization_User__r.code__c);
            }
        }
        
        List<Sales_Organization_Material__c> saleOrgMaterials = [SELECT Id, Code__c, Material_Number__c, Material_Number__r.Name, Material_Number__r.Material_Status__c,
                                                                 Block__c, Deletion__c, Distribution_Channel__c 
                                                                 FROM Sales_Organization_Material__c
                                                                 WHERE Code__c IN: saleOrgCodes AND Material_Number__c IN :MaterialIds AND Distribution_Channel__c != null];
        for (Sales_Organization_Material__c som : saleOrgMaterials)
        {            
            if(!saleOrgMaterialMap.containsKey(som.Code__c + som.Material_Number__c)){
                saleOrgMaterialMap.put(som.Code__c + som.Material_Number__c, new List<Sales_Organization_Material__c >{som});
            }
            else{
                saleOrgMaterialMap.get(som.Code__c + som.Material_Number__c).add(som);
            }
           
            if(!saleOrgMaterialChannelMap.containsKey(som.Code__c + som.Material_Number__c + som.Distribution_Channel__c)){
                saleOrgMaterialChannelMap.put(som.Code__c + som.Material_Number__c + som.Distribution_Channel__c, som);
            }
        }
        
        
        for (Opportunity opportunity : opportunities) 
        {
            Boolean validated = true;
            if(opportunity.Recordtype.Name.contains('SGT'))
            {
                if(opportunity.Number_of_Quotations__c > 0 && opportunity.Lock_Opportunity__c == true  && profileName != 'Integration') //&& profileName != 'System Administrator'
                {
                    /*for(OpportunityLineItem oli2 : mNewOppLineItem)
                    {
                        oli2.addError('A Quote has been created, Cannot update opportunity items');
                        validated = false;
                        break;
                    }*/
                }
                else
                {
                    if(opportunity.Sales_Organization_User__c != null)
                    {
                        String saleOrgCode = opportunity.Sales_Organization_User__r.code__c;
                        System.debug('Trigger OpportunityLineItemTriggerHandler');
                        System.debug('saleOrgCode: '+saleOrgCode);
                        if(!MaterialIds.isEmpty())
                        {   
                            system.debug(opportunity.Id+' has Items size '+oppItemsMap.get(opportunity.Id).size());
                            for(OpportunityLineItem oli1 : oppItemsMap.get(opportunity.Id))
                            {
                                //system.debug('oli ------------ '+oli1);
                                if(profileName != 'System Administrator' && profileName != 'Integration')
                                {
                                    // Check Sale Org Material
                                    if(!saleOrgMaterialMap.isEmpty() && saleOrgMaterialMap.containsKey(saleOrgCode + oli1.Material_Number__c))
                                    { 
                                        system.debug('saleOrgMateria size '+saleOrgMaterialMap.get(saleOrgCode + oli1.Material_Number__c).size());
                                        
                                        if(saleOrgMaterialChannelMap.containsKey(saleOrgCode + oli1.Material_Number__c + opportunity.Channel__c))
                                        {
                                            Sales_Organization_Material__c saleOrgMat = saleOrgMaterialChannelMap.get(saleOrgCode + oli1.Material_Number__c + opportunity.Channel__c);
                                            system.debug('saleOrgMat '+saleOrgMat);
                                            if(saleOrgMat.Block__c == true || saleOrgMat.Deletion__c == true)
                                            {
                                                oli1.addError('Material '+saleOrgMat.Material_Number__r.Name+' is blocked for '+saleOrgCode+ '/'+opportunity.Channel__c);
                                                System.debug('Material '+saleOrgMat.Material_Number__r.Name+' is blocked for '+saleOrgCode+ '/'+opportunity.Channel__c);
                                                validated = false;
                                                break;
                                            }
                                        }
                                        else
                                        {
                                            oli1.addError('This Material Number is not extended to Sales Org: '+ saleOrgCode+', Dis Channel: '+opportunity.Channel__c+' usage');
                                            System.debug('This Material Number is not extended to Sales Org: '+ saleOrgCode+', Dis Channel: '+opportunity.Channel__c+' usage');
                                            validated = false;
                                            break;
                                        }
                                    }
                                    else
                                    {
                                        oli1.addError('This material is not extended to Sales Org '+saleOrgCode+ ' usage');
                                        System.debug('This material is not extended to Sales Org '+saleOrgCode+ ' usage');
                                        validated = false;
                                        break;
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        for(OpportunityLineItem oli2 : mNewOppLineItem)
                        {
                            oli2.addError('Please enter User Sales Organization in Opportunity');
                            validated = false;
                            break;
                        }
                    } 
                }
            }
            else
            {
                System.debug('No SalesOrg Product Validation and Populate ProductHierarchy for Standalone Record Type');
                validated = false;
            }
            
            //--------------------Validate Product Hierarchy-------------------------------------------//
            
            if(TriggerEvent == 'IsInsert' && validated == true)
            {
                if(!invalidHierarchyList.isEmpty())
                {
                    PopulateProductHierarchy(mNewOppLineItem,invalidHierarchyList,Opportunity);
                }
            }
        }      
        
    }
    
    public static void PopulateProductHierarchy(List<OpportunityLineItem> mNewOppLineItem, List<String> invalidHierarchyList, Opportunity mOpportunity)
    {
        System.debug(invalidHierarchyList.size()+'  invalidHierarchyList: '+invalidHierarchyList);
        for(PricebookEntry pbEntry : [SELECT Id, Name, Pricebook2Id, CurrencyIsoCode, Product2.Third_Level_Product_Hierarchy__c
                                      FROM PricebookEntry WHERE IsActive = true AND CurrencyIsoCode =: mOpportunity.CurrencyIsoCode
                                      AND Product2.Third_Level_Product_Hierarchy__c IN: invalidHierarchyList])
        {
            pbEntryMap.put(pbEntry.Product2.Third_Level_Product_Hierarchy__c, pbEntry.id);
            System.debug('pbEntryMap Size : '+pbEntryMap.size()+' pbEntryMap: ' + pbEntryMap);
            for(OpportunityLineItem oli : mNewOppLineItem)
            {
                for(String hierarchy : invalidHierarchyList)
                {
                    if(oli.MaterialHierarchy__c == hierarchy)
                    {
                        //system.debug('Update hierarchy : '+hierarchy);
                        oli.PricebookEntryId = pbEntryMap.get(hierarchy);
                        oli.Update_Product_Hierarchy__c = true;
                    }
                }
            }
        }
    } 
}