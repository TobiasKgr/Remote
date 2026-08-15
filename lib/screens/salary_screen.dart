import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/salary_slip.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/salary_slip_parser_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';
import 'company_car_screen.dart';
import 'salary_slip_form_screen.dart';

class SalaryScreen extends ConsumerStatefulWidget {
  const SalaryScreen({super.key});

  @override
  ConsumerState<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends ConsumerState<SalaryScreen> {
  bool _importing = false;

  Future<void> _importPdf() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result == null || result.files.isEmpty || result.files.single.bytes == null) {
        setState(() => _importing = false);
        return;
      }
      final parsed = await SalarySlipParserService().parseFromBytes(result.files.single.bytes!);
      setState(() => _importing = false);
      if (!mounted) return;

      // If a slip for the same Abrechnungsmonat already exists (re-importing
      // the same or an overlapping PDF), edit that one with the freshly
      // parsed values instead of creating a duplicate entry.
      final period = parsed.period;
      final existing = period == null
          ? null
          : ref.read(salarySlipNotifierProvider).where((s) => s.period.year == period.year && s.period.month == period.month).firstOrNull;

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SalarySlipFormScreen(existing: existing, prefill: parsed)),
      );
    } catch (e) {
      setState(() => _importing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Einlesen der PDF-Datei: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = ref.watch(selectedYearProvider);
    final slips = ref.watch(salarySlipsForSelectedYearProvider);

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Firmenwagen verwalten',
            icon: const Icon(CupertinoIcons.car_fill),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CompanyCarScreen())),
          ),
          IconButton(icon: const Icon(CupertinoIcons.chevron_left), onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1),
          Center(child: Text('$year', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(icon: const Icon(CupertinoIcons.chevron_right), onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PersonFilterBar(),
            Expanded(
              child: _importing
                  ? const Center(child: CircularProgressIndicator())
                  : slips.isEmpty
                      ? ListView(
                          children: [
                            const AppleLargeTitle('Gehalt'),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text('Keine Gehaltsabrechnungen für $year erfasst.', textAlign: TextAlign.center),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 96),
                          children: [
                            const AppleLargeTitle('Gehalt'),
                            _BreakdownChart(slips: slips),
                            const AppleSectionHeader('Gehaltsabrechnungen'),
                            AppleGroupedSection(children: [for (final slip in slips) _SalarySlipTile(slip: slip)]),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'salary_pdf',
            onPressed: _importPdf,
            icon: const Icon(CupertinoIcons.arrow_up_doc_fill),
            label: const Text('PDF importieren'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'salary_manual',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalarySlipFormScreen())),
            icon: const Icon(CupertinoIcons.add),
            label: const Text('Manuell'),
          ),
        ],
      ),
    );
  }
}

class _BreakdownChart extends StatelessWidget {
  const _BreakdownChart({required this.slips});

  final List<SalarySlip> slips;

  @override
  Widget build(BuildContext context) {
    final maxY = slips.fold<double>(0, (m, s) => s.gross > m ? s.gross : m);
    final colors = context.appleColors;

    return AppleCard(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brutto vs. Netto pro Monat', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 1 : maxY * 1.2,
                  barGroups: [
                    for (final slip in slips)
                      BarChartGroupData(x: slip.period.month, barRods: [
                        BarChartRodData(toY: slip.gross, color: AppleColors.gray, width: 8, borderRadius: BorderRadius.circular(3)),
                        BarChartRodData(toY: slip.net, color: colors.success, width: 8, borderRadius: BorderRadius.circular(3)),
                      ]),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt() - 1;
                          if (i < 0 || i > 11) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(monthNamesDe[i].substring(0, 3), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendDot(AppleColors.gray, 'Brutto'),
                const SizedBox(width: 16),
                _legendDot(colors.success, 'Netto'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)), child: const SizedBox(width: 12, height: 12)),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _SalarySlipTile extends ConsumerWidget {
  const _SalarySlipTile({required this.slip});

  final SalarySlip slip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(monthYearFormat.format(slip.period)),
      subtitle: Text(
        'Brutto ${currencyFormat.format(slip.gross)} · Steuern ${currencyFormat.format(slip.incomeTax)} · '
        'SV ${currencyFormat.format(slip.socialSecurity)}${slip.employer != null ? ' · ${slip.employer}' : ''}',
      ),
      trailing: Text(
        currencyFormat.format(slip.net),
        style: TextStyle(color: context.appleColors.success, fontWeight: FontWeight.bold),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SalarySlipFormScreen(existing: slip)),
      ),
    );
  }
}
