import 'package:flutter/material.dart';

import '../../../core/design/app_design_system.dart';
import '../data/report_demo_catalog.dart';
import 'report_definition.dart';
import 'widgets/report_section_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportDefinition? _selectedReport;

  void _openReport(ReportDefinition report) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedReport = report);
  }

  void _handleBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedReport != null) {
      setState(() => _selectedReport = null);
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedReport = _selectedReport;
    final accentColor =
        selectedReport?.palette.middle ?? AppModuleColors.reports;
    final tint = Color.alphaBlend(
      accentColor.withAlpha(12),
      AppColors.surface,
    );

    return PopScope(
      canPop: selectedReport == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: AppScreenShell(
        key: const Key('reportsScreen'),
        title: selectedReport?.title ?? 'التقارير',
        backgroundColor: tint,
        onBack: _handleBack,
        body: ColoredBox(
          key: const Key('reportsTintBackground'),
          color: tint,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: selectedReport == null
                  ? _ReportsHub(onOpenReport: _openReport)
                  : KeyedSubtree(
                      key: Key('reportSection_${selectedReport.id}'),
                      child: ReportSectionView(
                        definition: selectedReport,
                        definitions: reportDefinitions,
                        onDefinitionChanged: _openReport,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportsHub extends StatelessWidget {
  const _ReportsHub({required this.onOpenReport});

  final ValueChanged<ReportDefinition> onOpenReport;

  @override
  Widget build(BuildContext context) {
    final rows = <List<ReportDefinition>>[
      reportDefinitions.sublist(0, 3),
      reportDefinitions.sublist(3, 6),
      reportDefinitions.sublist(6),
    ];

    return Column(
      key: const Key('reportsHub'),
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _ReportsHubRow(
              key: Key('reportsHubRow_$index'),
              reports: rows[index],
              onOpenReport: onOpenReport,
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportsHubRow extends StatelessWidget {
  const _ReportsHubRow({
    required this.reports,
    required this.onOpenReport,
    super.key,
  });

  final List<ReportDefinition> reports;
  final ValueChanged<ReportDefinition> onOpenReport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final cardWidth = (constraints.maxWidth - spacing * 2) / 3;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < reports.length; index++) ...[
              if (index > 0) const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: AppModuleCard(
                  key: Key('reportSectionCard_${reports[index].id}'),
                  title: reports[index].title,
                  icon: reports[index].icon,
                  colors: reports[index].palette.gradient,
                  shadowColor: reports[index].palette.shadow,
                  onTap: () => onOpenReport(reports[index]),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
