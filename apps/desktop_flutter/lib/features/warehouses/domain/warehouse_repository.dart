import '../../../core/data/app_repository.dart';
import '../../../core/domain/business_values.dart';
import 'inventory_records.dart';
import 'warehouse.dart';

abstract interface class WarehouseRepository
    implements AppRepository<Warehouse> {
  Future<List<Warehouse>> search(String query);

  Future<List<InventoryBalance>> getInventory(EntityId warehouseId);

  Future<List<InventoryTransfer>> getTransfers();

  Future<InventoryTransfer> transfer(InventoryTransferDraft draft);

  Future<InventoryTransfer> reverseTransfer(
    EntityId transferId, {
    AuditTimestamp? createdAt,
  });

  Future<bool> referencesItem(EntityId itemId);
}
