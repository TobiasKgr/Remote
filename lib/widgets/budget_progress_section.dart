import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_providers.dart';
import '../utils/formatters.dart';

/// Shows a progress bar per category with a budget set, for the currently
/// selected month/person filter. Renders nothing when no budgets exist.
class BudgetProgressSection extends ConsumerWidget {
  const BudgetProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetProgressForSelectedMonthProvider);
    if (progress.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Budgets', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [for (final p in progress) _BudgetProgressRow(progress: p)],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetProgressRow extends StatelessWidget {
  const _BudgetProgressRow({required this.progress});

  final BudgetProgress progress;

  @override
  Widget build(BuildContext context) {
    final color = progress.ratio >= 1
        ? Colors.red
        : progress.ratio >= 0.8
            ? Colors.amber.shade800
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progress.category.name),
              Text(
                '${currencyFormat.format(progress.spent)} / ${currencyFormat.format(progress.limit)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.ratio.clamp(0, 1).toDouble(),
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
