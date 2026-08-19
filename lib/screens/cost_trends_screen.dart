import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cost_trend_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/cost_trend_service.dart';
import '../services/recurring_payment_detector.dart' show RecurrenceRhythmLabel;
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';

const _monthAbbreviations = ['Jan', 'Feb', 'Mrz', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

const _labelWidth = 200.0;
const _trendWidth = 84.0;
const _monthWidth = 72.0;
const _yearWidth = 92.0;

/// A spreadsheet-style year overview dedicated to costs that repeat or
/// otherwise show a predictable pattern - the two things a household budget
/// can actually plan around, as opposed to one-off spending. Two sections:
///
/// - "Wiederkehrende Zahlungen": every auto-detected recurring payment
///   (Abo/Vertrag), same detection as [RecurringPaymentsScreen] but pivoted
///   across all 12 months here instead of shown as a flat list.
/// - "Kostentrends": expense categories whose recent spending is regular
///   enough (present in most of the last few months) to extrapolate, with a
///   rising/falling/stable indicator.
///
/// In both sections, months with no actual booking yet are filled with a
/// clearly marked forecast (italic + label) that a real Kontoauszug-Buchung
/// automatically overrides the moment it's imported - never a fixed
/// allocation, always just the current best guess.
class CostTrendsScreen extends ConsumerWidget {
  const CostTrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final data = ref.watch(costTrendProvider);
    final colors = context.appleColors;

    final tableWidth = _labelWidth + _trendWidth + _monthWidth * 12 + _yearWidth;
    final isEmpty = data.recurringRows.isEmpty && data.trendRows.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(icon: const Icon(CupertinoIcons.chevron_left), onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1),
          Center(child: Text('$year', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(icon: const Icon(CupertinoIcons.chevron_right), onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const AppleLargeTitle('Kostentrends'),
            const PersonFilterBar(),
            if (!isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Kursiv = Prognose, kein tatsächlicher Kontoauszug. Sobald ein Monat importiert wird, ersetzt '
                  'die echte Buchung automatisch die Prognose.',
                  style: TextStyle(color: colors.secondaryLabel, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Noch keine wiederkehrenden oder regelmäßigen Kosten erkannt. Dafür werden mehrere '
                          'Buchungen mit ähnlichem Muster benötigt (z.B. eine feste Miete oder monatlich '
                          'wiederkehrende Lebensmitteleinkäufe).',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.secondaryLabel),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: tableWidth,
                          child: Table(
                            columnWidths: {
                              0: const FixedColumnWidth(_labelWidth),
                              1: const FixedColumnWidth(_trendWidth),
                              for (var i = 0; i < 12; i++) 2 + i: const FixedColumnWidth(_monthWidth),
                              14: const FixedColumnWidth(_yearWidth),
                            },
                            children: [
                              _headerRow(context),
                              _totalRow(context, 'Gesamt', data.monthlyCombinedTotals, data.yearRecurringTotal + data.yearTrendTotal, colors.danger),
                              ..._sectionRows(context, 'Wiederkehrende Zahlungen', data.recurringRows, colors, data.yearRecurringTotal),
                              ..._sectionRows(context, 'Kostentrends', data.trendRows, colors, data.yearTrendTotal),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _headerRow(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return TableRow(
      children: [
        _cell('', style),
        _cell('Trend', style, align: TextAlign.center),
        for (final m in _monthAbbreviations) _cell(m, style, align: TextAlign.right),
        _cell('Jahr', style, align: TextAlign.right),
      ],
    );
  }

  TableRow _totalRow(BuildContext context, String label, List<double> monthly, double yearTotal, Color color) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color);
    return TableRow(
      children: [
        _cell(label, style),
        _cell('', style),
        for (final v in monthly) _cell(v == 0 ? '—' : currencyFormat.format(v), style, align: TextAlign.right),
        _cell(currencyFormat.format(yearTotal), style, align: TextAlign.right),
      ],
    );
  }

  List<TableRow> _sectionRows(BuildContext context, String title, List<CostTrendRow> rows, AppleSemantics colors, double sectionTotal) {
    if (rows.isEmpty) return const [];

    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    final rowStyle = Theme.of(context).textTheme.bodyMedium;
    final subStyle = Theme.of(context).textTheme.bodySmall;

    final result = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: colors.secondaryGroupedBackground),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Row(
              children: [
                Expanded(child: _cell(title, titleStyle)),
                Text(currencyFormat.format(sectionTotal), style: titleStyle),
                const SizedBox(width: 6),
              ],
            ),
          ),
          for (var i = 0; i < 14; i++) _cell('', titleStyle),
        ],
      ),
    ];

    for (final row in rows) {
      final combined = row.combinedAmounts;
      result.add(TableRow(
        decoration: BoxDecoration(color: Color(row.categoryColorValue).withValues(alpha: 0.10)),
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              CircleAvatar(radius: 5, backgroundColor: Color(row.categoryColorValue)),
              const SizedBox(width: 6),
              Expanded(child: _cell(row.label, rowStyle)),
            ],
          ),
          Center(child: _TrendBadge(row: row, style: subStyle)),
          for (var i = 0; i < 12; i++)
            _cell(
              combined[i] == 0 ? '—' : currencyFormat.format(combined[i]),
              row.monthlyAmounts[i] == 0 && row.forecastAmounts[i] != 0
                  ? rowStyle?.copyWith(fontStyle: FontStyle.italic, color: colors.secondaryLabel)
                  : rowStyle,
              align: TextAlign.right,
            ),
          _cell(currencyFormat.format(row.yearTotal), rowStyle?.copyWith(fontWeight: FontWeight.w600), align: TextAlign.right),
        ],
      ));
    }
    return result;
  }

  Widget _cell(String text, TextStyle? style, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(text, style: style, textAlign: align, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Small pill next to each row: the recurrence rhythm for a detected
/// series ("Monatlich"), or a rising/falling/stable arrow plus the average
/// monthly change for a category-trend row.
class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.row, required this.style});

  final CostTrendRow row;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;

    if (row.isRecurringSeries) {
      return Text(row.rhythm!.label, style: style, textAlign: TextAlign.center);
    }

    final direction = row.direction!;
    final (icon, color) = switch (direction) {
      CostTrendDirection.rising => (CupertinoIcons.arrow_up_right, colors.danger),
      CostTrendDirection.falling => (CupertinoIcons.arrow_down_right, colors.success),
      CostTrendDirection.stable => (CupertinoIcons.arrow_right, colors.secondaryLabel),
    };
    final change = row.relativeMonthlyChange ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          direction == CostTrendDirection.stable ? 'Stabil' : '${(change * 100).abs().toStringAsFixed(0)}%/Mo.',
          style: style?.copyWith(color: color),
        ),
      ],
    );
  }
}
