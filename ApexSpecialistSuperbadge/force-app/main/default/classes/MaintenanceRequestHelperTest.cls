@isTest
public with sharing class MaintenanceRequestHelperTest {
    
    private static final string STATUS_NEW = 'New';
    private static final string WORKING = 'Working';
    private static final string CLOSED = 'Closed';
    private static final string REPAIR = 'Repair';
    private static final string REQUEST_ORIGIN = 'Web';
    private static final string REQUEST_TYPE = 'Routine Maintenance';
    private static final string REQUEST_SUBJECT = 'Testing subject';
    
    private static Vehicle__c createVehicle(){
        Vehicle__c vehicle = new Vehicle__C(Name = 'SuperTruck');
        return vehicle;
    }
    
    private static Product2 createEq(){
        product2 equipment = new product2(
            name = 'SuperEquipment',
            lifespan_months__C = 10,
            maintenance_cycle__C = 10,
            replacement_part__c = true);
        return equipment;
    }
    
    private static Case createMaintenanceRequest(id vehicleId, id equipmentId){
        case cs = new case(Type=REPAIR,
                            Status=STATUS_NEW,
                            Origin=REQUEST_ORIGIN,
                            Subject=REQUEST_SUBJECT,
                            ProductId=equipmentId,
                            Vehicle__c=vehicleId);
        return cs;
    }
    
    private static Equipment_Maintenance_Item__c createWorkPart(id equipmentId,id requestId){
        Equipment_Maintenance_Item__c wp = new Equipment_Maintenance_Item__c(Equipment__c = equipmentId,
                                                                            Maintenance_Request__c = requestId);
        return wp;
    }
    
    @istest
    private static void testMaintenanceRequestPositive(){
        Vehicle__c vehicle = createVehicle();
        insert vehicle;
        Id vehicleId = vehicle.Id;
        
        Product2 equipment = createEq();
        insert equipment;
        Id equipmentId = equipment.Id;
        
        Case somethingToUpdate = createMaintenanceRequest(vehicleId,equipmentId);
        insert somethingToUpdate;
        
        Equipment_Maintenance_Item__c workP = createWorkPart(equipmentId,somethingToUpdate.id);
        insert workP;
        
        Test.startTest();
        somethingToUpdate.status = CLOSED;
        update somethingToUpdate;
        Test.stopTest();
        
        Case newReq = [SELECT id, subject, type, ProductId, Date_Reported__c, Vehicle__c, Date_Due__c
                        FROM case
                        WHERE status =:STATUS_NEW];
        
        Equipment_Maintenance_Item__c workPart = [select id
                                                    from Equipment_Maintenance_Item__c
                                                    where Maintenance_Request__c =:newReq.Id];
        
        system.assert(workPart != null);
        system.assert(newReq.Subject != null);
        system.assertEquals(newReq.Type, REQUEST_TYPE);
        SYSTEM.assertEquals(newReq.ProductId, equipmentId);
        SYSTEM.assertEquals(newReq.Vehicle__c, vehicleId);
        SYSTEM.assertEquals(newReq.Date_Reported__c, system.today());
    }
    
    @istest
    private static void testMaintenanceRequestNegative(){
        Vehicle__C vehicle = createVehicle();
        insert vehicle;
        id vehicleId = vehicle.Id;
        
        product2 equipment = createEq();
        insert equipment;
        id equipmentId = equipment.Id;
        
        case emptyReq = createMaintenanceRequest(vehicleId,equipmentId);
        insert emptyReq;
        
        Equipment_Maintenance_Item__c workP = createWorkPart(equipmentId, emptyReq.Id);
        insert workP;
        
        test.startTest();
        emptyReq.Status = WORKING;
        update emptyReq;
        test.stopTest();
        
        list<case> allRequest = [select id 
                                    from case];
        
        Equipment_Maintenance_Item__c workPart = [select id 
                                                    from Equipment_Maintenance_Item__c 
                                                    where Maintenance_Request__c = :emptyReq.Id];
        System.debug('XX ' + workPart);
        System.debug('XX ' + allRequest.size());
        system.assert(workPart != null, true);
        system.assert(allRequest.size() == 2, true);
    }
    
    @istest
    private static void testMaintenanceRequestBulk(){
        list<Vehicle__C> vehicleList = new list<Vehicle__C>();
        list<Product2> equipmentList = new list<Product2>();
        list<Equipment_Maintenance_Item__c> workPartList = new list<Equipment_Maintenance_Item__c>();
        list<case> requestList = new list<case>();
        list<id> oldRequestIds = new list<id>();
        
        for(integer i = 0; i < 300; i++){
            vehicleList.add(createVehicle());
            equipmentList.add(createEq());
        }
        insert vehicleList;
        insert equipmentList;
        
        for(integer i = 0; i < 300; i++){
            requestList.add(createMaintenanceRequest(vehicleList.get(i).id, equipmentList.get(i).id));
        }
        insert requestList;
        
        for(integer i = 0; i < 300; i++){
            workPartList.add(createWorkPart(equipmentList.get(i).id, requestList.get(i).id));
        }
        insert workPartList;
        
        test.startTest();
        for(case req : requestList){
            req.Status = CLOSED;
            oldRequestIds.add(req.Id);
        }
        update requestList;
        test.stopTest();
        
        list<case> allRequests = [select id
                                    from case
                                    where status =: STATUS_NEW];
        
        list<Equipment_Maintenance_Item__c> workParts = [select id
                                                        from Equipment_Maintenance_Item__c
                                                        where Maintenance_Request__c in: oldRequestIds];
        
        system.assert(allRequests.size() == 300);
    }
}