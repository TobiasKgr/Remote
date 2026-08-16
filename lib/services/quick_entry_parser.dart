/// Result of parsing one free-text quick-entry line, e.g.
/// "50€ Rewe gestern" or "+120 Erstattung 15.03.".
class QuickEntryDraft {
  const QuickEntryDraft({required this.amount, required this.isIncome, required this.date, required this.description});

  /// Always positive - [isIncome] carries the sign.
  final double amount;
  final bool isIncome;
  final DateTime date;

  /// What's left of the input after the amount and date tokens were
  /// stripped out. Falls back to a placeholder when nothing remains.
  final String description;
}

final _amountPattern = RegExp(r'([+-])?\s*(\d+(?:[.,]\d{1,2})?)\s*(?:€|eur)?', caseSensitive: false);
final _explicitDatePattern = RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{4})?');

const _relativeDateKeywords = {
  'heute': 0,
  'gestern': -1,
  'vorgestern': -2,
};

/// Parses a single free-text booking entry ("Schnelleingabe") into a
/// [QuickEntryDraft], or null when no amount could be found at all - an
/// amount is the one thing every booking needs, everything else falls back
/// to a sensible default. Deliberately simple (no NLP/locale library): a
/// handful of regexes for amount/date, keyword lookup for relative dates,
/// whatever text remains becomes the description.
QuickEntryDraft? parseQuickEntry(String input, {DateTime? referenceDate}) {
  final today = referenceDate ?? DateTime.now();
  var remaining = input;
  var date = DateTime(today.year, today.month, today.day);

  var dateMatched = false;
  for (final entry in _relativeDateKeywords.entries) {
    final regex = RegExp('\\b${entry.key}\\b', caseSensitive: false);
    final match = regex.firstMatch(remaining);
    if (match != null) {
      date = date.add(Duration(days: entry.value));
      remaining = remaining.replaceRange(match.start, match.end, ' ');
      dateMatched = true;
      break;
    }
  }

  if (!dateMatched) {
    final match = _explicitDatePattern.firstMatch(remaining);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = match.group(3) != null ? int.parse(match.group(3)!) : today.year;
      if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        date = DateTime(year, month, day);
        remaining = remaining.replaceRange(match.start, match.end, ' ');
      }
    }
  }

  final amountMatch = _amountPattern.firstMatch(remaining);
  if (amountMatch == null) return null;

  final amount = double.parse(amountMatch.group(2)!.replaceAll(',', '.'));
  final isIncome = amountMatch.group(1) == '+';
  remaining = remaining.replaceRange(amountMatch.start, amountMatch.end, ' ');

  final description = remaining.replaceAll(RegExp(r'\s+'), ' ').trim();

  return QuickEntryDraft(amount: amount, isIncome: isIncome, date: date, description: description.isEmpty ? 'Buchung' : description);
}
