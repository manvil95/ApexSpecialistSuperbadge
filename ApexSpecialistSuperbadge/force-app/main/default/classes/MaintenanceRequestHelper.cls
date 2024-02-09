public with sharing class MaintenanceRequestHelper {
    
    private final static string CLOSE_STATUS               = 'Closed';
    private final static string STATUS                     = 'Status'; 
    private final static string ROUTINE_MAINTENANCE_TYPE   = 'Routine Maintenance'; 
    private final static string REPAIR_TYPE                = 'Repair'; 

    /**
     * Crear una nueva solicitud de mantenimiento cuando se cierra una solicitud existente de tipo Reparación o Mantenimiento Rutinario.
     * La nueva solicitud de mantenimiento debe estar vinculada a los mismos registros de Vehículo y Equipo que la solicitud original cerrada.
     * Mantener los elementos de mantenimiento existentes del equipo vinculados a la solicitud cerrada original.
     * El Tipo de la nueva solicitud debe establecerse como Mantenimiento Rutinario.
     * El Asunto de la nueva solicitud no debe ser nulo.
     * El campo de Fecha de Informe de la nueva solicitud refleja el día en que se creó la solicitud.
     * Calcular las fechas de vencimiento de las solicitudes de mantenimiento utilizando el ciclo de mantenimiento definido en los registros de equipos relacionados.
     * Si se utilizan varios equipos en la solicitud de mantenimiento, definir la fecha de vencimiento aplicando el ciclo de mantenimiento más corto a la fecha actual.
     * Diseñar el código para funcionar tanto con solicitudes de mantenimiento individuales como con lotes.
     * Implementar la lógica del sistema para procesar con éxito aproximadamente 300 registros de solicitudes de mantenimiento sin conexión que se programan para importarse juntos.
     * Exponer la lógica para otros usos en la organización.
     * Separar el desencadenador (MaintenanceRequest) de la lógica de la aplicación en el controlador (MaintenanceRequestHelper).
    */

    public static void updateWorkOrders(List<Case> newMaintenanceRequests, Map<Id, Case> oldMaintenanceRequestMap) {
        // TODO: Complete the method to update workorders
        Set<Id> maintenanceRequestIds       = new Set<Id>();
        List<Case> casesToInsert            = new List<Case>();
        Map<Id,Decimal> maintenanceCycles   = new Map<ID,Decimal>();

        for(Case maintenance : newMaintenanceRequests) {
            if(oldMaintenanceRequestMap.get(maintenance.Id).get(STATUS) != maintenance.Status &&
                    (maintenance.Type == ROUTINE_MAINTENANCE_TYPE 
                    || maintenance.Type == REPAIR_TYPE)
            ) {
                maintenanceRequestIds.add(maintenance.Id);

                System.debug('Entra en if 1');
                System.debug('maintenanceRequestIds::: ' + maintenanceRequestIds);
            }
        }
        
        if(!maintenanceRequestIds.isEmpty()) {
            Map<Id,Case> closedCasesMap = new Map<Id,Case>([SELECT  Id, 
                                                                    Vehicle__c, 
                                                                    ProductId, 
                                                                    Product.Maintenance_Cycle__c,
                                                                    (SELECT Id, Equipment__c,Quantity__c 
                                                                    FROM Equipment_Maintenance_Items__r) 
                                                            FROM    Case 
                                                            WHERE   Id IN :maintenanceRequestIds
                                                            WITH    USER_MODE]);

            AggregateResult[] results = [   SELECT  Maintenance_Request__c, 
                                                    MIN(Equipment__r.Maintenance_Cycle__c)cycle 
                                            FROM    Equipment_Maintenance_Item__c 
                                            WHERE   Maintenance_Request__c IN :maintenanceRequestIds 
                                            WITH    USER_MODE 
                                            GROUP BY Maintenance_Request__c];

            for (AggregateResult result : results) {
                maintenanceCycles.put((Id) result.get('Maintenance_Request__c'), (Decimal) result.get('cycle'));
            }

            for(Case closedCase: closedCasesMap.values()) {
                Case newCase = new Case(
                    ParentId            = closedCase.Id,
                    Status              = 'New',
                    Subject             = 'Routine Maintenance',
                    Type                = 'Routine Maintenance',
                    Vehicle__c          = closedCase.Vehicle__c,
                    ProductId           = closedCase.ProductId,
                    Origin              = 'Web',
                    Date_Reported__c    = Date.today()
                );

                if(maintenanceCycles.containsKey(closedCase.Id)) {
                    newCase.Date_Due__c = Date.today().addDays((Integer) maintenanceCycles.get(closedCase.Id));
                } 
                // else {
                //     newCase.Date_Due__c = Date.today().addDays((Integer) closedCase.Product.Maintenance_Cycle__c);
                // }

                casesToInsert.add(newCase);
            }
            
            System.Database.insert(casesToInsert);

            List<Equipment_Maintenance_Item__c> clonedWPs = new List<Equipment_Maintenance_Item__c>();
            for(Case nc : casesToInsert){
                for (Equipment_Maintenance_Item__c wp : closedCasesMap.get(nc.ParentId).Equipment_Maintenance_Items__r){
                    Equipment_Maintenance_Item__c wpClone = wp.clone();
                    wpClone.Maintenance_Request__c = nc.Id;
                    ClonedWPs.add(wpClone);
                    
                }
            }

            insert ClonedWPs;

        }

    }
    
    // public static void updateW(List<Case> updWorkOrders, Map<Id,Case> nonUpdCaseMap) {
    //         Set<Id> validIds = new Set<Id>();
        
        
    //     For (Case c : updWorkOrders){
    //         if (nonUpdCaseMap.get(c.Id).Status != 'Closed' && c.Status == 'Closed'){
    //             if (c.Type == 'Repair' || c.Type == 'Routine Maintenance'){
    //                 validIds.add(c.Id);
                    
             
    //             }
    //         }
    //     }
        
    //     if (!validIds.isEmpty()){
    //         List<Case> newCases = new List<Case>();
    //         Map<Id,Case> closedCasesM = new Map<Id,Case>([SELECT Id, Vehicle__c, ProductId, Product2__r.Maintenance_Cycle__c,(SELECT Id,Equipment__c,Quantity__c FROM Equipment_Maintenance_Items__r) 
    //                                                      FROM Case WHERE Id IN :validIds]);
    //         Map<Id,Decimal> maintenanceCycles = new Map<ID,Decimal>();
    //         AggregateResult[] results = [SELECT Maintenance_Request__c, MIN(Equipment__r.Maintenance_Cycle__c)cycle FROM Equipment_Maintenance_Item__c WHERE Maintenance_Request__c IN :ValidIds GROUP BY Maintenance_Request__c];
        
    //         for (AggregateResult ar : results){ 
    //             maintenanceCycles.put((Id) ar.get('Maintenance_Request__c'), (Decimal) ar.get('cycle'));
    //         }
            
    //         for(Case cc : closedCasesM.values()){
    //             Case nc = new Case (
    //                 ParentId = cc.Id,
    //                 Status = 'New',
    //                 Subject = 'Routine Maintenance',
    //                 Type = 'Routine Maintenance',
    //                 Vehicle__c = cc.Vehicle__c,
    //                 Equipment__c =cc.Equipment__c,
    //                 Origin = 'Web',
    //                 Date_Reported__c = Date.Today()
                    
    //             );
                
    //             If (maintenanceCycles.containskey(cc.Id)){
    //                 nc.Date_Due__c = Date.today().addDays((Integer) maintenanceCycles.get(cc.Id));
    //             } else {
    //                 nc.Date_Due__c = Date.today().addDays((Integer) cc.Equipment__r.maintenance_Cycle__c);
    //             }
                
    //             newCases.add(nc);
    //         }
            
    //        insert newCases;
            
    //        List<Equipment_Maintenance_Item__c> clonedWPs = new List<Equipment_Maintenance_Item__c>();
    //        for (Case nc : newCases){
    //             for (Equipment_Maintenance_Item__c wp : closedCasesM.get(nc.ParentId).Equipment_Maintenance_Items__r){
    //                 Equipment_Maintenance_Item__c wpClone = wp.clone();
    //                 wpClone.Maintenance_Request__c = nc.Id;
    //                 ClonedWPs.add(wpClone);
                    
    //             }
    //         }
    //         insert ClonedWPs;
    //     }
    // }

}    
