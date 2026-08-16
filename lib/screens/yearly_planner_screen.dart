import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/transaction_providers.dart';
import '../providers/yearly_planner_providers.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';

const _monthAbbreviations = ['Jan', 'Feb', 'Mrz', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

const _labelWidth = 180.0;
const _dueDayWidth = 48.0;
const _percentWidth = 52.0;
const _monthWidth = 72.0;
const _yearWidth = 92.0;

/// A spreadsheet-style yearly planner: every recurring/unique payment as a
/// row (grouped by category), one column per month plus a year total - the
/// "extra Übersicht" view, separate from the regular Dashboard/Jahresübersicht,
/// for seeing every planned/booked item side by side across the whole year.
class YearlyPlannerScreen extends ConsumerWidget {
  const YearlyPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final data = ref.watch(yearlyPlannerProvider);
    final colors = context.appleColors;

    final tableWidth = _labelWidth + _dueDayWidth + _percentWidth + _monthWidth * 12 + _yearWidth;

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
            const AppleLargeTitle('Jahresplaner'),
            const PersonFilterBar(),
            if (data.incomeGroups.isNotEmpty || data.expenseGroups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Kursiv = Prognose aus erkannten wiederkehrenden Zahlungen, kein tatsächlicher Kontoauszug. '
                  'Sobald ein Monat importiert wird, ersetzt die echte Buchung automatisch die Prognose.',
                  style: TextStyle(color: colors.secondaryLabel, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: (data.incomeGroups.isEmpty && data.expenseGroups.isEmpty)
                  ? Center(child: Text('Keine Buchungen für $year.', style: TextStyle(color: colors.secondaryLabel)))
                  : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: SizedBox(
                          width: tableWidth,
                          child: Table(
                            columnWidths: {
                              0: const FixedColumnWidth(_labelWidth),
                              1: const FixedColumnWidth(_dueDayWidth),
                              2: const FixedColumnWidth(_percentWidth),
                              for (var i = 0; i < 12; i++) 3 + i: const FixedColumnWidth(_monthWidth),
                              15: const FixedColumnWidth(_yearWidth),
                            },
                            children: [
                              _headerRow(context),
                              _totalRow(context, 'Gesamteinnahmen', data.monthlyIncomeTotals, data.yearIncomeTotal, colors.success),
                              _totalRow(context, 'Gesamtausgaben', data.monthlyExpenseTotals, data.yearExpenseTotal, colors.danger),
                              _balanceRow(context, data),
                              ..._sectionRows(context, 'Einnahmen', data.incomeGroups, colors),
                              ..._sectionRows(context, 'Ausgaben', data.expenseGroups, colors),
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
        _cell('Termin', style, align: TextAlign.center),
        _cell('in %', style, align: TextAlign.center),
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
        _cell('', style),
        for (final v in monthly) _cell(v == 0 ? '—' : currencyFormat.format(v), style, align: TextAlign.right),
        _cell(currencyFormat.format(yearTotal), style, align: TextAlign.right),
      ],
    );
  }

  TableRow _balanceRow(BuildContext context, YearlyPlannerData data) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
    final colors = context.appleColors;
    final monthlyBalance = [for (var i = 0; i < 12; i++) data.monthlyIncomeTotals[i] - data.monthlyExpenseTotals[i]];
    final yearBalance = data.yearIncomeTotal - data.yearExpenseTotal;
    return TableRow(
      children: [
        _cell('Saldo', baseStyle),
        _cell('', baseStyle),
        _cell('', baseStyle),
        for (final v in monthlyBalance) _cell(currencyFormat.format(v), baseStyle?.copyWith(color: v >= 0 ? colors.success : colors.danger), align: TextAlign.right),
        _cell(currencyFormat.format(yearBalance), baseStyle?.copyWith(color: yearBalance >= 0 ? colors.success : colors.danger), align: TextAlign.right),
      ],
    );
  }

  List<TableRow> _sectionRows(BuildContext context, String title, List<YearlyPlannerCategoryGroup> groups, AppleSemantics colors) {
    if (groups.isEmpty) return const [];

    final titleStyle = Theme.of(context).textTheme.headlineMedium;
    final categoryStyle = Theme.of(context).textTheme.titleSmall;
    final rowStyle = Theme.of(context).textTheme.bodyMedium;
    final percentStyle = Theme.of(context).textTheme.bodySmall;

    final rows = <TableRow>[
      TableRow(
        decoration: BoxDecoration(color: colors.secondaryGroupedBackground),
        children: [
          Padding(padding: const EdgeInsets.only(top: 16, bottom: 4), child: _cell(title, titleStyle)),
          for (var i = 0; i < 15; i++) _cell('', titleStyle),
        ],
      ),
    ];

    for (final group in groups) {
      rows.add(TableRow(
        decoration: BoxDecoration(color: Color(group.category.colorValue).withValues(alpha: 0.12)),
        children: [
          Row(
            children: [
              const SizedBox(width: 8),
              CircleAvatar(radius: 5, backgroundColor: Color(group.category.colorValue)),
              const SizedBox(width: 6),
              Expanded(child: _cell(group.category.name, categoryStyle)),
            ],
          ),
          _cell('', categoryStyle),
          _cell('', categoryStyle),
          for (var i = 0; i < 12; i++) _cell('', categoryStyle),
          _cell(currencyFormat.format(group.yearTotal), categoryStyle, align: TextAlign.right),
        ],
      ));

      for (final row in group.rows) {
        final combined = row.combinedAmounts;
        rows.add(TableRow(
          children: [
            Padding(padding: const EdgeInsets.only(left: 24), child: _cell(row.label, rowStyle)),
            _cell('${row.dueDay}.', percentStyle, align: TextAlign.center),
            _cell('${(row.percentOfTotal * 100).toStringAsFixed(2)}%', percentStyle, align: TextAlign.center),
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
    }
    return rows;
  }

  Widget _cell(String text, TextStyle? style, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Text(text, style: style, textAlign: align, overflow: TextOverflow.ellipsis),
    );
  }
}
