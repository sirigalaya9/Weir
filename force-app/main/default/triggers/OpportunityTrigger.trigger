trigger OpportunityTrigger on Opportunity (Before insert, Before update, After update, After insert, After delete) {
    Map<Id, List<OpportunityLineItem >> oppItemsMap = new Map<Id, List<OpportunityLineItem >>();
    Map<Id, List<Sales_Organization_User__c >> saleOrgMap = new Map<Id, List<Sales_Organization_User__c >>();
    Map<Id, List<Account >> accountMap = new Map<Id, List<Account >>();
    Map<Id, List<Sales_Area_Detail__c >> accSaleAreaMap = new Map<Id, List<Sales_Area_Detail__c >>();
    Map<Id, String> accountCurrMap = new Map<Id, String>();
    Map<Id, Id> oppToSalesOrgMap = new Map<Id, Id>();
    
    List<Id> ownerIdList = new List<Id>();
    List<OpportunityLineItem> olisToDelete = new List<OpportunityLineItem>();
    Set<Id> accountIdSet = new Set<Id>();
    Set<Id> OppIdSet = new Set<Id>();
    Set<Id> quoteDate_OppIdSet = new Set<Id>();
    
    List<Sales_Area_Detail__c> salesArea;
    List<Sales_Area_Detail__c> mSaleAreaDetails;
    List<Organization_Structure__c> orgStruc;
    List<ObjectTerritory2Association> mAccTerritories;
    
    List<Id> projectIds = new List<Id>();
    List<Project__c> updatedProjs;
    
    if(Trigger.isBefore)
    {
        for(Opportunity opp : Trigger.New){
            ownerIdList.add(opp.OwnerId);
            accountIdSet.add(opp.AccountId);
            if(Trigger.IsUpdate)
            {
                oppIdSet.add(opp.Id);
                oppToSalesOrgMap.put(opp.Id, opp.Sales_Organization_Formula__c);
            }
            if(opp.isClone()) opp.erp_id__c = null;
        }
    }
    else // isAfter
    {
        if(Trigger.isDelete)
        {
            for( Opportunity mOpp: Trigger.Old)
            {
                projectIds.add(mOpp.project__c);
            }
        }
        else // isInsert or isUpdate
        {
            for(Opportunity opp : Trigger.New){
                if((Trigger.IsInsert || opp.Project__c != Trigger.oldMap.get(opp.Id).Project__c ||
                    opp.Amount != Trigger.oldMap.get(opp.Id).Amount || opp.Publish_to_Forecast__c!= Trigger.oldMap.get(opp.Id).Publish_to_Forecast__c ||
                    opp.CurrencyISOCode != Trigger.oldMap.get(opp.Id).CurrencyISOCode || opp.StageName != Trigger.oldMap.get(opp.Id).StageName) && 
                   opp.Project__c!=null) 
                {
                    projectIds.add(opp.project__c);
                    system.debug('projectIds isAfter: '+projectIds);
                }
                else if(Trigger.isUpdate && opp.Project__c != Trigger.oldMap.get(opp.Id).Project__c && 
                        opp.Project__c == null && Trigger.oldMap.get(opp.Id).Project__c !=null)
                {
                    projectIds.add(Trigger.oldMap.get(opp.Id).project__c); 
                }
                
                //When 'CloseDate' OR 'Expected_Delivery_Date__c' OR any of 5 additional fields changed
                if(Trigger.isUpdate && (opp.CloseDate != Trigger.oldMap.get(opp.Id).CloseDate || opp.Expected_Delivery_Date__c != Trigger.oldMap.get(opp.Id).Expected_Delivery_Date__c
                || opp.Application__c != Trigger.oldMap.get(opp.Id).Application__c
                || opp.Integrated_Solution__c != Trigger.oldMap.get(opp.Id).Integrated_Solution__c
                || opp.Other_Strategic_Initiatives__c != Trigger.oldMap.get(opp.Id).Other_Strategic_Initiatives__c
                || opp.Important__c != Trigger.oldMap.get(opp.Id).Important__c
                || opp.Managed_by_Project_Teams__c != Trigger.oldMap.get(opp.Id).Managed_by_Project_Teams__c))
                {
                    quoteDate_OppIdSet.add(opp.Id);
                }
            }
        }
    }
    
    if(!ownerIdList.isEmpty()){
        for(Sales_Organization_User__c saleOrg : [SELECT Id, Name, Code__c, User__c, Sales_Organizationa__c FROM Sales_Organization_User__c where User__c IN: ownerIdList]){
            if(!saleOrgMap.containsKey(saleOrg.User__c)){
                saleOrgMap.put(saleOrg.User__c, new List<Sales_Organization_User__c >{saleOrg});
            }
            else{
                saleOrgMap.get(saleOrg.User__c).add(saleOrg);
            }        
        }
    }
    
    if(!OppIdSet.isEmpty()){
        for(OpportunityLineItem  oppItem : [SELECT Id, OpportunityId FROM OpportunityLineItem  where OpportunityId IN: OppIdSet]){
            if(!oppItemsMap.containsKey(oppItem.OpportunityId)){
                oppItemsMap.put(oppItem.OpportunityId, new List<OpportunityLineItem >{oppItem});
            }
            else{
                oppItemsMap.get(oppItem.OpportunityId).add(oppItem);
            }     
        }
    }
    
    if(!accountIdSet.isEmpty()){
        for(Account account: [SELECT Id,ERP_ID__c, Prospect__c,CurrencyISOCode,(SELECT Id, Organization_Structure__c from Sales_Area_Details__r) FROM Account where Id IN: accountIdSet]){  
            if(!accountCurrMap.containsKey(account.Id)){
                accountCurrMap.put(account.Id, account.CurrencyISOCode);
            }
            if(!accountMap.containsKey(account.Id)){
                accountMap.put(account.Id, new List<Account>{account});
            }
            if(!accSaleAreaMap.containsKey(account.Id)){
                accSaleAreaMap.put(account.Id, account.Sales_Area_Details__r);
            }      
        }
    }
    
    if(!quoteDate_OppIdSet.isEmpty()){
        OpportunityTriggerHandler.SyncDateToSAP(quoteDate_OppIdSet);
    }
    
    if (Trigger.isAfter && projectIds.size() >0)
        updatedProjs = OpportunityTriggerHandler.PoppulateTotalOpportunitySum(projectIds);
    else
    {
        for(Opportunity opp : Trigger.New){
            if(Trigger.isBefore){ 
                //if(oppItemsMap.containsKey(opp.id)) system.debug('oppItemsMap.get(opp.Id).size() : '+oppItemsMap.get(opp.id).size());
                string recordTypeName = Schema.SObjectType.Opportunity.getRecordTypeInfosById().get(opp.recordtypeid).getname();  
                Opp_Transfer_Owner__c userMC = Opp_Transfer_Owner__c.getInstance(opp.OwnerProfileID__c);
                
                if((Trigger.IsInsert) || (Trigger.IsUpdate && (opp.OwnerId != Trigger.oldMap.get(opp.Id).OwnerId || opp.recordtypeid != Trigger.oldMap.get(opp.Id).recordtypeid))){         
                    if(Trigger.IsUpdate && (recordTypeName.contains('SGT') && userMC.SGT_Profile__c == false || recordTypeName.contains('Standalone') && userMC.Non_SGT_Profile__c == false))
                        opp.addError('The opportunity owner cannot transfer to a different Record Type. Kindly contact System Administrator.');
                    else{  
                        if((!saleOrgMap.containsKey(opp.OwnerId)||saleOrgMap.get(opp.OwnerId).size()==0) && opp.ERP_Id__c != null){
                            opp.addError('Sales Org \''+opp.Sales_Organization_User_Code__c+'\' not found in the selected profile. Kindly contact System Administrator.');                                                                                  
                        }
                        //-------------------- One SalesOrg INSERTED -----------------------
                        else if(saleOrgMap.containsKey(opp.OwnerId) && saleOrgMap.get(opp.OwnerId).size()==1 && (Trigger.IsInsert || opp.isClone())){
                            opp.Sales_Organization_User__c = saleOrgMap.get(opp.OwnerId)[0].Id;
                            opp.Sales_Org_Code__c = saleOrgMap.get(opp.OwnerId)[0].Code__c;
                            system.debug('opp.Sales_Org_Code__c -- Only 1 SalesOrg : '+opp.Sales_Org_Code__c);
                            system.debug('User has only SalesOrg ' +saleOrgMap.get(opp.OwnerId)[0].Code__c);
                        }
                        //-------------------- One SalesOrg INSERTED -----------------------
                        
                        //-------------------- One & Multiple SalesOrg UPDATED -----------------------
                        else if(saleOrgMap.containsKey(opp.OwnerId) && saleOrgMap.get(opp.OwnerId).size()>=1 && (Trigger.IsUpdate || opp.isClone())){
                            opp.Sales_Organization_User__c  = null;
                            for (Sales_Organization_User__c  sales_org_user : saleOrgMap.get(opp.OwnerId) ){
                                if(sales_org_user.Sales_Organizationa__c == oppToSalesOrgMap.get(opp.Id)){
                                    opp.Sales_Organization_User__c = sales_org_user.Id;
                                    opp.Sales_Org_Code__c = sales_org_user.Code__c;
                                    system.debug('opp.Sales_Org_Code__c -- Multiple SalesOrg : '+opp.Sales_Org_Code__c);
                                    system.debug('Sales_Organization_User__c -- Multiple SalesOrg : '+opp.Sales_Organization_User__c);
                                    break;
                                }                
                            }
                            if (Trigger.IsUpdate && opp.Sales_Organization_User__c == null){
                                
                                if(opp.ERP_Id__c != null) {
                                    opp.addError('Sales Org \''+opp.Sales_Organization_User_Code__c+'\' not found in the selected profile. Inquiry is already created in SAP system. Kindly contact System Administrator.');
                                }
                                else if(saleOrgMap.get(opp.OwnerId).size()>1){
                                    opp.Sales_Office__c = null;
                                    opp.Sales_Group__c = null;
                                    opp.Sales_District__c = null; 
                                    opp.Organization_Structure__c = null;
                                    opp.Territory2Id =  null;
                                    system.debug('Multiple SalesOrg No ERPID CLEAR');
                                }
                                else{
                                    opp.Sales_Organization_User__c = saleOrgMap.get(opp.OwnerId)[0].Id;
                                    opp.Sales_Org_Code__c = saleOrgMap.get(opp.OwnerId)[0].Code__c;
                                    system.debug('Only 1 SalesOrg No ERPID');
                                }  
                            }
                            else if(opp.isClone() && opp.Sales_Organization_User__c == null)
                            {
                                opp.Sales_Org_Code__c = null;
                                opp.Sales_Office__c = null;
                                opp.Sales_Group__c = null;
                                opp.Sales_District__c = null;
                                opp.Organization_Structure__c = null;
                                opp.Territory2Id =  null;
                                system.debug('Multiple SalesOrg - Opp Clone');
                            }
                        }
                        //-------------------- One & Multiple SalesOrg UPDATED -----------------------  
                    }
                }
                
                 if((Trigger.IsInsert && opp.Territory_Integration__c == False && opp.Sales_Organization_User__c != null) || 
                   (Trigger.IsUpdate && (opp.Sales_Organization_User__c != Trigger.oldMap.get(opp.Id).Sales_Organization_User__c) && (opp.Sales_Organization_User__c != null)) ||
                   (Trigger.IsUpdate && (opp.Update_Territory__c != Trigger.oldMap.get(opp.Id).Update_Territory__c) && (opp.Update_Territory__c == True) && (opp.Sales_Organization_User__c != null))
                  ){
                      system.debug('opp.Sales_Org_Code__c BEFORE : '+opp.Sales_Org_Code__c);
                      if((Trigger.IsUpdate && (opp.Sales_Org_Code__c != opp.Sales_Organization_User_Code__c) && (opp.OwnerId == Trigger.oldMap.get(opp.Id).OwnerId)) ||
                         Trigger.IsInsert && (opp.Sales_Org_Code__c == null)){
                             opp.Sales_Org_Code__c = opp.Sales_Organization_User_Code__c;
                         }
                      
                      system.debug('Sales_Organization_User_Code__c : '+opp.Sales_Organization_User_Code__c);
                      system.debug('opp.Sales_Org_Code__c AFTER: '+opp.Sales_Org_Code__c);
                      
                      salesArea = OpportunityTriggerHandler.QuerySalesAreaDetail(opp, recordTypeName);
                      
                      if(salesArea.size()==1){
                          opp.Organization_Structure__c = salesArea[0].Organization_Structure__c;
                          opp.Territory2Id =  salesArea[0].Organization_Structure__r.Territoty_ID__c;
                          opp.Sales_Office__c = salesArea[0].Organization_Structure__r.Sales_Office__c;
                          opp.Sales_Group__c = salesArea[0].Organization_Structure__r.Sales_Group__c;
                          opp.Sales_District__c = salesArea[0].Organization_Structure__r.Sales_District__c;
                      }
                      else if(salesArea.size() == 0){
                          //system.debug('accountMap : '+accountMap);
                          if (Trigger.IsUpdate && ((accountMap.get(opp.AccountId)[0].Prospect__c == true && opp.Sales_Office__c != null && opp.Sales_Group__c != null) ||
                                                   (opp.Update_Account__c != Trigger.oldMap.get(opp.Id).Update_Account__c && opp.Update_Account__c == True)))
                          {
                              orgStruc = OpportunityTriggerHandler.QueryOrganizationStructure(opp, recordTypeName);
                              //system.debug('QueryOrganizationStructure '+orgStruc.size()+' '+orgStruc);
                              if(orgStruc == null || orgStruc.size() == 0)
                              {
                                  opp.Territory2Id =  null;
                                  opp.Sales_Office__c = null;
                                  opp.Sales_Group__c = null;
                                  opp.Sales_District__c = null; 
                                  opp.Organization_Structure__c = null;
                              }
                              else if(orgStruc.size() == 1)
                              {
                                  opp.Organization_Structure__c = orgStruc[0].id;
                                  opp.Territory2Id =  orgStruc[0].Territoty_ID__c;
                                  opp.Sales_Office__c = orgStruc[0].Sales_Office__c;
                                  opp.Sales_Group__c = orgStruc[0].Sales_Group__c;
                                  opp.Sales_District__c = orgStruc[0].Sales_District__c;
                                  
                                  //PoppulateSalesAreaDetail
                                  mSaleAreaDetails = OpportunityTriggerHandler.PoppulateSalesAreaDetail(orgStruc, accSaleAreaMap.get(opp.AccountId),accountMap.get(opp.AccountId)[0].id);
                                  //PoppulateAccountTerritory
                                  mAccTerritories = OpportunityTriggerHandler.PoppulateAccountTerritory(orgStruc, accountMap.get(opp.AccountId)[0].id);
                              }
                          }
                          else{
                              opp.Territory2Id =  null;
                              opp.Sales_Office__c = null;
                              opp.Sales_Group__c = null;
                              opp.Sales_District__c = null; 
                              opp.Organization_Structure__c = null;
                          } 
                      }
                      else if(salesArea.size() > 0)
                          opp.addError('There are '+salesArea.size()+' Territories found. Kindly contact System Administrator.');
                  } 
                else if((Trigger.IsUpdate && opp.Sales_Org_Code__c == Trigger.oldMap.get(opp.Id).Sales_Org_Code__c &&
                         ((opp.Division__c != Trigger.oldMap.get(opp.Id).Division__c) || (opp.Channel__c != Trigger.oldMap.get(opp.Id).Channel__c) ||
                          (opp.Sales_Office__c != Trigger.oldMap.get(opp.Id).Sales_Office__c) || (opp.Sales_Group__c != Trigger.oldMap.get(opp.Id).Sales_Group__c) ||
                          (opp.Sales_District__c != Trigger.oldMap.get(opp.Id).Sales_District__c) || (opp.Update_Account__c != Trigger.oldMap.get(opp.Id).Update_Account__c && opp.Update_Account__c == True))) ||
                        (Trigger.IsInsert && opp.Territory_Integration__c == True))
                {
                    orgStruc = OpportunityTriggerHandler.QueryOrganizationStructure(opp, recordTypeName);
                    //system.debug('orgStruc size: '+orgStruc.size());
                    //system.debug('orgStruc : '+orgStruc);
                    if(orgStruc != null && orgStruc.size() > 0)
                    {
                        for(Organization_Structure__c Org : orgStruc){
                            if(opp.Division__c == Org.Division__c)
                            {
                                opp.Organization_Structure__c = Org.id;
                                opp.Territory2Id =  Org.Territoty_ID__c;
                                opp.Sales_Office__c = Org.Sales_Office__c;
                                opp.Sales_Group__c = Org.Sales_Group__c;
                                opp.Sales_District__c = Org.Sales_District__c;
                            }
                        }
                        //system.debug('orgStruc : '+orgStruc.size());
                        
                        if ((recordTypeName.contains('SGT') && accountMap.get(opp.AccountId)[0].Prospect__c == true && accountMap.get(opp.AccountId)[0].ERP_Id__c == null) || recordTypeName.contains('Standalone'))
                        {
                            //PoppulateSalesAreaDetail
                            salesArea = OpportunityTriggerHandler.QuerySalesAreaDetail(opp, recordTypeName);
                            //system.debug('salesArea : '+salesArea);
                            if(salesArea.size() == 0)
                                mSaleAreaDetails = OpportunityTriggerHandler.PoppulateSalesAreaDetail(orgStruc, accSaleAreaMap.get(opp.AccountId), accountMap.get(opp.AccountId)[0].id);
                            //PoppulateAccountTerritory
                            mAccTerritories = OpportunityTriggerHandler.PoppulateAccountTerritory(orgStruc, accountMap.get(opp.AccountId)[0].id);
                            //system.debug('mSaleAreaDetails : '+mSaleAreaDetails);
                            //system.debug('mAccTerritories : '+mAccTerritories);
                        }
                    }
                    else
                    {
                        opp.Organization_Structure__c = null;
                        opp.Territory2Id =  null;
                    }
                    //else opp.addError('There are '+orgStruc.size()+' Territories found. Kindly contact System Administrator.');
                }
                
                if(Trigger.IsInsert && opp.CurrencyISOCode == UserInfo.getDefaultCurrency()){
                    opp.CurrencyISOCode = accountCurrMap.get(opp.AccountId);
                }
            }
            
            if(Trigger.isAfter && Trigger.isUpdate && (opp.Sales_Organization_User_Code__c != Trigger.oldMap.get(opp.Id).Sales_Organization_User_Code__c)){
                for (List<OpportunityLineItem> temp : oppItemsMap.values()) olisToDelete.addAll(temp);
                if(!olisToDelete.isEmpty()){
                    delete olisToDelete;
                    system.debug('OpportunityLineItem Deleted');
                }
            }
        }
    }
    
    OpportunityTriggerHandler.InsertAndUpdateOpp(updatedProjs);
    OpportunityTriggerHandler.InsertAndUpdateOpp(mSaleAreaDetails);
    OpportunityTriggerHandler.InsertAndUpdateOpp(mAccTerritories);
}