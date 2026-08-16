import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/recurring_payment_providers.dart';
import '../services/recurring_payment_detector.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';

/// Lists every recurring payment (Abo/Vertrag) the app auto-detected from
/// booking patterns alone - no manual "recurring" flag required. See
/// [RecurringPaymentDetector] for the detection logic.
class RecurringPaymentsScreen extends ConsumerWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(recurringPaymentsProvider);
    final colors = context.appleColors;

    final monthlyTotal = groups
        .where((g) => g.rhythm == RecurrenceRhythm.monthly && g.latestAmount < 0)
        .fold<double>(0, (s, g) => s + g.latestAmount.abs());

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Abos & Verträge'),
            const PersonFilterBar(),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Noch keine wiederkehrenden Zahlungen erkannt. Dafür werden mindestens 3 Buchungen mit '
                  'ähnlichem Betrag und ähnlichem Text in einem regelmäßigen Abstand (wöchentlich, monatlich '
                  'oder jährlich) benötigt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.secondaryLabel),
                ),
              )
            else ...[
              if (monthlyTotal > 0)
                AppleHeroCard(label: 'Monatliche Abos', value: currencyFormat.format(monthlyTotal)),
              AppleGroupedSection(children: [for (final group in groups) _RecurringPaymentTile(group: group)]),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecurringPaymentTile extends StatelessWidget {
  const _RecurringPaymentTile({required this.group});

  final RecurringPaymentGroup group;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final isIncome = group.latestAmount >= 0;

    return ListTile(
      leading: Container(
        width: 29,
        height: 29,
        decoration: BoxDecoration(color: AppleColors.indigo, borderRadius: BorderRadius.circular(7)),
        child: const Icon(CupertinoIcons.repeat, color: Colors.white, size: 16),
      ),
      title: Text(group.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${group.rhythm.label} · ${group.occurrenceCount}x erkannt · Zuletzt ${dateFormat.format(group.lastDate)}'),
      trailing: Text(
        currencyFormat.format(group.latestAmount.abs()),
        style: TextStyle(color: isIncome ? colors.success : colors.danger, fontWeight: FontWeight.bold),
      ),
    );
  }
}
