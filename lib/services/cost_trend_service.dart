import '../models/category.dart';
import '../models/transaction.dart';
import 'cash_flow_projection_service.dart';
import 'recurring_payment_detector.dart';
import '../utils/description_normalizer.dart';

/// Direction of a [CostTrendRow]'s recent month-over-month development.
enum CostTrendDirection { rising, falling, stable }

extension CostTrendDirectionLabel on CostTrendDirection {
  String get label => switch (this) {
        CostTrendDirection.rising => 'Steigend',
        CostTrendDirection.falling => 'Fallend',
        CostTrendDirection.stable => 'Stabil',
      };
}

/// One row of the "Kostentrends" overview: either a detected recurring
/// payment series (Abo/Vertrag) or a category whose spending shows a
/// consistent month-to-month pattern, pivoted into one amount per calendar
/// month of the selected year.
class CostTrendRow {
  const CostTrendRow({
    required this.label,
    required this.categoryColorValue,
    required this.isRecurringSeries,
    required this.monthlyAmounts,
    required this.forecastAmounts,
    this.direction,
    this.relativeMonthlyChange,
    this.rhythm,
  });

  final String label;
  final int categoryColorValue;

  /// True for a detected recurring payment (fixed rhythm/amount, e.g. a
  /// subscription); false for a category-level trend row (varying bookings
  /// that still show up regularly, e.g. groceries).
  final bool isRecurringSeries;

  /// Index 0 = January ... 11 = December. Positive magnitudes, zero where
  /// nothing was actually booked yet.
  final List<double> monthlyAmounts;

  /// Projected amounts for months with no actual booking yet - filled from
  /// the detected rhythm for recurring rows, or from a linear trend
  /// extrapolation for category-trend rows. Zero wherever [monthlyAmounts]
  /// already has a real value, so a real booking always wins.
  final List<double> forecastAmounts;

  /// Only set for category-trend rows (null for recurring series, whose
  /// "predictability" is the fixed rhythm itself, not a rising/falling trend).
  final CostTrendDirection? direction;

  /// Average relative change per month over the trend window, e.g. 0.05 =
  /// +5%/Monat. Only set for category-trend rows.
  final double? relativeMonthlyChange;

  /// Only set for recurring series.
  final RecurrenceRhythm? rhythm;

  List<double> get combinedAmounts => [for (var i = 0; i < 12; i++) monthlyAmounts[i] != 0 ? monthlyAmounts[i] : forecastAmounts[i]];

  double get yearTotal => combinedAmounts.fold<double>(0, (s, v) => s + v);
}

class CostTrendData {
  const CostTrendData({required this.recurringRows, required this.trendRows});

  final List<CostTrendRow> recurringRows;
  final List<CostTrendRow> trendRows;

  List<double> get monthlyRecurringTotals => _monthlyTotals(recurringRows);
  List<double> get monthlyTrendTotals => _monthlyTotals(trendRows);
  List<double> get monthlyCombinedTotals => [for (var i = 0; i < 12; i++) monthlyRecurringTotals[i] + monthlyTrendTotals[i]];

  double get yearRecurringTotal => monthlyRecurringTotals.fold<double>(0, (s, v) => s + v);
  double get yearTrendTotal => monthlyTrendTotals.fold<double>(0, (s, v) => s + v);

  static List<double> _monthlyTotals(List<CostTrendRow> rows) {
    final totals = List<double>.filled(12, 0);
    for (final row in rows) {
      final combined = row.combinedAmounts;
      for (var i = 0; i < 12; i++) {
        totals[i] += combined[i];
      }
    }
    return totals;
  }
}

/// A category needs bookings in at least this share of the trend window's
/// months to count as "shows a similar tendency" rather than one-off/sporadic.
const _trendPresenceThreshold = 0.6;

/// Minimum absolute average month-over-month change (relative to the
/// window's average spend) for a category to be labelled rising/falling
/// instead of stable.
const _trendSignificantSlope = 0.03;

/// How far a trend forecast is allowed to stray from the window average, so
/// a steep short-term slope can't extrapolate into an implausible number.
const _trendForecastCap = 3.0;

/// Pure function (no Riverpod dependency): builds the "Kostentrends" year
/// overview - every detected recurring payment (see [RecurringPaymentDetector])
/// plus every expense category whose recent spending shows a consistent
/// month-to-month pattern, each pivoted into [year]'s 12 months with a
/// forecast filled in wherever a month has no actual booking yet.
///
/// [allTransactions] should be the full, all-time booking history (not
/// limited to [year]) - recurring detection and trend detection both look
/// back further than a single calendar year. [recurringGroups] is expected
/// to already be filtered/detected from the same [allTransactions] (see
/// [recurringPaymentsProvider]) so this function doesn't redo that work.
CostTrendData computeCostTrends({
  required List<Transaction> allTransactions,
  required List<Category> categories,
  required List<RecurringPaymentGroup> recurringGroups,
  required int year,
  DateTime? referenceDate,
  int trendWindowMonths = 6,
}) {
  final reference = referenceDate ?? DateTime.now();
  final forecastFloor = DateTime(reference.year, reference.month);
  final categoryById = {for (final c in categories) c.id: c};

  final relevant = allTransactions.where((t) => !t.isTransfer && !t.isIncome).toList();

  // --- Recurring series rows -------------------------------------------
  final expenseRecurring = recurringGroups.where((g) => g.latestAmount < 0).toList();
  final recurringDescriptionKeys = expenseRecurring.map((g) => normalizeDescription(g.description)).toSet();

  List<double> projectRecurringForecast(RecurringPaymentGroup group, List<double> actual) {
    final forecast = List<double>.filled(12, 0);
    var occurrence = group.lastDate;
    while (true) {
      occurrence = nextOccurrence(occurrence, group.rhythm);
      if (occurrence.year > year) break;
      if (occurrence.year == year) {
        final monthIndex = occurrence.month - 1;
        if (actual[monthIndex] == 0 && !DateTime(occurrence.year, occurrence.month).isBefore(forecastFloor)) {
          forecast[monthIndex] += group.latestAmount.abs();
        }
      }
    }
    return forecast;
  }

  final recurringRows = <CostTrendRow>[];
  for (final group in expenseRecurring) {
    final monthly = List<double>.filled(12, 0);
    for (final t in group.transactions) {
      if (t.date.year == year) monthly[t.date.month - 1] += t.amount.abs();
    }
    final forecast = projectRecurringForecast(group, monthly);
    if (monthly.every((v) => v == 0) && forecast.every((v) => v == 0)) continue;

    recurringRows.add(CostTrendRow(
      label: group.description,
      categoryColorValue: (categoryById[group.latest.categoryId] ?? _fallbackCategory).colorValue,
      isRecurringSeries: true,
      monthlyAmounts: List.unmodifiable(monthly),
      forecastAmounts: List.unmodifiable(forecast),
      rhythm: group.rhythm,
    ));
  }
  recurringRows.sort((a, b) => b.yearTotal.compareTo(a.yearTotal));

  // --- Category trend rows ----------------------------------------------
  // Transactions already represented by a recurring row are excluded here,
  // so e.g. a Netflix booking doesn't also inflate its category's "trend".
  final trendCandidates = relevant.where((t) => !recurringDescriptionKeys.contains(normalizeDescription(t.description)));

  final byCategory = <String, List<Transaction>>{};
  for (final t in trendCandidates) {
    byCategory.putIfAbsent(t.categoryId, () => []).add(t);
  }

  int monthsBetween(DateTime a, DateTime b) => (a.year - b.year) * 12 + (a.month - b.month);

  final trendRows = <CostTrendRow>[];
  for (final entry in byCategory.entries) {
    final txs = entry.value;

    // Trailing window of `trendWindowMonths` months ending at the reference
    // month (index 0 = oldest, last index = reference month).
    final window = List<double>.filled(trendWindowMonths, 0);
    for (final t in txs) {
      final monthsAgo = monthsBetween(DateTime(reference.year, reference.month), DateTime(t.date.year, t.date.month));
      final index = trendWindowMonths - 1 - monthsAgo;
      if (index >= 0 && index < trendWindowMonths) window[index] += t.amount.abs();
    }

    final presentMonths = window.where((v) => v != 0).length;
    if (presentMonths / trendWindowMonths < _trendPresenceThreshold) continue;

    final average = window.fold<double>(0, (s, v) => s + v) / trendWindowMonths;
    if (average <= 0) continue;

    final slope = _linearRegressionSlope(window);
    final relativeSlope = slope / average;
    final direction = relativeSlope >= _trendSignificantSlope
        ? CostTrendDirection.rising
        : relativeSlope <= -_trendSignificantSlope
            ? CostTrendDirection.falling
            : CostTrendDirection.stable;

    // Pivot this category's actual bookings into the selected year.
    final monthly = List<double>.filled(12, 0);
    for (final t in txs) {
      if (t.date.year == year) monthly[t.date.month - 1] += t.amount.abs();
    }

    // Extrapolate the trend forward for any remaining, still-empty month of
    // the selected year, capped so a steep slope can't run away.
    final forecast = List<double>.filled(12, 0);
    for (var m = 0; m < 12; m++) {
      final monthDate = DateTime(year, m + 1);
      if (monthly[m] != 0 || monthDate.isBefore(forecastFloor)) continue;
      final stepsAhead = monthsBetween(monthDate, DateTime(reference.year, reference.month));
      final projected = average + slope * (trendWindowMonths - 1 + stepsAhead);
      forecast[m] = projected.clamp(0, average * _trendForecastCap);
    }
    if (monthly.every((v) => v == 0) && forecast.every((v) => v == 0)) continue;

    final category = categoryById[entry.key] ?? _fallbackCategory;
    trendRows.add(CostTrendRow(
      label: category.name,
      categoryColorValue: category.colorValue,
      isRecurringSeries: false,
      monthlyAmounts: List.unmodifiable(monthly),
      forecastAmounts: List.unmodifiable(forecast),
      direction: direction,
      relativeMonthlyChange: relativeSlope,
    ));
  }
  trendRows.sort((a, b) => b.yearTotal.compareTo(a.yearTotal));

  return CostTrendData(recurringRows: recurringRows, trendRows: trendRows);
}

/// Simple least-squares slope of `values` against their index (0, 1, 2, ...).
double _linearRegressionSlope(List<double> values) {
  final n = values.length;
  if (n < 2) return 0;
  final meanX = (n - 1) / 2;
  final meanY = values.fold<double>(0, (s, v) => s + v) / n;

  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < n; i++) {
    final dx = i - meanX;
    numerator += dx * (values[i] - meanY);
    denominator += dx * dx;
  }
  return denominator == 0 ? 0 : numerator / denominator;
}

final _fallbackCategory = Category(id: '_unknown', name: 'Unbekannt', type: CategoryType.expense, colorValue: 0xFF9E9E9E);
