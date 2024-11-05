trigger UpdateCurrentOccupancy on Inventory__c (after insert, after update, after delete) {
    Set<Id> warehouseIds = new Set<Id>();
    
    // Collect all warehouse IDs from inventory records
    if (Trigger.isInsert || Trigger.isUpdate) {
        for (Inventory__c inv : Trigger.new) {
            if (inv.Location__c != null) { // Ensure this matches your API name for the Warehouse lookup
                warehouseIds.add(inv.Location__c);
            }
        }
    } 
    else if (Trigger.isDelete) {
        for (Inventory__c inv : Trigger.old) {
            if (inv.Location__c != null) { // Ensure this matches your API name for the Warehouse lookup
                warehouseIds.add(inv.Location__c);
            }
        }
    }

    // Query the related inventory items and calculate total quantity for each warehouse
    Map<Id, Decimal> warehouseOccupancyMap = new Map<Id, Decimal>();
    for (AggregateResult ar : [
        SELECT Location__c, SUM(Quantity_Available__c) total
        FROM Inventory__c
        WHERE Location__c IN :warehouseIds // Use Location__c instead of Warehouse__c
        GROUP BY Location__c
    ]) {
        warehouseOccupancyMap.put((Id)ar.get('Location__c'), (Decimal)ar.get('total')); // Reference Location__c for totals
    }

    // Update the current occupancy field for each warehouse
    List<Warehouse__c> warehousesToUpdate = new List<Warehouse__c>();
    for (Id warehouseId : warehouseIds) {
        warehousesToUpdate.add(new Warehouse__c(
            Id = warehouseId,
            Current_Occupancy__c = warehouseOccupancyMap.get(warehouseId) != null ? warehouseOccupancyMap.get(warehouseId) : 0
        ));
    }
    
    // Perform the update
    if (!warehousesToUpdate.isEmpty()) {
        update warehousesToUpdate;
    }
}