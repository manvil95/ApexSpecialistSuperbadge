public with sharing class WarehouseCalloutService {

    private static final String WAREHOUSE_URL = 'https://th-superbadge-apex.herokuapp.com/equipment';
    
    // @future(callout=true)
    public static void runWarehouseEquipmentSync(){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        request.setEndpoint(WAREHOUSE_URL);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        
        List<Product2> warehouseEq = new List<Product2>();
        
        if (response.getStatusCode() == 200){
            List<Object> jsonResponse = (List<Object>)JSON.deserializeUntyped(response.getBody());
            System.debug(response.getBody());
            
            //class maps the following fields: replacement part (always true), cost, current inventory, lifespan, maintenance cycle, and warehouse SKU
            //warehouse SKU will be external ID for identifying which equipment records to update within Salesforce
            for (Object eq : jsonResponse){
                Map<String,Object> mapJson = (Map<String,Object>)eq;
                Product2 myEq = new Product2(
                    Replacement_Part__c     = (Boolean) mapJson.get('replacement'),
                    Name                    = (String) mapJson.get('name'),
                    Maintenance_Cycle__c    = (Integer) mapJson.get('maintenanceperiod'),
                    Lifespan_Months__c      = (Integer) mapJson.get('lifespan'),
                    Cost__c                 = (Integer) mapJson.get('cost'),
                    Warehouse_SKU__c        = (String) mapJson.get('sku'),
                    Current_Inventory__c    = (Double) mapJson.get('quantity'),
                    ProductCode             = (String) mapJson.get('_id')
                );

                warehouseEq.add(myEq);
            }
            
            if (warehouseEq.size() > 0){
                upsert warehouseEq;
                System.debug('Your equipment was synced with the warehouse one');
            }
        }
    }
    
    // public static void execute (QueueableContext context){
    //     runWarehouseEquipmentSync();
    // }
}