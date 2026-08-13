import '../../../core/domain/business_values.dart';
import 'inventory_cost.dart';

abstract interface class InventoryCostRepository {
  Future<List<InventoryCostBalance>> getBalances();

  Future<InventoryCostBalance?> getBalance({
    required EntityId warehouseId,
    required EntityId itemId,
  });

  Future<List<SalesLineCostRecord>> getSalesLineCosts({
    EntityId? salesInvoiceId,
  });

  Future<SalesLineCostRecord?> getSalesLineCost(EntityId salesLineId);
}
