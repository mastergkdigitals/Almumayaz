import 'dart:async';

import 'package:erp/core/application/invoice_editor_coordinator.dart';
import 'package:erp/core/data/app_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps invoice loading to ready and empty states', () async {
    final ready = InvoiceEditorCoordinator<int>(
      loadRecords: () async => [101, 102, 103],
    );
    final empty = InvoiceEditorCoordinator<int>(
      loadRecords: () async => [],
    );

    expect((await ready.load()).status, AppDataStatus.ready);
    expect(ready.state.data, [101, 102, 103]);
    expect((await empty.load()).status, AppDataStatus.empty);
  });

  test('maps missing references and failures to explicit states', () async {
    final missing = InvoiceEditorCoordinator<int>(
      loadRecords: () async => throw const InvoiceMissingReferenceException(
        'مرجع مفقود',
      ),
    );
    final failing = InvoiceEditorCoordinator<int>(
      loadRecords: () async => throw StateError('فشل'),
    );

    expect((await missing.load()).status, AppDataStatus.missingReference);
    expect(missing.state.message, 'مرجع مفقود');
    expect((await failing.load()).status, AppDataStatus.error);
  });

  test('serializes invoice mutations and always clears busy state', () async {
    final coordinator = InvoiceEditorCoordinator<int>(
      loadRecords: () async => [],
    );
    final blocker = Completer<void>();
    final first = coordinator.mutate(() async {
      await blocker.future;
      return 1;
    });

    expect(coordinator.isBusy, isTrue);
    await expectLater(
      coordinator.mutate(() async => 2),
      throwsStateError,
    );
    blocker.complete();
    expect(await first, 1);
    expect(coordinator.isBusy, isFalse);
  });

  test('keeps the newest result when overlapping loads finish out of order',
      () async {
    final first = Completer<List<int>>();
    final second = Completer<List<int>>();
    var calls = 0;
    final coordinator = InvoiceEditorCoordinator<int>(
      loadRecords: () => calls++ == 0 ? first.future : second.future,
    );

    final olderLoad = coordinator.load();
    final newerLoad = coordinator.load();
    second.complete([202]);
    await newerLoad;
    first.complete([101]);
    await olderLoad;

    expect(coordinator.state.status, AppDataStatus.ready);
    expect(coordinator.state.data, [202]);
  });
}
