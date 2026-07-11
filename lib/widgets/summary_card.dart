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
                if (icon != null) Icon(icon, color: color, size: 20),
                if (icon != null) const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
