public with sharing class MaintenanceRequestHelper {
    
    private final static string CLOSE_STATUS               = 'Closed';
    private final static string STATUS                     = 'Status'; 
    private final static string ROUTINE_MAINTENANCE_TYPE   = 'Status'; 
    private final static string REPAIR_TYPE                = 'Status'; 

    public static void updateWorkOrders(List<Case> newMaintenanceRequests, Map<Id, Case> oldMaintenanceRequestMap) {
        // TODO: Complete the method to update workorders
        Set<Id>                                         maintenanceRequestIds           = new Set<Id>();
        List<Case>                                      maintenanceRequestToUpdate      = new List<Case>();
        List<Equipment_Maintenance_Item__c>             listEquipment                   = new List<Equipment_Maintenance_Item__c>();
        Map<Id, List<Equipment_Maintenance_Item__c>>    maintenanceAndEquipmentItems    = new Map<Id, List<Equipment_Maintenance_Item__c>>();

        for(Case maintenance : newMaintenanceRequests) {
            if(maintenance.Status == CLOSE_STATUS &&
                    (maintenance.Type == ROUTINE_MAINTENANCE_TYPE 
                    || maintenance.Type == REPAIR_TYPE)
            ) {
                maintenanceRequestToUpdate.add(maintenance);
                maintenanceRequestIds.add(maintenance.Id);
            }
        }

        listEquipment = [SELECT Id, Equipment__c
                        FROM    Equipment_Maintenance_Item__c
                        WHERE   Id IN :maintenanceRequestIds 
                        WITH    USER_MODE];
        

        for(Case maintenance : maintenanceRequestToUpdate) {
            maintenanceAndEquipmentItems.put(maintenance.Id, listEquipment);

            for(Equipment_Maintenance_Item__c equip : maintenanceAndEquipmentItems.get(maintenance.Id)) {
                
            }
        }

        
    }        
}        