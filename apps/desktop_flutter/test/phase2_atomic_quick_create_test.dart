import 'package:erp/core/data/demo_transaction_runner.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/items/data/demo_item_repository.dart';
import 'package:erp/features/items/domain/item.dart';
import 'package:erp/features/items/domain/item_repository.dart';
import 'package:erp/features/parties/data/demo_party_repository.dart';
import 'package:erp/features/parties/domain/party.dart';
import 'package:erp/features/parties/domain/party_repository.dart';
import 'package:erp/features/settings/data/demo_operational_settings_repositories.dart';
import 'package:erp/features/settings/domain/operational_master_data.dart';
import 'package:erp/features/settings/domain/operational_master_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('master-data creation serializes races and never reuses numbers',
      () async {
    final runner = DemoTransactionRunner();
    final repository = DemoOperationalMasterDataRepository(
      initialValues: const [],
      transactionRunner: runner,
    );

    final created = await Future.wait([
      repository.createNamedRecord(
        const CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.workplace,
          name: 'جهة ألف',
        ),
      ),
      repository.createNamedRecord(
        const CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.workplace,
          name: 'جهة باء',
        ),
      ),
    ]);
    expect(created.map((record) => record.number).toSet(), {1, 2});
    expect(created.map((record) => record.id).toSet(), hasLength(2));
    expect(
      (await repository.getAll()).map((record) => record.name).toSet(),
      containsAll({'جهة ألف', 'جهة باء'}),
    );

    final duplicateOutcomes = await Future.wait([
      _capture(
        repository.createNamedRecord(
          const CreateOperationalMasterDataRequest(
            kind: OperationalMasterDataKind.workplace,
            name: 'جهة متزامنة',
          ),
        ),
      ),
      _capture(
        repository.createNamedRecord(
          const CreateOperationalMasterDataRequest(
            kind: OperationalMasterDataKind.workplace,
            name: '  جهة   متزامنة  ',
          ),
        ),
      ),
    ]);
    expect(
      duplicateOutcomes.whereType<OperationalMasterDataRecord>(),
      hasLength(1),
    );
    expect(duplicateOutcomes.whereType<StateError>(), hasLength(1));

    final normallySaved = OperationalMasterDataRecord(
      id: EntityId('manual-workplace-20'),
      kind: OperationalMasterDataKind.workplace,
      number: 20,
      name: 'جهة محفوظة بالطريقة العادية',
    );
    await repository.save(normallySaved);
    await repository.delete(normallySaved.id);
    final afterDelete = await repository.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.workplace,
        name: 'جهة بعد الحذف',
      ),
    );
    expect(afterDelete.number, 21);
    expect(afterDelete.id, isNot(normallySaved.id));

    final group = await repository.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemGroup,
        name: 'مجموعة ترقيم الأبناء',
      ),
    );
    final types = await Future.wait([
      repository.createNamedRecord(
        CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.itemType,
          name: 'نوع أول',
          parentId: group.id,
        ),
      ),
      repository.createNamedRecord(
        CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.itemType,
          name: 'نوع ثان',
          parentId: group.id,
        ),
      ),
    ]);
    expect(types.map((record) => record.number).toSet(), {1, 2});
    final secondType = types.singleWhere((record) => record.number == 2);
    await repository.delete(secondType.id);
    final thirdType = await repository.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemType,
        name: 'نوع ثالث',
        parentId: group.id,
      ),
    );
    expect(thirdType.number, 3);
  });

  test('master-data creation rejects Arabic-equivalent names', () async {
    final repository = DemoOperationalMasterDataRepository(
      initialValues: const [],
    );

    await repository.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.workplace,
        name: 'مؤسسة أفق',
      ),
    );

    await expectLater(
      repository.createNamedRecord(
        const CreateOperationalMasterDataRequest(
          kind: OperationalMasterDataKind.workplace,
          name: '  موسسه   افق  ',
        ),
      ),
      throwsStateError,
    );
    expect(await repository.getAll(), hasLength(1));
  });

  test('moving a child cannot reuse a number consumed in the target scope',
      () async {
    final repository = DemoOperationalMasterDataRepository(
      initialValues: const [],
    );
    final sourceGroup = await repository.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemGroup,
        name: 'مجموعة المصدر',
      ),
    );
    final targetGroup = await repository.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemGroup,
        name: 'مجموعة الهدف',
      ),
    );
    final consumedTargetType = await repository.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemType,
        name: 'نوع هدف محذوف',
        parentId: targetGroup.id,
      ),
    );
    await repository.delete(consumedTargetType.id);
    final sourceType = await repository.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemType,
        name: 'نوع المصدر',
        parentId: sourceGroup.id,
      ),
    );
    expect(sourceType.number, consumedTargetType.number);

    await expectLater(
      repository.save(
        OperationalMasterDataRecord(
          id: sourceType.id,
          kind: sourceType.kind,
          number: sourceType.number,
          name: sourceType.name,
          parentId: targetGroup.id,
        ),
      ),
      throwsStateError,
    );
    expect((await repository.getById(sourceType.id))?.parentId, sourceGroup.id);
  });

  test('cashbox main and first subaccount commit as one pair', () async {
    final repository = DemoOperationalMasterDataRepository(
      initialValues: const [],
    );

    await expectLater(
      repository.createCashboxAccountPair(
        const CreateCashboxAccountPairRequest(
          mainAccountName: 'صندوق غير مكتمل',
          firstSubaccountName: '   ',
        ),
      ),
      throwsStateError,
    );
    expect(await repository.getAll(), isEmpty);

    final pair = await repository.createCashboxAccountPair(
      const CreateCashboxAccountPairRequest(
        mainAccountName: 'صندوق الفرع',
        firstSubaccountName: 'النقدية',
      ),
    );
    expect(pair.mainAccount.number, 1);
    expect(pair.subaccount.number, 1);
    expect(pair.subaccount.parentId, pair.mainAccount.id);
    expect(await repository.getAll(), hasLength(2));
  });

  test('party quick-create normalizes races and retains issued identity',
      () async {
    final runner = DemoTransactionRunner();
    final masterData = DemoOperationalMasterDataRepository(
      initialValues: const [],
      transactionRunner: runner,
    );
    final repository = DemoPartyRepository(
      initialValues: const [],
      masterData: masterData,
      transactionRunner: runner,
    );
    final firstWorkplace = await masterData.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.workplace,
        name: 'جهة أولى',
      ),
    );
    final secondWorkplace = await masterData.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.workplace,
        name: 'جهة ثانية',
      ),
    );
    final firstBranch = await masterData.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.branch,
        name: 'فرع أول',
        parentId: firstWorkplace.id,
      ),
    );
    await expectLater(
      repository.quickCreate(
        PartyQuickCreateRequest(
          name: 'طرف بارتباط غير صالح',
          workplaceId: secondWorkplace.id,
          branchId: firstBranch.id,
        ),
      ),
      throwsStateError,
    );
    expect(await repository.getAll(), isEmpty);

    final created = await Future.wait([
      repository.quickCreate(
        PartyQuickCreateRequest(
          name: 'طرف أول',
          type: PartyType.customer,
          workplaceId: firstWorkplace.id,
          branchId: firstBranch.id,
        ),
      ),
      repository.quickCreate(
        const PartyQuickCreateRequest(
          name: 'طرف ثان',
          type: PartyType.supplier,
        ),
      ),
    ]);
    expect(created.map((party) => party.number).toSet(), {1, 2});
    expect(created.map((party) => party.entityId).toSet(), hasLength(2));
    final linkedParty = created.singleWhere((party) => party.name == 'طرف أول');
    expect(linkedParty.workplace, firstWorkplace.name);
    expect(linkedParty.branch, firstBranch.name);
    final linkedReferences = await repository.getMasterDataReferences(
      linkedParty.entityId,
    );
    expect(linkedReferences?.workplaceId, firstWorkplace.id);
    expect(linkedReferences?.branchId, firstBranch.id);

    final normalSaveRace = await Future.wait([
      _capture(repository.save(_party(id: 'manual-party-a', number: 3))),
      _capture(repository.save(_party(id: 'manual-party-b', number: 3))),
    ]);
    expect(normalSaveRace.whereType<Party>(), hasLength(1));
    expect(normalSaveRace.whereType<StateError>(), hasLength(1));
    final deletedNormalSave = normalSaveRace.whereType<Party>().single;
    await repository.delete(deletedNormalSave.entityId);
    final afterNormalDelete = await repository.quickCreate(
      const PartyQuickCreateRequest(name: 'طرف بعد حذف الحفظ العادي'),
    );
    expect(afterNormalDelete.number, 4);
    expect(afterNormalDelete.entityId, isNot(deletedNormalSave.entityId));

    final canonicalRace = await Future.wait([
      _capture(
        repository.quickCreate(
          const PartyQuickCreateRequest(name: 'مؤسسة أفق'),
        ),
      ),
      _capture(
        repository.quickCreate(
          const PartyQuickCreateRequest(name: 'موسسه افق'),
        ),
      ),
    ]);
    expect(canonicalRace.whereType<Party>(), hasLength(1));
    expect(canonicalRace.whereType<StateError>(), hasLength(1));

    final highest = (await repository.getAll()).reduce(
      (first, second) => first.number > second.number ? first : second,
    );
    await repository.delete(highest.entityId);
    final afterDelete = await repository.quickCreate(
      const PartyQuickCreateRequest(name: 'طرف بعد الحذف'),
    );
    expect(afterDelete.number, highest.number + 1);
    expect(afterDelete.entityId, isNot(highest.entityId));
  });

  test('item quick-create serializes code races and issues unique IDs',
      () async {
    final runner = DemoTransactionRunner();
    final masterData = DemoOperationalMasterDataRepository(
      initialValues: const [],
      transactionRunner: runner,
    );
    final group = await masterData.createNamedRecord(
      const CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemGroup,
        name: 'مجموعة الاختبار',
      ),
    );
    final type = await masterData.createNamedRecord(
      CreateOperationalMasterDataRequest(
        kind: OperationalMasterDataKind.itemType,
        name: 'نوع الاختبار',
        parentId: group.id,
      ),
    );
    final repository = DemoItemRepository(
      initialValues: const [],
      masterData: masterData,
      transactionRunner: runner,
    );

    final duplicateOutcomes = await Future.wait([
      _capture(
        repository.quickCreate(
          ItemQuickCreateRequest(
            code: 'Q-1',
            name: 'مادة أولى',
            groupId: group.id,
            typeId: type.id,
          ),
        ),
      ),
      _capture(
        repository.quickCreate(
          ItemQuickCreateRequest(
            code: ' q-1 ',
            name: 'مادة ثانية',
            groupId: group.id,
            typeId: type.id,
          ),
        ),
      ),
    ]);
    expect(duplicateOutcomes.whereType<StateError>(), hasLength(1));
    final first = duplicateOutcomes.whereType<Item>().single;
    expect(first.groupEntityId, group.id);
    expect(first.typeEntityId, type.id);
    expect(first.groupName, 'مجموعة الاختبار');
    expect(first.typeName, 'نوع الاختبار');

    await repository.delete(first.entityId);
    final afterDelete = await repository.quickCreate(
      ItemQuickCreateRequest(
        code: 'Q-2',
        name: 'مادة بعد الحذف',
        groupId: group.id,
        typeId: type.id,
      ),
    );
    expect(afterDelete.entityId, isNot(first.entityId));
  });
}

Future<Object> _capture(Future<Object> operation) async {
  try {
    return await operation;
  } catch (error) {
    return error;
  }
}

Party _party({required String id, required int number}) {
  return Party(
    id: id,
    number: number,
    createdAt: DateTime(2026, 8, 11),
    name: 'طرف حفظ عادي $id',
    type: PartyType.customer,
    workplace: '',
    branch: '',
    phone: '',
    alternatePhone: '',
    city: '',
    address: '',
    notes: '',
    balanceIqd: 0,
    balanceUsd: 0,
  );
}
