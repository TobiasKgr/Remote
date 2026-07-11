import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/salary_slip.dart';
import '../providers/salary_slip_providers.dart';
import '../providers/transaction_providers.dart';
import '../services/salary_slip_parser_service.dart';
import '../utils/formatters.dart';
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SalarySlipFormScreen(prefill: parsed)),
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
        title: const Text('Gehalt'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => ref.read(selectedYearProvider.notifier).state = year - 1),
          Center(child: Text('$year', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => ref.read(selectedYearProvider.notifier).state = year + 1),
        ],
      ),
      body: SafeArea(
        child: _importing
            ? const Center(child: CircularProgressIndicator())
            : slips.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Keine Gehaltsabrechnungen für $year erfasst.', textAlign: TextAlign.center),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _BreakdownChart(slips: slips),
                      const SizedBox(height: 16),
                      for (final slip in slips) _SalarySlipTile(slip: slip),
                    ],
                  ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'salary_pdf',
            onPressed: _importPdf,
            icon: const Icon(Icons.upload_file),
            label: const Text('PDF importieren'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'salary_manual',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalarySlipFormScreen())),
            icon: const Icon(Icons.add),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brutto vs. Netto pro Monat', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY == 0 ? 1 : maxY * 1.2,
                  barGroups: [
                    for (final slip in slips)
                      BarChartGroupData(x: slip.period.month, barRods: [
                        BarChartRodData(toY: slip.gross, color: Colors.blueGrey, width: 8),
                        BarChartRodData(toY: slip.net, color: Colors.green, width: 8),
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
                _legendDot(Colors.blueGrey, 'Brutto'),
                const SizedBox(width: 16),
                _legendDot(Colors.green, 'Netto'),
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
        Container(width: 12, height: 12, color: color),
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
    return Card(
      child: ListTile(
        title: Text(monthYearFormat.format(slip.period)),
        subtitle: Text(
          'Brutto ${currencyFormat.format(slip.gross)} · Steuern ${currencyFormat.format(slip.incomeTax)} · '
          'SV ${currencyFormat.format(slip.socialSecurity)}${slip.employer != null ? ' · ${slip.employer}' : ''}',
        ),
        trailing: Text(
          currencyFormat.format(slip.net),
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SalarySlipFormScreen(existing: slip)),
        ),
      ),
    );
  }
}
