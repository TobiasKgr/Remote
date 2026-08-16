import '../models/transaction.dart';
import 'recurring_payment_detector.dart';

/// One projected day in the cash-flow forecast.
class CashFlowProjectionPoint {
  const CashFlowProjectionPoint({required this.date, required this.balance, this.eventDescription});

  final DateTime date;

  /// Projected total balance across all tracked accounts as of this date,
  /// assuming only currently-known recurring payments occur - not a
  /// prediction of one-off spending.
  final double balance;

  /// Set on days where a recurring payment is projected to book, e.g.
  /// "Netflix.com -12,99 €". Null on days between events (no change).
  final String? eventDescription;
}

/// Advances [from] by one occurrence of [rhythm]. Monthly/yearly steps clamp
/// the day-of-month to the target month's length (e.g. Jan 31 + monthly ->
/// Feb 28/29, not Mar 3).
DateTime nextOccurrence(DateTime from, RecurrenceRhythm rhythm) {
  switch (rhythm) {
    case RecurrenceRhythm.weekly:
      return from.add(const Duration(days: 7));
    case RecurrenceRhythm.monthly:
      return _addMonths(from, 1);
    case RecurrenceRhythm.yearly:
      return _addMonths(from, 12);
  }
}

DateTime _addMonths(DateTime from, int months) {
  final targetMonthIndex = from.month - 1 + months;
  final year = from.year + targetMonthIndex ~/ 12;
  final month = targetMonthIndex % 12 + 1;
  final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
  final day = from.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : from.day;
  return DateTime(year, month, day);
}

/// Pure function (no Riverpod dependency): projects the combined tracked-
/// account balance forward from [currentBalance] by rolling each detected
/// [RecurringPaymentGroup] forward from its last known booking, day by day,
/// for [daysAhead] days. Only known recurring payments are projected - no
/// attempt is made to forecast one-off/irregular spending, so this is a
/// floor-ish "what's already committed" view rather than a full prediction.
List<CashFlowProjectionPoint> computeCashFlowProjection({
  required double currentBalance,
  required List<RecurringPaymentGroup> recurringGroups,
  DateTime? referenceDate,
  int daysAhead = 56,
}) {
  final today = referenceDate ?? DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(Duration(days: daysAhead));

  final events = <DateTime, List<Transaction>>{};
  for (final group in recurringGroups) {
    var next = nextOccurrence(group.lastDate, group.rhythm);
    while (!next.isAfter(end)) {
      if (next.isAfter(start)) {
        final day = DateTime(next.year, next.month, next.day);
        events.putIfAbsent(day, () => []).add(group.latest);
      }
      next = nextOccurrence(next, group.rhythm);
    }
  }

  final points = <CashFlowProjectionPoint>[CashFlowProjectionPoint(date: start, balance: currentBalance)];
  var runningBalance = currentBalance;
  var day = start.add(const Duration(days: 1));
  while (!day.isAfter(end)) {
    final dayEvents = events[day];
    if (dayEvents == null || dayEvents.isEmpty) {
      day = day.add(const Duration(days: 1));
      continue;
    }
    for (final t in dayEvents) {
      runningBalance += t.amount;
      points.add(CashFlowProjectionPoint(date: day, balance: runningBalance, eventDescription: '${t.description} ${t.amount >= 0 ? '+' : ''}${t.amount.toStringAsFixed(2)} €'));
    }
    day = day.add(const Duration(days: 1));
  }

  return points;
}
