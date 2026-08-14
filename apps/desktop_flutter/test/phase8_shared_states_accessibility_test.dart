import 'dart:ui' as ui;

import 'package:erp/app/app.dart';
import 'package:erp/core/app_state/app_store.dart';
import 'package:erp/core/design/app_design_system.dart';
import 'package:erp/core/domain/business_values.dart';
import 'package:erp/features/authentication/domain/session_models.dart';
import 'package:erp/features/permissions/domain/permission_models.dart';
import 'package:erp/features/settings/presentation/settings_screen.dart';
import 'package:erp/features/users/domain/user_models.dart';
import 'package:erp/features/warehouses/domain/warehouse.dart';
import 'package:erp/features/warehouses/presentation/widgets/warehouse_inventory_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 8 shared state accessibility', () {
    testWidgets(
      'announces six RTL state panels once and keeps the action separate',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.binding.setSurfaceSize(const Size(1280, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var retries = 0;
        const states = <(AppStateType, String, String)>[
          (AppStateType.loading, 'جاري التحميل', 'يرجى الانتظار قليلاً'),
          (AppStateType.empty, 'لا توجد بيانات', 'أضف سجلاً للمتابعة'),
          (
            AppStateType.missingReference,
            'مرجع البيانات غير متاح',
            'اختر مرجعاً متاحاً',
          ),
          (AppStateType.error, 'تعذر تحميل البيانات', 'حاول مرة أخرى'),
          (
            AppStateType.permissionDenied,
            'ليست لديك الصلاحية المطلوبة',
            'راجع مسؤول النظام',
          ),
          (
            AppStateType.unavailable,
            'الميزة غير متاحة',
            'اختر سجلاً أولاً',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (var index = 0; index < states.length; index++)
                        SizedBox(
                          width: 380,
                          child: AppStatePanel(
                            key: Key('phase8State_$index'),
                            type: states[index].$1,
                            title: states[index].$2,
                            message: states[index].$3,
                            actionLabel:
                                index == 3 ? 'إعادة المحاولة' : null,
                            onAction:
                                index == 3 ? () => retries++ : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final viewport = Offset.zero & const Size(1280, 720);
        for (var index = 0; index < states.length; index++) {
          final panel = find.byKey(Key('phase8State_$index'));
          final announcement = '${states[index].$2}. ${states[index].$3}';
          expect(Directionality.of(tester.element(panel)), TextDirection.rtl);
          expect(viewport.contains(tester.getRect(panel).topLeft), isTrue);
          expect(viewport.contains(tester.getRect(panel).bottomRight), isTrue);
          expect(find.bySemanticsLabel(announcement), findsOneWidget);

          final description = _singleExplicitSemantics(
            tester,
            panel,
            announcement,
          );
          expect(description.container, isTrue);
          expect(description.properties.liveRegion, isTrue);
          expect(description.excludeSemantics, isTrue);
        }

        final retryText = find.text('إعادة المحاولة');
        final retry = find.ancestor(
          of: retryText,
          matching: find.byType(AppRegularButton),
        );
        expect(find.bySemanticsLabel('إعادة المحاولة'), findsOneWidget);
        final errorDescription = find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'تعذر تحميل البيانات. حاول مرة أخرى',
        );
        expect(
          find.descendant(of: errorDescription, matching: retryText),
          findsNothing,
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(_hasFocusWithin(tester, retry), isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(retries, 1);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );

    testWidgets(
      'loading overlay blocks pointer focus keyboard and child semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        var isLoading = false;
        var activations = 0;
        late StateSetter setHostState;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) {
                    setHostState = setState;
                    return AppLoadingOverlay(
                      key: const Key('phase8LoadingOverlay'),
                      isLoading: isLoading,
                      message: 'جاري حفظ السجل',
                      child: Center(
                        child: Semantics(
                          label: 'الإجراء المحجوب',
                          button: true,
                          enabled: true,
                          excludeSemantics: true,
                          onTap: () => activations++,
                          child: TextButton(
                            key: const Key('phase8UnderlyingAction'),
                            focusNode: focusNode,
                            onPressed: () => activations++,
                            child: const Text('تنفيذ'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        focusNode.requestFocus();
        await tester.pump();
        expect(focusNode.hasFocus, isTrue);
        expect(find.bySemanticsLabel('الإجراء المحجوب'), findsOneWidget);

        setHostState(() => isLoading = true);
        await tester.pump();
        expect(focusNode.hasFocus, isFalse);
        expect(find.bySemanticsLabel('الإجراء المحجوب'), findsNothing);
        expect(find.bySemanticsLabel('جاري حفظ السجل'), findsOneWidget);

        final overlaySemantics = _singleExplicitSemantics(
          tester,
          find.byKey(const Key('phase8LoadingOverlay')),
          'جاري حفظ السجل',
        );
        expect(overlaySemantics.container, isTrue);
        expect(overlaySemantics.properties.liveRegion, isTrue);
        expect(overlaySemantics.excludeSemantics, isTrue);

        await tester.tap(
          find.byKey(const Key('phase8UnderlyingAction')),
          warnIfMissed: false,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(activations, 0);

        setHostState(() => isLoading = false);
        await tester.pump();
        expect(find.bySemanticsLabel('الإجراء المحجوب'), findsOneWidget);
        focusNode.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(activations, 1);
        semantics.dispose();
      },
    );

    testWidgets(
      'text loading disabled icon and module controls expose exact semantics',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var normalActivations = 0;
        var loadingActivations = 0;
        var disabledActivations = 0;
        var iconActivations = 0;
        var moduleActivations = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Column(
                  children: [
                    AppButton(
                      key: const Key('phase8NormalButton'),
                      label: 'حفظ',
                      onPressed: () => normalActivations++,
                    ),
                    AppButton(
                      key: const Key('phase8LoadingButton'),
                      label: 'تحديث',
                      isLoading: true,
                      onPressed: () => loadingActivations++,
                    ),
                    AppButton(
                      key: const Key('phase8DisabledButton'),
                      label: 'حذف',
                      onPressed: null,
                    ),
                    AppHeaderIconButton(
                      key: const Key('phase8IconButton'),
                      icon: Icons.print_rounded,
                      tooltip: 'طباعة',
                      onPressed: () => iconActivations++,
                    ),
                    SizedBox(
                      width: 360,
                      height: 150,
                      child: AppModuleCard(
                        key: const Key('phase8DisabledModule'),
                        title: 'النسخ الاحتياطي',
                        icon: Icons.backup_rounded,
                        colors: AppModulePalettes.reports.gradient,
                        shadowColor: AppModulePalettes.reports.shadow,
                        disabledReason: 'تتطلب صلاحية إدارة الإعدادات',
                        onTap: null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        for (final label in [
          'حفظ',
          'تحديث، جاري التنفيذ',
          'حذف',
          'طباعة',
          'النسخ الاحتياطي',
        ]) {
          expect(find.bySemanticsLabel(label), findsOneWidget);
        }

        final normal = _semanticsData(tester, 'حفظ');
        expect(normal.flagsCollection.isButton, isTrue);
        expect(normal.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
        expect(normal.hasAction(ui.SemanticsAction.tap), isTrue);

        final loading = _semanticsData(tester, 'تحديث، جاري التنفيذ');
        expect(loading.flagsCollection.isButton, isTrue);
        expect(loading.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
        expect(loading.flagsCollection.isLiveRegion, isTrue);
        expect(loading.hasAction(ui.SemanticsAction.tap), isFalse);

        final disabled = _semanticsData(tester, 'حذف');
        expect(disabled.flagsCollection.isButton, isTrue);
        expect(disabled.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
        expect(disabled.hasAction(ui.SemanticsAction.tap), isFalse);

        final icon = _semanticsData(tester, 'طباعة');
        expect(icon.flagsCollection.isButton, isTrue);
        expect(icon.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
        expect(icon.hasAction(ui.SemanticsAction.tap), isTrue);

        final module = _semanticsData(tester, 'النسخ الاحتياطي');
        expect(module.flagsCollection.isButton, isTrue);
        expect(module.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
        expect(
          module.hint,
          'غير متاح. تتطلب صلاحية إدارة الإعدادات',
        );
        expect(module.hasAction(ui.SemanticsAction.tap), isFalse);

        await tester.tap(find.byKey(const Key('phase8NormalButton')));
        await tester.tap(find.byKey(const Key('phase8IconButton')));
        await tester.tap(
          find.byKey(const Key('phase8LoadingButton')),
          warnIfMissed: false,
        );
        await tester.tap(
          find.byKey(const Key('phase8DisabledButton')),
          warnIfMissed: false,
        );
        await tester.tap(
          find.byKey(const Key('phase8DisabledModule')),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(normalActivations, 1);
        expect(iconActivations, 1);
        expect(loadingActivations, 0);
        expect(disabledActivations, 0);
        expect(moduleActivations, 0);
        semantics.dispose();
      },
    );

    testWidgets('switch exposes its title hint enabled and toggled state',
        (tester) async {
      final semantics = tester.ensureSemantics();
      var value = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => AppSwitchField(
                  title: 'النسخ التلقائي',
                  subtitle: 'إنشاء نسخة يومية',
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      var data = _semanticsData(tester, 'النسخ التلقائي');
      expect(data.hint, 'إنشاء نسخة يومية');
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      expect(data.flagsCollection.isToggled.toBoolOrNull(), isFalse);
      expect(data.hasAction(ui.SemanticsAction.tap), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      data = _semanticsData(tester, 'النسخ التلقائي');
      expect(data.flagsCollection.isFocused.toBoolOrNull(), isTrue);
      final focusFrame = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(AppSwitchField),
              matching: find.byType(Container),
            ),
          )
          .singleWhere((container) => container.decoration is BoxDecoration);
      final focusDecoration = focusFrame.decoration! as BoxDecoration;
      expect(focusDecoration.border!.top.color, AppColors.navigation);
      expect(focusDecoration.border!.top.width, 2);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      expect(value, isTrue);
      data = _semanticsData(tester, 'النسخ التلقائي');
      expect(data.flagsCollection.isToggled.toBoolOrNull(), isTrue);
      semantics.dispose();
    });

    testWidgets('focusable field icon exposes focus and a visible ring',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: AppFieldIconButton(
                buttonKey: const Key('phase8FocusableFieldIcon'),
                icon: Icons.visibility_rounded,
                tooltip: 'إظهار كلمة المرور',
                canRequestFocus: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final data = _semanticsData(tester, 'إظهار كلمة المرور');
      expect(data.flagsCollection.isFocused.toBoolOrNull(), isTrue);
      final button = tester.widget<IconButton>(
        find.byKey(const Key('phase8FocusableFieldIcon')),
      );
      final focusSide = button.style!.side!.resolve(
        const <WidgetState>{WidgetState.focused},
      );
      expect(focusSide!.color, AppColors.navigation);
      expect(focusSide.width, 2);
      semantics.dispose();
    });

    testWidgets('interactive module mirrors focus and uses a two-tone ring',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                width: 360,
                height: 160,
                child: AppModuleCard(
                  key: const Key('phase8FocusableModule'),
                  title: 'المشتريات',
                  icon: Icons.shopping_cart_rounded,
                  colors: AppModulePalettes.purchases.gradient,
                  shadowColor: AppModulePalettes.purchases.shadow,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final data = _semanticsData(tester, 'المشتريات');
      expect(data.flagsCollection.isFocused.toBoolOrNull(), isTrue);
      final card = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byKey(const Key('phase8FocusableModule')),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .single;
      final decoration = card.decoration! as BoxDecoration;
      expect(decoration.border!.top.color, AppColors.onStrong);
      expect(decoration.border!.top.width, 2);
      expect(
        decoration.boxShadow,
        contains(
          const BoxShadow(
            color: AppColors.navigation,
            blurRadius: 0,
            spreadRadius: 2,
          ),
        ),
      );
      semantics.dispose();
    });

    testWidgets(
      'table exposes headers and activates selected rows with Space',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final tableFocus = FocusNode();
        addTearDown(tableFocus.dispose);
        var activatedIndex = 0;
        var keyboardIndex = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => AppDataTable(
                    key: const Key('phase8SemanticTable'),
                    semanticLabel: 'جدول الأطراف',
                    height: 220,
                    focusNode: tableFocus,
                    onKeyboardSelectionChanged: (index) {
                      keyboardIndex = index;
                    },
                    columns: const [
                      AppTableColumn(label: 'الاسم'),
                      AppTableColumn(label: 'الرصيد', numeric: true),
                    ],
                    rows: [
                      for (var index = 0; index < 2; index++)
                        AppTableRow(
                          rowKey: Key('phase8SemanticRow_$index'),
                          semanticLabel: 'الطرف ${index + 1}',
                          selected: activatedIndex == index,
                          onTap: () {
                            setState(() => activatedIndex = index);
                          },
                          cells: [
                            Text('الطرف ${index + 1}'),
                            Text('${index * 1000}'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final table = _semanticsData(tester, 'جدول الأطراف');
        expect(table.value, 'عدد الصفوف: 2');
        final nameHeader = _semanticsData(tester, 'الاسم');
        final balanceHeader = _semanticsData(tester, 'الرصيد');
        expect(nameHeader.flagsCollection.isHeader, isTrue);
        expect(balanceHeader.flagsCollection.isHeader, isTrue);

        await tester.tap(find.byKey(const Key('phase8SemanticRow_0')));
        await tester.pump();
        expect(tableFocus.hasFocus, isTrue);
        final focusFrame = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byKey(const Key('phase8SemanticTable')),
                matching: find.byType(Container),
              ),
            )
            .singleWhere((container) => container.foregroundDecoration != null);
        final focusDecoration =
            focusFrame.foregroundDecoration! as BoxDecoration;
        expect(focusDecoration.border!.top.color, AppColors.navigation);
        expect(focusDecoration.border!.top.width, 2);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(keyboardIndex, 1);
        var secondRow = _semanticsData(tester, 'الطرف 2');
        expect(secondRow.value, 'الصف 2 من 2');
        expect(secondRow.flagsCollection.isButton, isTrue);
        expect(secondRow.flagsCollection.isSelected.toBoolOrNull(), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
        expect(activatedIndex, 1);
        expect(tableFocus.hasFocus, isTrue);
        secondRow = _semanticsData(tester, 'الطرف 2');
        expect(secondRow.flagsCollection.isSelected.toBoolOrNull(), isTrue);
        semantics.dispose();
      },
    );

    testWidgets(
      'Settings uses a permission panel and explains disabled sections',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.binding.setSurfaceSize(const Size(1280, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final deniedStore = await _settingsDeniedStore();
        addTearDown(deniedStore.dispose);
        await tester.pumpWidget(_settingsHarness(deniedStore));
        await tester.pumpAndSettle();

        final deniedPanel = find.byKey(
          const Key('settingsViewPermissionRequired'),
        );
        expect(
          tester.widget<AppStatePanel>(deniedPanel).type,
          AppStateType.permissionDenied,
        );
        expect(
          find.bySemanticsLabel(
            'تعذر عرض الإعدادات. ليست لديك صلاحية عرض الإعدادات',
          ),
          findsOneWidget,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        final viewerStore = await _settingsViewerStore();
        addTearDown(viewerStore.dispose);
        await tester.pumpWidget(_settingsHarness(viewerStore));
        await tester.pumpAndSettle();

        final backupCard = find.byKey(
          const Key('settingsSectionCard_backup'),
        );
        final cardData = _semanticsData(tester, 'النسخ الاحتياطي والبيانات');
        expect(cardData.flagsCollection.isButton, isTrue);
        expect(cardData.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
        expect(
          cardData.hint,
          'غير متاح. تتطلب صلاحية إدارة الإعدادات',
        );
        await tester.tap(backupCard, warnIfMissed: false);
        await tester.pump();
        expect(find.byKey(const Key('settingsHub')), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('warehouse no-selection state is shared and unavailable',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final search = TextEditingController();
      addTearDown(search.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SizedBox(
                height: 520,
                child: WarehouseInventoryPanel(
                  warehouse: null,
                  items: const <WarehouseInventoryItem>[],
                  materialCount: 0,
                  totalQuantity: 0,
                  searchController: search,
                  onSearchChanged: (_) {},
                  onOpenProducts: null,
                  onOpenTransfer: null,
                  height: 280,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final table = find.byKey(const Key('warehouseInventoryTable'));
      final panel = find.descendant(
        of: table,
        matching: find.byType(AppStatePanel),
      );
      expect(tester.widget<AppStatePanel>(panel).type, AppStateType.unavailable);
      expect(
        find.bySemanticsLabel(
          'اختر مخزناً من القائمة. سيظهر مخزون المخزن المحدد هنا.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('empty installment schedule uses the shared empty panel',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => Scaffold(
                body: AppButton(
                  label: 'فتح الأقساط',
                  onPressed: () => AppInstallmentScheduleDialog.show(
                    context,
                    invoiceNumber: '101',
                    customerName: 'زبون الاختبار',
                    currencyCode: 'IQD',
                    entries: const [],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('فتح الأقساط'));
      await tester.pumpAndSettle();

      final table = find.byKey(const Key('appInstallmentScheduleTable'));
      final panel = find.descendant(
        of: table,
        matching: find.byType(AppStatePanel),
      );
      expect(tester.widget<AppStatePanel>(panel).type, AppStateType.empty);
      expect(
        find.bySemanticsLabel('لا توجد أقساط. لا توجد أقساط لهذه القائمة'),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('application installs Arabic Material localizations',
        (tester) async {
      await tester.pumpWidget(const AlmumayazApp());
      await tester.pump();

      final context = tester.element(find.byKey(const Key('loginButton')));
      expect(Localizations.localeOf(context), const Locale('ar', 'IQ'));
      expect(MaterialLocalizations.of(context).cancelButtonLabel, 'الإلغاء');
    });
  });

  test('status and strong action colors meet normal-text contrast', () {
    const pairs = <(Color, Color)>[
      (AppColors.successForeground, AppColors.successSurface),
      (AppColors.warningForeground, AppColors.warningSurface),
      (AppColors.dangerForeground, AppColors.dangerSurface),
      (AppColors.infoForeground, AppColors.infoSurface),
      (AppColors.neutralForeground, AppColors.neutralSurface),
      (AppColors.onStrong, AppColors.successStrong),
      (AppColors.onStrong, AppColors.warningStrong),
      (AppColors.onStrong, AppColors.blue),
      (AppColors.onStrong, AppColors.red),
      (AppColors.onStrong, AppColors.textPrimary),
    ];

    for (final pair in pairs) {
      expect(
        _contrastRatio(pair.$1, pair.$2),
        greaterThanOrEqualTo(4.5),
        reason: '${pair.$1} on ${pair.$2}',
      );
    }
  });
}

Semantics _singleExplicitSemantics(
  WidgetTester tester,
  Finder root,
  String label,
) {
  final matches = tester
      .widgetList<Semantics>(
        find.descendant(of: root, matching: find.byType(Semantics)),
      )
      .where((semantics) => semantics.properties.label == label)
      .toList(growable: false);
  expect(matches, hasLength(1));
  return matches.single;
}

SemanticsData _semanticsData(WidgetTester tester, String label) {
  final finder = find.bySemanticsLabel(label);
  expect(finder, findsOneWidget);
  return tester.getSemantics(finder).getSemanticsData();
}

bool _hasFocusWithin(WidgetTester tester, Finder control) {
  final focusedContext = FocusManager.instance.primaryFocus?.context;
  if (focusedContext == null) {
    return false;
  }
  final controlElement = tester.element(control);
  if (identical(focusedContext, controlElement)) {
    return true;
  }
  var isWithin = false;
  focusedContext.visitAncestorElements((ancestor) {
    if (identical(ancestor, controlElement)) {
      isWithin = true;
      return false;
    }
    return true;
  });
  return isWithin;
}

Future<AppStore> _settingsDeniedStore() async {
  final store = AppStore.demo()..suspendIdleMonitoring();
  await store.signIn(
    SignInCredentials(username: 'admin', password: 'password'),
  );
  final role = await store.services.administration.saveRole(
    RoleSaveRequest(
      name: 'عرض المبيعات فقط لمرحلة 8',
      permissions: {
        PermissionCode(
          module: 'sales',
          action: PermissionAction.view,
        ),
      },
    ),
  );
  final user = await store.services.administration.createUser(
    UserCreateRequest(
      fullName: 'مستخدم بلا إعدادات',
      username: 'phase8.settings.denied',
      roleIds: {role.id},
      initialPassword: 'phase8-password',
    ),
  );
  await store.signOut();
  await store.signIn(
    SignInCredentials(
      username: user.username,
      password: 'phase8-password',
    ),
  );
  store.suspendIdleMonitoring();
  return store;
}

Future<AppStore> _settingsViewerStore() async {
  final store = AppStore.demo()..suspendIdleMonitoring();
  await store.signIn(
    SignInCredentials(username: 'admin', password: 'password'),
  );
  final user = await store.services.administration.createUser(
    UserCreateRequest(
      fullName: 'مستخدم عرض الإعدادات لمرحلة 8',
      username: 'phase8.settings.viewer',
      roleIds: {EntityId.demo('role', 4)},
      initialPassword: 'phase8-password',
    ),
  );
  await store.signOut();
  await store.signIn(
    SignInCredentials(
      username: user.username,
      password: 'phase8-password',
    ),
  );
  store.suspendIdleMonitoring();
  return store;
}

Widget _settingsHarness(AppStore store) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: AppStoreScope(
        store: store,
        child: const SettingsScreen(),
      ),
    ),
  );
}

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = firstLuminance > secondLuminance
      ? firstLuminance
      : secondLuminance;
  final darker = firstLuminance > secondLuminance
      ? secondLuminance
      : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
