import 'pdf_import_service.dart' show ParsedTransaction;

/// True when [text] looks like a TARGOBANK "Finanzstatus" - a combined
/// multi-account overview plus a monthly "Monatsübersicht" statement per
/// account, quite different in layout from a plain single-account
/// Kontoauszug (see [parseTargobankFinanzstatus] for why it needs its own
/// parser).
bool looksLikeTargobankFinanzstatus(String text) {
  return text.contains('TARGOBANK') &&
      text.contains('Finanzstatus') &&
      text.contains('Transaktionen') &&
      text.contains('Guthaben/Kredit');
}

/// Parses the "Monatsübersicht" transaction tables of a TARGOBANK
/// "Finanzstatus" PDF.
///
/// Unlike a normal Kontoauszug, each row prints a running account balance
/// instead of a signed transaction amount, and once the PDF's columns are
/// flattened into plain text the transaction amount and the balance end
/// up concatenated on the same line with no separator between them (e.g.
/// "1.020,00209,68 -AUSFÜHRUNGDAUERAUFTRAG..."). There is no reliable
/// per-line marker for Ausgabe vs. Einnahme, so the sign of every booking
/// is derived from the change in balance between consecutive rows
/// instead - which also naturally skips non-final rows like pending card
/// holds ("RESERV.BETRAGPOS") or overdraft notices ("HINWEIS..."), since
/// those only ever carry a single number and never match the two-number
/// row pattern below.
List<ParsedTransaction> parseTargobankFinanzstatus(String text) {
  final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  final periodMatch = RegExp(r'vom\s+(\d{2})\.(\d{2})\.(\d{4})\s*-\s*(\d{2})\.(\d{2})\.(\d{4})').firstMatch(text);
  final endMonth = periodMatch != null ? int.parse(periodMatch.group(4)!) : DateTime.now().month;
  final endYear = periodMatch != null ? int.parse(periodMatch.group(6)!) : DateTime.now().year;

  final saldoRegex = RegExp(r'^(\d{2})\.(\d{2})[A-ZÄÖÜ]{2}(\d{1,3}(?:\.\d{3})*,\d{2})(\s?-)?(ANFANGSSALDO|ENDSALDO)$');
  final transactionRegex =
      RegExp(r'^(\d{2})\.(\d{2})[A-ZÄÖÜ]{2}(\d{1,3}(?:\.\d{3})*,\d{2})(\d{1,3}(?:\.\d{3})*,\d{2})(\s?-)?(.+)$');

  // A transaction line's date has no year of its own; a statement can
  // carry over a single day from the previous year (the opening balance
  // is dated the last day of the prior month), so any month later than
  // the statement's own end month must belong to the year before it.
  int yearFor(int month) => month > endMonth ? endYear - 1 : endYear;
  double parseAmount(String raw) => double.parse(raw.replaceAll('.', '').replaceAll(',', '.'));

  final results = <ParsedTransaction>[];
  double? previousBalance;

  for (final line in lines) {
    final saldoMatch = saldoRegex.firstMatch(line);
    if (saldoMatch != null) {
      final magnitude = parseAmount(saldoMatch.group(3)!);
      previousBalance = saldoMatch.group(4) != null ? -magnitude : magnitude;
      continue;
    }

    final match = transactionRegex.firstMatch(line);
    if (match == null || previousBalance == null) continue;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final balanceMagnitude = parseAmount(match.group(4)!);
    final newBalance = match.group(5) != null ? -balanceMagnitude : balanceMagnitude;
    final description = match.group(6)!.trim();

    final delta = newBalance - previousBalance;
    previousBalance = newBalance;
    if (delta.abs() < 0.005) continue;

    results.add(ParsedTransaction(date: DateTime(yearFor(month), month, day), description: description, amount: delta));
  }

  return results;
}
