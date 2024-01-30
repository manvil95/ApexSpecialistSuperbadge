public with sharing class MaintenanceRequestTriggerHandler extends TriggerHandler{

    private List<Case> 		oldMaintenanceRequests;
	private List<Case> 		newMaintenanceRequests;
	private Map<Id, Case> 	oldMaintenanceRequestMap;
	private Map<Id, Case> 	newMaintenanceRequestMap;

	public MaintenanceRequestTriggerHandler() {
		this.oldMaintenanceRequests		= Trigger.old;
		this.newMaintenanceRequests		= Trigger.new;
		this.oldMaintenanceRequestMap	= (Map<Id,Case>) Trigger.oldMap;
		this.newMaintenanceRequestMap	= (Map<Id,Case>) Trigger.newMap;

		this.objectType					= 'Case';
	}

	public override void afterUpdate() {
        MaintenanceRequestHelper.updateWorkOrders(this.newMaintenanceRequests, this.oldMaintenanceRequestMap);
	}
}