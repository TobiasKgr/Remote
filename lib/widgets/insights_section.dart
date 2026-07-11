import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/insight_providers.dart';
import '../services/optimization_service.dart';

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
        Text('Optimierungspotenzial', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
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
    final color = isWarning ? Colors.amber.shade800 : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(isWarning ? Icons.lightbulb_outline : Icons.info_outline, color: color),
        title: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(insight.description),
      ),
    );
  }
}
