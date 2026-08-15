import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/insight_providers.dart';
import '../services/optimization_service.dart';
import '../theme/app_theme.dart';
import 'apple_widgets.dart';

/// Shows rule-based optimization hints for the currently selected month
/// (e.g. duplicate subscriptions, spending spikes, long-running Abos).
/// Renders nothing when there is nothing to report.
class InsightsSection extends ConsumerWidget {
  const InsightsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppleSectionHeader('Optimierungspotenzial'),
        for (final insight in insights) _InsightCard(insight: insight),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final isWarning = insight.severity == InsightSeverity.warning;
    final color = isWarning ? context.appleColors.warning : Theme.of(context).colorScheme.primary;

    return AppleCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ListTile(
        leading: Icon(isWarning ? CupertinoIcons.lightbulb : CupertinoIcons.info_circle, color: color),
        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(insight.description),
      ),
    );
  }
}
