import 'package:erp/core/app_state/app_repositories.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/cashbox/presentation/cashbox_controller.dart';
import 'package:erp/features/items/presentation/items_controller.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/parties/domain/party_repository.dart';
import 'package:erp/features/parties/presentation/parties_controller.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/operational_master_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('party quick-create preserves workplace and branch stable IDs',
      () async {
    final repositories = AppRepositories.demo();
    final controller = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final workplace = await controller.createWorkplace('شركة الاختبار');
    final branch = await controller.createBranch(
      name: 'فرع الاختبار',
      workplaceId: workplace.id,
    );
    final party = await controller.add(
      Party(
        id: 'phase2-party',
        number: controller.nextNumber,
        createdAt: DateTime(2026, 8, 11),
        name: 'زبون المرحلة الثانية',
        type: PartyType.customer,
        workplace: workplace.name,
        branch: branch.name,
        phone: '',
        alternatePhone: '',
        city: '',
        address: '',
        notes: '',
        balanceIqd: 0,
        balanceUsd: 0,
      ),
    );

    final references = await repositories.parties.getMasterDataReferences(
      party.entityId,
    );
    expect(references?.workplaceId, workplace.id);
    expect(references?.branchId, branch.id);
    expect(branch.parentId, workplace.id);
  });

  test(
      'normal party add preserves the full profile while the repository issues identity',
      () async {
    final repositories = AppRepositories.demo();
    final controller = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final workplace = await controller.createWorkplace('جهة الملف الكامل');
    final branch = await controller.createBranch(
      name: 'فرع الملف الكامل',
      workplaceId: workplace.id,
    );
    final createdAt = DateTime(2026, 8, 12, 13, 14, 15, 123);
    final submitted = Party(
      id: 'caller-owned-party-id',
      number: 999999,
      createdAt: createdAt,
      name: 'طرف كامل البيانات',
      type: PartyType.customerAndSupplier,
      workplace: workplace.name,
      branch: branch.name,
      phone: '07701234567',
      alternatePhone: '07801234567',
      city: 'بغداد',
      address: 'الكرادة - شارع الاختبار',
      notes: 'ملاحظات الملف الكامل',
      balanceIqd: 0,
      balanceUsd: 0,
    );
    final repositoryIssuedNumber =
        await repositories.parties.nextPartyNumber();

    final saved = await controller.add(
      submitted,
      references: PartyMasterDataReferences(
        workplaceId: workplace.id,
        branchId: branch.id,
      ),
    );

    expect(saved.entityId, isNot(submitted.entityId));
    expect(saved.number, repositoryIssuedNumber);
    expect(saved.number, isNot(submitted.number));
    expect(saved.createdTimestamp, AuditTimestamp(createdAt));
    expect(saved.name, submitted.name);
    expect(saved.type, submitted.type);
    expect(saved.workplace, workplace.name);
    expect(saved.branch, branch.name);
    expect(saved.phone, submitted.phone);
    expect(saved.alternatePhone, submitted.alternatePhone);
    expect(saved.city, submitted.city);
    expect(saved.address, submitted.address);
    expect(saved.notes, submitted.notes);

    final references = await repositories.parties.getMasterDataReferences(
      saved.entityId,
    );
    expect(references?.workplaceId, workplace.id);
    expect(references?.branchId, branch.id);
  });

  test('party references survive master renames and display live names',
      () async {
    final repositories = AppRepositories.demo();
    final masterData = repositories.operationalMasterData;
    final workplace = await masterData.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.workplace,
        name: 'جهة قبل التعديل',
      ),
    );
    final branch = await masterData.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.branch,
        name: 'فرع قبل التعديل',
        parentId: workplace.id,
      ),
    );
    final party = await repositories.parties.quickCreate(
      PartyQuickCreateRequest(
        name: 'طرف بمرجع ثابت',
        type: PartyType.customer,
        workplaceId: workplace.id,
        branchId: branch.id,
      ),
    );

    await masterData.save(
      OperationalMasterDataRecord(
        id: workplace.id,
        kind: workplace.kind,
        number: workplace.number,
        name: 'جهة بعد التعديل',
      ),
    );
    await masterData.save(
      OperationalMasterDataRecord(
        id: branch.id,
        kind: branch.kind,
        number: branch.number,
        name: 'فرع بعد التعديل',
        parentId: workplace.id,
      ),
    );

    final reopened = PartiesController(
      repository: repositories.parties,
      masterData: masterData,
    );
    addTearDown(reopened.dispose);
    await reopened.load();
    reopened.select(party.id);

    expect(reopened.selectedParty?.workplace, 'جهة بعد التعديل');
    expect(reopened.selectedParty?.branch, 'فرع بعد التعديل');
    final references = await repositories.parties.getMasterDataReferences(
      party.entityId,
    );
    expect(references?.workplaceId, workplace.id);
    expect(references?.branchId, branch.id);
  });

  test('item quick-create keeps a new type under its selected group',
      () async {
    final repositories = AppRepositories.demo();
    final controller = ItemsController(
      repository: repositories.items,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();

    final group = await controller.createGroup('مجموعة المرحلة الثانية');
    final type = await controller.createType(
      name: 'نوع المرحلة الثانية',
      groupId: group.entityId,
    );

    expect(controller.groupById(group.id)?.entityId, group.entityId);
    expect(controller.typeById(type.id)?.entityId, type.entityId);
    expect(type.groupEntityId, group.entityId);
    expect(
      controller.typesFor(group.id).map((candidate) => candidate.entityId),
      contains(type.entityId),
    );
  });

  test('cashbox subaccount quick-create uses the selected main account ID',
      () async {
    final repositories = AppRepositories.demo();
    final controller = CashboxController(
      repository: repositories.cashbox,
      settingsRepository: repositories.businessSettings,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();
    final main = controller.state.accounts.first;

    final created = await controller.createSubaccount(
      name: 'حساب المرحلة الثانية',
      mainAccountId: main.entityId,
    );

    final stored = await repositories.operationalMasterData.getById(
      created.entityId,
    );
    expect(stored?.kind, OperationalMasterDataKind.cashboxSubaccount);
    expect(stored?.parentId, main.entityId);
    expect(
      controller.state.accounts
          .firstWhere((account) => account.entityId == main.entityId)
          .subaccounts
          .map((account) => account.entityId),
      contains(created.entityId),
    );
  });

  test('branch creation rejects a missing parent stable ID', () async {
    final repositories = AppRepositories.demo();
    final controller = PartiesController(
      repository: repositories.parties,
      masterData: repositories.operationalMasterData,
    );
    addTearDown(controller.dispose);
    await controller.load();

    await expectLater(
      controller.createBranch(
        name: 'فرع يتيم',
        workplaceId: EntityId('missing-workplace'),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
