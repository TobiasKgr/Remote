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

const _amount = r'\d{1,3}(?:\.\d{3})*,\d{2}';

/// Marks the start of a transaction row: a "dd.mm" date - some statements
/// print a trailing "." after the month, some don't - directly followed by
/// a two-letter weekday code (MO/DI/.../SO). Scanned across the *entire*
/// text rather than line by line, because not every TARGOBANK export
/// preserves line breaks between rows: regular monthly statements do, but
/// quarterly "Rechnungsabschluss" statements (the closing days of March/
/// June/September/December) have been observed to flatten a whole page
/// into one line with no internal breaks at all. Anchoring on this marker
/// instead means the parser doesn't care either way.
final _rowStart = RegExp(r'(\d{2})\.(\d{2})\.?[A-ZÄÖÜ]{2}');

final _saldoAmountFirst = RegExp(r'^(' + _amount + r')(\s?-)?(ANFANGSSALDO|ENDSALDO)', dotAll: true);
final _saldoLabelFirst = RegExp(r'^(ANFANGSSALDO|ENDSALDO)(' + _amount + r')(\s?-)?', dotAll: true);
// Regular monthly statements put the amount+balance right after the
// weekday code, ahead of the description; quarterly closing statements
// instead put them at the very end of the row, after the description.
final _txnAmountFirst = RegExp(r'^(' + _amount + r')(' + _amount + r')(\s?-)?(.+)$', dotAll: true);
final _txnAmountLast = RegExp(r'^(.+?)(' + _amount + r')(' + _amount + r')(\s?-)?$', dotAll: true);

double _parseAmount(String raw) => double.parse(raw.replaceAll('.', '').replaceAll(',', '.'));

/// Parses the "Monatsübersicht" transaction tables of a TARGOBANK
/// "Finanzstatus" PDF.
///
/// Unlike a normal Kontoauszug, each row prints a running account balance
/// instead of a signed transaction amount, and once the PDF's columns are
/// flattened into plain text the transaction amount and the balance end
/// up directly concatenated with no separator between them. There is no
/// reliable per-row marker for Ausgabe vs. Einnahme, so the sign of every
/// booking is derived from the change in balance between consecutive rows
/// instead - which also naturally skips non-final rows like pending card
/// holds ("RESERV. BETRAG POS") or overdraft notices ("HINWEIS..."),
/// since those only ever carry a single stray amount (the hold amount,
/// buried inside descriptive text) rather than two amounts immediately
/// adjacent to each other.
List<ParsedTransaction> parseTargobankFinanzstatus(String text) {
  final periodMatch = RegExp(r'vom\s+(\d{2})\.(\d{2})\.(\d{4})\s*-\s*(\d{2})\.(\d{2})\.(\d{4})').firstMatch(text);
  final endMonth = periodMatch != null ? int.parse(periodMatch.group(4)!) : DateTime.now().month;
  final endYear = periodMatch != null ? int.parse(periodMatch.group(6)!) : DateTime.now().year;

  // A row's date has no year of its own; a statement can carry over a
  // single day from the previous year (the opening balance is dated the
  // last day of the prior month), so any month later than the statement's
  // own end month must belong to the year before it.
  int yearFor(int month) => month > endMonth ? endYear - 1 : endYear;

  final rowStarts = _rowStart.allMatches(text).toList();
  final results = <ParsedTransaction>[];
  double? previousBalance;

  for (var i = 0; i < rowStarts.length; i++) {
    final start = rowStarts[i];
    final bodyEnd = i + 1 < rowStarts.length ? rowStarts[i + 1].start : text.length;
    if (bodyEnd <= start.end) continue;
    final body = text.substring(start.end, bodyEnd).trim();
    if (body.isEmpty) continue;

    final saldoAmountFirst = _saldoAmountFirst.firstMatch(body);
    if (saldoAmountFirst != null) {
      final magnitude = _parseAmount(saldoAmountFirst.group(1)!);
      previousBalance = saldoAmountFirst.group(2) != null ? -magnitude : magnitude;
      continue;
    }
    final saldoLabelFirst = _saldoLabelFirst.firstMatch(body);
    if (saldoLabelFirst != null) {
      final magnitude = _parseAmount(saldoLabelFirst.group(2)!);
      previousBalance = saldoLabelFirst.group(3) != null ? -magnitude : magnitude;
      continue;
    }
    if (previousBalance == null) continue;

    final amountFirst = _txnAmountFirst.firstMatch(body);
    final amountLast = amountFirst == null ? _txnAmountLast.firstMatch(body) : null;
    if (amountFirst == null && amountLast == null) continue;

    final String balanceStr, description;
    final String? negMarker;
    if (amountFirst != null) {
      balanceStr = amountFirst.group(2)!;
      negMarker = amountFirst.group(3);
      description = amountFirst.group(4)!.trim();
    } else {
      description = amountLast!.group(1)!.trim();
      balanceStr = amountLast.group(3)!;
      negMarker = amountLast.group(4);
    }

    final newBalance = negMarker != null ? -_parseAmount(balanceStr) : _parseAmount(balanceStr);
    final delta = newBalance - previousBalance;
    previousBalance = newBalance;
    if (delta.abs() < 0.005) continue;

    results.add(ParsedTransaction(
      date: DateTime(yearFor(int.parse(start.group(2)!)), int.parse(start.group(2)!), int.parse(start.group(1)!)),
      description: description,
      amount: delta,
    ));
  }

  return results;
}
