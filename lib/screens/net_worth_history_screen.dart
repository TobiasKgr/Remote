import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/cash_flow_projection_providers.dart';
import '../providers/net_worth_history_providers.dart';
import '../services/cash_flow_projection_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/apple_widgets.dart';
import '../widgets/person_filter_bar.dart';

const _monthAbbreviations = ['Jan', 'Feb', 'Mrz', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];

/// Line chart of net worth (tracked account balances, reconstructed from
/// each account's starting balance plus its transactions up to each
/// month-end, plus the current static assets/liabilities total as a
/// constant offset - see computeNetWorthHistory) over time. Months with no
/// booking anywhere ("keine Daten") are drawn as hollow points instead of
/// filled ones, since the carried-forward value isn't confirmed by an
/// import for that specific month.
class NetWorthHistoryScreen extends ConsumerWidget {
  const NetWorthHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(netWorthHistoryProvider);
    final projection = ref.watch(cashFlowProjectionProvider);
    final colors = context.appleColors;

    final negativePoints = projection.where((p) => p.balance < 0);
    final negativeFrom = negativePoints.isEmpty ? null : negativePoints.first;

    return Scaffold(
      appBar: AppBar(title: const SizedBox.shrink()),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const AppleLargeTitle('Vermögensentwicklung'),
            const PersonFilterBar(),
            if (points.length < 2)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Noch nicht genug Buchungsverlauf für einen Verlauf. Sobald ein Konto über mindestens '
                  'zwei verschiedene Monate hinweg Buchungen hat, erscheint hier die Entwicklung.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.secondaryLabel),
                ),
              )
            else ...[
              AppleHeroCard(
                label: 'Aktuell',
                value: currencyFormat.format(points.last.netWorth),
                subtitle: '${_monthAbbreviations[points.first.month.month - 1]} ${points.first.month.year} - '
                    '${_monthAbbreviations[points.last.month.month - 1]} ${points.last.month.year}',
              ),
              AppleCard(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
                  child: _Chart(points: points, projection: projection),
                ),
              ),
              if (projection.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Container(width: 12, height: 2, color: colors.secondaryLabel),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gestrichelt: Prognose der nächsten 8 Wochen anhand erkannter Abos/Verträge - keine '
                          'Vorhersage sonstiger Ausgaben.',
                          style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (negativeFrom != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: colors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle_fill, color: colors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bei gleichbleibenden Abos/Verträgen rutscht der Kontostand um den '
                            '${dateFormat.format(negativeFrom.date)} voraussichtlich ins Minus.',
                            style: TextStyle(color: colors.danger, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (points.any((p) => !p.hasData))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.circle, size: 12, color: colors.secondaryLabel),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ungefüllte Punkte: keine Buchung in diesem Monat gefunden - Wert vom Vormonat übernommen.',
                          style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Enthält alle Konten (Startsaldo + Buchungen) über die Zeit sowie den aktuellen Stand deiner '
                  'manuell erfassten Vermögenswerte/Kredite - für diese gibt es keinen Verlauf, sie fließen mit '
                  'ihrem heutigen Wert über den ganzen Zeitraum ein.',
                  style: TextStyle(color: colors.secondaryLabel, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared x-axis for both series: days since [points].first's month, so the
/// (irregularly spaced, daily) projection can continue seamlessly from the
/// (regularly spaced, monthly) history on one chart.
class _Chart extends StatelessWidget {
  const _Chart({required this.points, required this.projection});

  final List<NetWorthPoint> points;
  final List<CashFlowProjectionPoint> projection;

  @override
  Widget build(BuildContext context) {
    final colors = context.appleColors;
    final accent = AppleColors.blue;
    final projectionAccent = AppleColors.indigo;
    final origin = points.first.month;
    double xFor(DateTime d) => d.difference(origin).inDays.toDouble();

    final historySpots = [for (final p in points) FlSpot(xFor(p.month), p.netWorth)];
    final projectionSpots = [
      FlSpot(xFor(points.last.month), points.last.netWorth),
      for (final p in projection) FlSpot(xFor(p.date), p.balance),
    ];

    final allValues = [...points.map((p) => p.netWorth), ...projection.map((p) => p.balance)];
    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final padding = ((maxY - minY).abs() * 0.15).clamp(10, double.infinity);
    final labelEvery = (points.length / 6).ceil().clamp(1, points.length);
    final monthLabels = {
      for (var i = 0; i < points.length; i += labelEvery)
        xFor(points[i].month).round(): '${_monthAbbreviations[points[i].month.month - 1]} ${points[i].month.year % 100}',
    };

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final label = monthLabels[value.round()];
                  if (label == null) return const SizedBox.shrink();
                  return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: const TextStyle(fontSize: 10)));
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) {
                final date = origin.add(Duration(days: s.x.round()));
                final isProjection = s.barIndex == 1;
                return LineTooltipItem(
                  '${isProjection ? "Prognose " : ""}${_monthAbbreviations[date.month - 1]} ${date.year}\n${currencyFormat.format(s.y)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: historySpots,
              isCurved: true,
              curveSmoothness: 0.15,
              color: accent,
              barWidth: 2.5,
              dotData: FlDotData(
                getDotPainter: (spot, percent, bar, index) {
                  final hasData = points[index].hasData;
                  return FlDotCirclePainter(
                    radius: 3,
                    color: hasData ? accent : colors.groupedBackground,
                    strokeWidth: hasData ? 0 : 1.5,
                    strokeColor: accent,
                  );
                },
              ),
              belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.12)),
            ),
            if (projectionSpots.length > 1)
              LineChartBarData(
                spots: projectionSpots,
                isCurved: false,
                color: projectionAccent,
                barWidth: 2.5,
                dashArray: const [6, 4],
                dotData: const FlDotData(show: false),
              ),
          ],
        ),
      ),
    );
  }
}
