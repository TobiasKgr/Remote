import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../utils/formatters.dart';

class CategoryTotal {
  const CategoryTotal(this.category, this.total);

  final Category category;
  final double total;
}

/// Pie chart with a legend showing how much was spent per category.
class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({super.key, required this.totals});

  final List<CategoryTotal> totals;

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Keine Ausgaben in diesem Zeitraum.')),
      );
    }

    final grandTotal = totals.fold<double>(0, (sum, t) => sum + t.total);

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (final t in totals)
                  PieChartSectionData(
                    value: t.total,
                    color: Color(t.category.colorValue),
                    title: grandTotal == 0 ? '' : '${(t.total / grandTotal * 100).round()}%',
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final t in totals)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, color: Color(t.category.colorValue)),
                  const SizedBox(width: 6),
                  Text('${t.category.name}: ${currencyFormat.format(t.total)}'),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
