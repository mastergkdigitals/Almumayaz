import '../../features/cashbox/data/demo_cashbox_repository.dart';
import '../../features/cashbox/domain/cashbox_repository.dart';
import '../../features/items/data/demo_item_repository.dart';
import '../../features/items/domain/item_repository.dart';
import '../../features/parties/data/demo_party_repository.dart';
import '../../features/parties/domain/party_repository.dart';
import '../../features/purchases/data/demo_purchase_repository.dart';
import '../../features/purchases/domain/purchase_repository.dart';
import '../../features/sales/data/demo_sales_repository.dart';
import '../../features/sales/domain/sales_repository.dart';
import '../../features/settings/data/demo_operational_settings_repositories.dart';
import '../../features/settings/domain/operational_master_data.dart';
import '../../features/settings/domain/operational_master_data_repository.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/warehouses/data/demo_warehouse_repository.dart';
import '../../features/warehouses/domain/warehouse_repository.dart';
import '../domain/business_values.dart';

/// One composition root for every repository used by the desktop app.
///
/// A single instance is kept above the navigator by the app-store provider, so
/// demo changes survive closing and reopening a feature screen. API-backed
/// adapters can later replace individual fields without changing widgets.
class AppRepositories {
  const AppRepositories({
    required this.parties,
    required this.items,
    required this.warehouses,
    required this.cashbox,
    required this.sales,
    required this.purchases,
    required this.businessSettings,
    required this.deviceSettings,
    required this.operationalMasterData,
  });

  factory AppRepositories.demo() {
    late DemoOperationalMasterDataRepository masterData;
    late DemoPartyRepository parties;
    late DemoItemRepository items;
    late DemoWarehouseRepository warehouses;
    late DemoCashboxRepository cashbox;
    late DemoSalesRepository sales;
    late DemoPurchaseRepository purchases;
    late DemoBusinessSettingsRepository businessSettings;

    masterData = DemoOperationalMasterDataRepository(
      isExternallyReferenced: (id) async {
        final record = await masterData.getById(id);
        if (record == null) return false;
        switch (record.kind) {
          case OperationalMasterDataKind.itemGroup:
            return (await items.getAll()).any(
              (item) => item.groupId == id.value,
            );
          case OperationalMasterDataKind.itemType:
            return (await items.getAll()).any(
              (item) => item.typeId == id.value,
            );
          case OperationalMasterDataKind.workplace:
          case OperationalMasterDataKind.branch:
            return parties.referencesMasterData(id);
          case OperationalMasterDataKind.cashboxMainAccount:
          case OperationalMasterDataKind.cashboxSubaccount:
            if (await cashbox.referencesMasterData(id)) return true;
            if (record.kind ==
                OperationalMasterDataKind.cashboxMainAccount) {
              final defaults =
                  await businessSettings.loadOperationalDefaults();
              return defaults.cashbox.mainAccountId == id;
            }
            return false;
        }
      },
    );

    parties = DemoPartyRepository(
      masterData: masterData,
      isReferenced: (partyId) async {
        if ((await sales.getAll()).any(
          (invoice) => invoice.customerId == partyId,
        )) {
          return true;
        }
        if ((await purchases.getAll()).any(
          (invoice) => invoice.supplierId == partyId,
        )) {
          return true;
        }
        return cashbox.referencesParty(partyId);
      },
    );

    items = DemoItemRepository(
      masterData: masterData,
      isReferenced: (itemId) async {
        if ((await sales.getAll()).any(
          (invoice) => invoice.lines.any((line) => line.itemId == itemId),
        )) {
          return true;
        }
        if ((await purchases.getAll()).any(
          (invoice) => invoice.lines.any((line) => line.itemId == itemId),
        )) {
          return true;
        }
        return warehouses.referencesItem(itemId);
      },
    );

    warehouses = DemoWarehouseRepository(
      itemExists: (itemId) async => await items.getById(itemId) != null,
      isExternallyReferenced: (warehouseId) async {
        return (await sales.getAll()).any(
              (invoice) =>
                  invoice.defaultWarehouseId == warehouseId ||
                  invoice.lines.any(
                    (line) => line.warehouseId == warehouseId,
                  ),
            ) ||
            (await purchases.getAll()).any(
              (invoice) =>
                  invoice.defaultWarehouseId == warehouseId ||
                  invoice.lines.any(
                    (line) => line.warehouseId == warehouseId,
                  ),
            ) ||
            (await businessSettings.loadOperationalDefaults())
                    .purchases
                    .warehouseId ==
                warehouseId ||
            (await businessSettings.loadOperationalDefaults())
                    .sales
                    .warehouseId ==
                warehouseId;
      },
    );
    cashbox = DemoCashboxRepository(masterData: masterData);

    Future<bool> partyExists(EntityId id) async =>
        await parties.getById(id) != null;
    Future<bool> itemExists(EntityId id) async =>
        await items.getById(id) != null;
    Future<bool> warehouseExists(EntityId id) async =>
        await warehouses.getById(id) != null;

    sales = DemoSalesRepository(
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
    );
    purchases = DemoPurchaseRepository(
      partyExists: partyExists,
      itemExists: itemExists,
      warehouseExists: warehouseExists,
    );

    businessSettings = DemoBusinessSettingsRepository(
      warehouseExists: warehouseExists,
      cashboxMainAccountExists: (id) async => (await cashbox.getMainAccounts())
          .any((account) => account.entityId == id),
    );

    return AppRepositories(
      parties: parties,
      items: items,
      warehouses: warehouses,
      cashbox: cashbox,
      sales: sales,
      purchases: purchases,
      businessSettings: businessSettings,
      deviceSettings: DemoDeviceSettingsRepository(),
      operationalMasterData: masterData,
    );
  }

  final PartyRepository parties;
  final ItemRepository items;
  final WarehouseRepository warehouses;
  final CashboxRepository cashbox;
  final SalesRepository sales;
  final PurchaseRepository purchases;
  final BusinessSettingsRepository businessSettings;
  final DeviceSettingsRepository deviceSettings;
  final OperationalMasterDataRepository operationalMasterData;
}
