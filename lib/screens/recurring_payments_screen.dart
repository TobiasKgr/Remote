import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/recurring_payment_providers.dart';
import '../services/fixed_cost_radar_service.dart';
import '../services/recurring_payment_detector.dart';
import '../services/what_if_simulator.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';

/// Lists every recurring payment (Abo/Vertrag) the app auto-detected from
/// booking patterns alone - no manual "recurring" flag required. See
/// [RecurringPaymentDetector] for the detection logic. Also hosts the
/// "Was wäre wenn?" simulator: ticking one or more Abos shows the
/// projected savings from cancelling them, without actually changing
/// anything.
class RecurringPaymentsScreen extends ConsumerStatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  ConsumerState<RecurringPaymentsScreen> createState() => _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends ConsumerState<RecurringPaymentsScreen> {
  final _simulatedIndices = <int>{};
  int _simulationMonths = 12;

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(recurringPaymentsProvider);
    final radar = ref.watch(fixedCostRadarProvider);
    final colors = context.appleColors;

    final monthlyTotal = groups
        .where((g) => g.rhythm == RecurrenceRhythm.monthly && g.latestAmount < 0)
        .fold<double>(0, (s, g) => s + g.latestAmount.abs());

    final cancelledGroups = [for (final i in _simulatedIndices) if (i < groups.length) groups[i]];
    final whatIf = computeWhatIfSavings(cancelledGroups: cancelledGroups, months: _simulationMonths);

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
              if (radar.ratio != null) _FixedCostRadarCard(radar: radar),
              const AppleSectionHeader('Erkannte Serien'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Häkchen setzen, um eine Kündigung durchzuspielen ("Was wäre wenn?") - es wird nichts '
                  'tatsächlich geändert.',
                  style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              AppleGroupedSection(
                children: [
                  for (var i = 0; i < groups.length; i++)
                    _RecurringPaymentTile(
                      group: groups[i],
                      simulated: _simulatedIndices.contains(i),
                      onSimulatedChanged: groups[i].latestAmount < 0
                          ? (value) => setState(() => value ? _simulatedIndices.add(i) : _simulatedIndices.remove(i))
                          : null,
                    ),
                ],
              ),
              if (cancelledGroups.isNotEmpty) _WhatIfCard(result: whatIf, months: _simulationMonths, onMonthsChanged: (m) => setState(() => _simulationMonths = m)),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Fixkosten-Radar": share of average monthly income already committed to
/// detected recurring expenses - green/orange/red like the common
/// household-budgeting rule of thumb (roughly: under ~30% comfortable,
/// 30-50% tight, over 50% a real constraint).
class _FixedCostRadarCard extends StatelessWidget {
  const _FixedCostRadarCard({required this.radar});

  final FixedCostRadarResult radar;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final ratio = radar.ratio!.clamp(0.0, 1.5);
    final color = ratio < 0.3 ? colors.success : (ratio < 0.5 ? colors.warning : colors.danger);

    return AppleCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fixkosten-Anteil am Einkommen', style: Theme.of(context).textTheme.bodyMedium),
                Text('${(radar.ratio! * 100).round()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: colors.groupedBackground,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${currencyFormat.format(radar.monthlyFixedCosts)} von durchschnittlich '
              '${currencyFormat.format(radar.averageMonthlyIncome)}/Monat Einkommen sind bereits durch erkannte '
              'Abos/Verträge gebunden.',
              style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the projected savings from cancelling every currently-ticked Abo,
/// over a user-chosen horizon (1/6/12 Monate).
class _WhatIfCard extends StatelessWidget {
  const _WhatIfCard({required this.result, required this.months, required this.onMonthsChanged});

  final WhatIfResult result;
  final int months;
  final ValueChanged<int> onMonthsChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: AppleCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(CupertinoIcons.wand_stars, color: colors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('Was wäre wenn?', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('1 Monat')),
                  ButtonSegment(value: 6, label: Text('6 Monate')),
                  ButtonSegment(value: 12, label: Text('12 Monate')),
                ],
                selected: {months},
                onSelectionChanged: (s) => onMonthsChanged(s.first),
              ),
              const SizedBox(height: 12),
              Text(
                'Bei Kündigung der ausgewählten Abos sparst du ${currencyFormat.format(result.monthlySavings)}/Monat - '
                'über $months Monat(e) macht das ${currencyFormat.format(result.totalSavings)}.',
                style: TextStyle(color: colors.secondaryLabel, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecurringPaymentTile extends StatelessWidget {
  const _RecurringPaymentTile({required this.group, required this.simulated, this.onSimulatedChanged});

  final RecurringPaymentGroup group;
  final bool simulated;
  final ValueChanged<bool>? onSimulatedChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final isIncome = group.latestAmount >= 0;

    return ListTile(
      leading: onSimulatedChanged != null
          ? Checkbox(value: simulated, onChanged: (v) => onSimulatedChanged!(v ?? false))
          : Container(
              width: 29,
              height: 29,
              decoration: BoxDecoration(color: AppleColors.indigo, borderRadius: BorderRadius.circular(7)),
              child: const Icon(CupertinoIcons.repeat, color: Colors.white, size: 16),
            ),
      title: Text(group.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${group.rhythm.label} · ${group.occurrenceCount}x erkannt · Zuletzt ${dateFormat.format(group.lastDate)}'),
          if (group.hasPriceChange)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.arrow_up_arrow_down, size: 12, color: colors.warning),
                  const SizedBox(width: 4),
                  Text(
                    'Preis geändert: ${currencyFormat.format(group.previous!.amount.abs())} → ${currencyFormat.format(group.latestAmount.abs())}',
                    style: TextStyle(color: colors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Text(
        currencyFormat.format(group.latestAmount.abs()),
        style: TextStyle(color: isIncome ? colors.success : colors.danger, fontWeight: FontWeight.bold),
      ),
    );
  }
}
