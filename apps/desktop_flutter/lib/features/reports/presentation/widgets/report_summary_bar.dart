import 'package:flutter/material.dart';

import '../../../../core/design/app_design_system.dart';
import '../report_definition.dart';

class ReportSummaryBar extends StatelessWidget {
  const ReportSummaryBar({
    required this.reportId,
    required this.variantId,
    required this.metrics,
    required this.matchingCount,
    required this.accentColor,
    super.key,
  });

  final String reportId;
  final String variantId;
  final List<ReportMetricValue> metrics;
  final int matchingCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    const iqdSuffix = ' - دينار';
    const usdSuffix = ' - دولار';
    final allMetrics = <_ReportSummaryMetricData>[
      _ReportSummaryMetricData(
        key: Key('reportMetric_${reportId}_${variantId}_matches'),
        label: 'النتائج المطابقة',
        value: '$matchingCount',
      ),
      for (var index = 0; index < metrics.length; index++)
        _ReportSummaryMetricData(
          key: Key('reportMetric_${reportId}_${variantId}_$index'),
          label: metrics[index].label,
          value: metrics[index].value,
        ),
    ];
    final generalMetrics = allMetrics
        .where(
          (metric) =>
              !metric.label.endsWith(iqdSuffix) &&
              !metric.label.endsWith(usdSuffix),
        )
        .toList(growable: false);
    final iqdMetrics = allMetrics
        .where((metric) => metric.label.endsWith(iqdSuffix))
        .map((metric) => metric.withoutSuffix(iqdSuffix))
        .toList(growable: false);
    final usdMetrics = allMetrics
        .where((metric) => metric.label.endsWith(usdSuffix))
        .map((metric) => metric.withoutSuffix(usdSuffix))
        .toList(growable: false);
    final groups = <_ReportSummaryGroupData>[
      if (generalMetrics.isNotEmpty)
        _ReportSummaryGroupData(
          title: 'عام',
          metrics: generalMetrics,
        ),
      if (iqdMetrics.isNotEmpty)
        _ReportSummaryGroupData(
          title: 'دينار',
          metrics: iqdMetrics,
        ),
      if (usdMetrics.isNotEmpty)
        _ReportSummaryGroupData(
          title: 'دولار',
          metrics: usdMetrics,
        ),
    ];

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'ملخص التقرير، $matchingCount نتيجة مطابقة',
      child: SizedBox(
        height: 88,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(
              color: Color.lerp(
                accentColor,
                AppColors.surface,
                0.58,
              )!,
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              for (var index = 0; index < groups.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: groups[index].flex,
                  child: _ReportSummaryGroup(
                    group: groups[index],
                    accentColor: accentColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportSummaryGroup extends StatelessWidget {
  const _ReportSummaryGroup({
    required this.group,
    required this.accentColor,
  });

  final _ReportSummaryGroupData group;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accentColor.withAlpha(10),
          AppColors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: accentColor.withAlpha(48)),
      ),
      child: Column(
        children: [
          Text(
            group.title,
            maxLines: 1,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                for (var index = 0;
                    index < group.metrics.length;
                    index++) ...[
                  if (index > 0)
                    VerticalDivider(
                      width: AppSpacing.sm,
                      thickness: 1,
                      color: accentColor.withAlpha(34),
                    ),
                  Expanded(
                    child: _ReportSummaryMetric(
                      key: group.metrics[index].key,
                      metric: group.metrics[index],
                      accentColor: accentColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryMetric extends StatelessWidget {
  const _ReportSummaryMetric({
    required this.metric,
    required this.accentColor,
    super.key,
  });

  final _ReportSummaryMetricData metric;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReportSummaryGroupData {
  const _ReportSummaryGroupData({
    required this.title,
    required this.metrics,
  });

  final String title;
  final List<_ReportSummaryMetricData> metrics;

  int get flex {
    if (metrics.length < 2) return 2;
    if (metrics.length > 5) return 5;
    return metrics.length;
  }
}

class _ReportSummaryMetricData {
  const _ReportSummaryMetricData({
    required this.key,
    required this.label,
    required this.value,
  });

  final Key key;
  final String label;
  final String value;

  _ReportSummaryMetricData withoutSuffix(String suffix) {
    return _ReportSummaryMetricData(
      key: key,
      label: label.substring(0, label.length - suffix.length),
      value: value,
    );
  }
}
