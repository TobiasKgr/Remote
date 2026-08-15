import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/budget_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'apple_widgets.dart';

/// Shows a progress bar per category with a budget set, for the currently
/// selected month/person filter. Renders nothing when no budgets exist.
class BudgetProgressSection extends ConsumerWidget {
  const BudgetProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetProgressForSelectedMonthProvider);
    return BudgetProgressList(title: 'Budgets', progress: progress);
  }
}

/// Same as [BudgetProgressSection] but aggregated over the selected year
/// (planned = sum of the effective monthly limit across all 12 months).
class YearlyBudgetProgressSection extends ConsumerWidget {
  const YearlyBudgetProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(budgetProgressForSelectedYearProvider);
    return BudgetProgressList(title: 'Jahresbudget', progress: progress);
  }
}

class BudgetProgressList extends StatelessWidget {
  const BudgetProgressList({super.key, required this.title, required this.progress});

  final String title;
  final List<BudgetProgress> progress;

  @override
  Widget build(BuildContext context) {
    if (progress.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppleSectionHeader(title),
        AppleCard(
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
    final colors = context.appleColors;
    final color = progress.ratio >= 1
        ? colors.danger
        : progress.ratio >= 0.8
            ? colors.warning
            : colors.success;

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
