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
        Set<Id>                                         maintenanceRequestIds           = new Set<Id>();
        List<Case>                                      maintenanceRequestToUpdate      = new List<Case>();
        List<Product2>                                  listEquipment                   = new List<Product2>();
        List<Equipment_Maintenance_Item__c>             listEquipmentItem               = new List<Equipment_Maintenance_Item__c>();
        Map<Id, List<Product2>>                         maintenanceRelatedEquipments    = new Map<Id, List<Product2>>();
        Map<Id, List<Equipment_Maintenance_Item__c>>    maintenanceAndEquipmentItems    = new Map<Id, List<Equipment_Maintenance_Item__c>>();

        for(Case maintenance : newMaintenanceRequests) {
            if(maintenance.Status == CLOSE_STATUS &&
                    (maintenance.Type == ROUTINE_MAINTENANCE_TYPE 
                    || maintenance.Type == REPAIR_TYPE)
            ) {
                maintenanceRequestToUpdate.add(maintenance.clone(false, true, false, false));
                maintenanceRequestIds.add(maintenance.Id);
                maintenanceRelatedEquipments.put(maintenance.Id, new List<Product2>());

                System.debug('Entra en if 1');
                System.debug('maintenance current::: ' + maintenance);
                System.debug('maintenanceRequestToUpdate::: ' + maintenanceRequestToUpdate);
                System.debug('maintenanceRequestIds::: ' + maintenanceRequestIds);
            }
        }
        
        List<Id> listIdsEquip = new List<Id>();

        for(Case idEquip : [SELECT Product__c 
                            FROM Case 
                            WHERE Id IN :maintenanceRequestIds WITH USER_MODE]){
            listIdsEquip.add(idEquip.Product__c);
        }

        System.debug('LIST IDS EQUIPMENT:::' + listIdsEquip);

        listEquipment = [SELECT Id, 
                                Maintenance_Cycle__c 
                        FROM    Product2 
                        WHERE Id IN :listIdsEquip
                        WITH USER_MODE];
        
        System.debug('ListEquipment:: ' + listEquipment);

        List<Integer> days = new List<Integer>();
        for(Case maintenance : maintenanceRequestToUpdate) {
            if(maintenance.Type == REPAIR_TYPE) {
                maintenance.Type = ROUTINE_MAINTENANCE_TYPE;
            }
            maintenance.Subject = ROUTINE_MAINTENANCE_TYPE + 'xx';
            maintenance.Date_Reported__c = System.today();

            for(Product2 equipment : listEquipment) {
                if(maintenance.Product__c == equipment.Id) {
                    days.add((Integer)equipment.Maintenance_Cycle__c);
                }
            }
            System.debug('LIST EQUIPMENT NO SORT:: ' + days);
            listEquipment.sort();
            System.debug('LIST EQUIPMENT SORT:: ' + days);

            maintenance.Date_Due__c = System.today().addDays(days.get(0));



        }

        try{
            System.Database.insert(maintenanceRequestToUpdate);
        }
        catch(Exception e){
            System.debug('EXCEPTION: ' + e.getMessage());
        }
    }        
}        