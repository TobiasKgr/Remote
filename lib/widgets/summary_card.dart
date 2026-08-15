import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.label, required this.amount, required this.color, this.icon});

  final String label;
  final double amount;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, color: color, size: 16),
                if (icon != null) const SizedBox(width: 6),
                Expanded(
                  child: Text(label, style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                currencyFormat.format(amount),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(color: color),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
