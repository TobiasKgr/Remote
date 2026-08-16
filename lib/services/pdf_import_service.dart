import 'dart:typed_data';

import '../models/custom_import_profile.dart';
import 'custom_format_parser.dart';
import 'pdf_text_extractor.dart';
import 'targobank_finanzstatus_parser.dart';

/// One line item parsed out of a bank statement PDF, still awaiting user
/// confirmation before it becomes a real [Transaction].
class ParsedTransaction {
  ParsedTransaction({
    required this.date,
    required this.description,
    required this.amount,
    this.amountAmbiguous = false,
  });

  final DateTime date;
  final String description;
  final double amount;

  /// True when the statement line had no explicit +/-/S/H sign marker, so
  /// the parser guessed the sign and the user should double check it.
  final bool amountAmbiguous;
}

/// Result of parsing one statement PDF, plus its opening/closing balance
/// when the layout carries one (currently only the TARGOBANK Finanzstatus
/// parser does) - lets a caller sanity-check that "Anfangssaldo + Summe der
/// Buchungen = Endsaldo" instead of silently trusting whatever the
/// heuristic parser happened to recognize.
class PdfImportResult {
  const PdfImportResult({required this.transactions, this.openingBalance, this.closingBalance});

  final List<ParsedTransaction> transactions;
  final double? openingBalance;
  final double? closingBalance;

  double get bookedTotal => transactions.fold<double>(0, (sum, t) => sum + t.amount);

  /// Null when the statement's layout doesn't carry balance markers at all
  /// (nothing to check against, not an error).
  double? get expectedTotal => (openingBalance != null && closingBalance != null) ? closingBalance! - openingBalance! : null;

  /// Signed difference between what was actually booked and what the
  /// statement's own balances imply should have been booked; null when
  /// [expectedTotal] can't be computed.
  double? get balanceDifference {
    final expected = expectedTotal;
    return expected == null ? null : bookedTotal - expected;
  }

  /// True when the difference exceeds a small rounding tolerance - a sign
  /// that some booking was missed or misparsed. Doesn't necessarily mean
  /// the import is wrong; it means it should be double-checked.
  bool get hasBalanceMismatch {
    final diff = balanceDifference;
    return diff != null && diff.abs() > 0.01;
  }
}

/// Extracts raw text from PDF bank statements and parses it into
/// transaction candidates.
///
/// Bank statement PDFs are not standardized between institutions, so this
/// is a best-effort heuristic parser tuned for common German "Kontoauszug"
/// layouts (a booking date at the start of a line, an amount with a German
/// decimal comma at the end, optionally followed by a Soll/Haben marker).
/// Results should always be reviewed by the user before saving - see the
/// import review screen.
class PdfImportService {
  static final _dateRegex = RegExp(r'^(\d{2}\.\d{2}\.\d{4})\b');
  static final _amountRegex = RegExp(r'([+-]?\d{1,3}(?:\.\d{3})*,\d{2})\s*(S|H)?\s*$');

  Future<String> extractText(Uint8List bytes) => extractPdfText(bytes);

  List<ParsedTransaction> parse(String text) {
    if (looksLikeTargobankFinanzstatus(text)) {
      final parsed = parseTargobankFinanzstatus(text);
      // Fallback: a document can still be correctly detected as a
      // TARGOBANK Finanzstatus while using some row layout the dedicated
      // parser doesn't recognize yet (as happened with the quarterly
      // "Rechnungsabschluss" layout). Rather than surfacing zero rows,
      // fall back to the generic line-based heuristic - it won't
      // understand the balance-column format, but it has still picked up
      // real bookings on genuine Kontoauszug-style lines in the past.
      if (parsed.isNotEmpty) return parsed;
      return _parseGenericStatement(text);
    }
    return _parseGenericStatement(text);
  }

  List<ParsedTransaction> _parseGenericStatement(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final results = <ParsedTransaction>[];
    DateTime? currentDate;
    StringBuffer? currentDesc;
    double? currentAmount;
    bool currentAmbiguous = false;

    void flush() {
      if (currentDate != null && currentAmount != null && currentDesc != null) {
        results.add(ParsedTransaction(
          date: currentDate!,
          description: _cleanDescription(currentDesc.toString()),
          amount: currentAmount!,
          amountAmbiguous: currentAmbiguous,
        ));
      }
      currentDate = null;
      currentDesc = null;
      currentAmount = null;
      currentAmbiguous = false;
    }

    for (final line in lines) {
      final dateMatch = _dateRegex.firstMatch(line);

      if (dateMatch != null) {
        // A new date at the start of a line begins a new transaction candidate.
        flush();
        currentDate = _parseGermanDate(dateMatch.group(1)!);
        final rest = line.substring(dateMatch.end);
        final amountMatch = _amountRegex.firstMatch(rest);
        if (amountMatch != null) {
          final parsed = _parseAmount(amountMatch);
          currentAmount = parsed.$1;
          currentAmbiguous = parsed.$2;
          currentDesc = StringBuffer(rest.substring(0, amountMatch.start));
        } else {
          currentDesc = StringBuffer(rest);
        }
      } else if (currentDate != null) {
        if (currentAmount == null) {
          final amountMatch = _amountRegex.firstMatch(line);
          if (amountMatch != null) {
            final parsed = _parseAmount(amountMatch);
            currentAmount = parsed.$1;
            currentAmbiguous = parsed.$2;
            final withoutAmount = line.substring(0, amountMatch.start).trim();
            if (withoutAmount.isNotEmpty) currentDesc!.write(' $withoutAmount');
            continue;
          }
        }
        currentDesc!.write(' $line');
      }
    }
    flush();
    return results;
  }

  Future<List<ParsedTransaction>> importFromBytes(Uint8List bytes) async {
    final text = await extractText(bytes);
    return parse(text);
  }

  /// Like [importFromBytes], but also returns the opening/closing balance
  /// when the statement's layout carries one, so the caller can flag a
  /// mismatch between "Anfangssaldo + Buchungen" and "Endsaldo" instead of
  /// silently trusting the parse. [customProfiles] (from "Format anlernen",
  /// see [FormatAssistantScreen]) are only tried as a last resort, when
  /// neither the bank-specific nor the generic parser recognized anything -
  /// among profiles that find something, the one with the most matches wins.
  Future<PdfImportResult> importFromBytesWithBalanceCheck(Uint8List bytes, {List<CustomImportProfile> customProfiles = const []}) async {
    final text = await extractText(bytes);

    if (looksLikeTargobankFinanzstatus(text)) {
      final detailed = parseTargobankFinanzstatusDetailed(text);
      if (detailed.transactions.isNotEmpty) {
        return PdfImportResult(
          transactions: detailed.transactions,
          openingBalance: detailed.openingBalanceSum,
          closingBalance: detailed.closingBalanceSum,
        );
      }
      // Same fallback as parse(): an unrecognized row layout within an
      // otherwise-detected Finanzstatus falls back to the generic parser,
      // which has no balance markers to check against.
    }

    final generic = _parseGenericStatement(text);
    if (generic.isNotEmpty || customProfiles.isEmpty) {
      return PdfImportResult(transactions: generic);
    }

    var best = <ParsedTransaction>[];
    for (final profile in customProfiles) {
      final result = parseWithCustomProfile(text, profile);
      if (result.length > best.length) best = result;
    }
    return PdfImportResult(transactions: best);
  }

  String _cleanDescription(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime _parseGermanDate(String value) {
    final parts = value.split('.');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }

  /// Returns (signedAmount, wasAmbiguous).
  (double, bool) _parseAmount(RegExpMatch match) {
    final numberPart = match.group(1)!;
    final soHaMarker = match.group(2);

    final hasExplicitSign = numberPart.startsWith('-') || numberPart.startsWith('+');
    final normalized = numberPart.replaceAll('.', '').replaceAll(',', '.');
    final magnitude = double.parse(normalized.replaceAll('+', ''));

    if (hasExplicitSign) {
      return (magnitude, false);
    }
    if (soHaMarker == 'S') {
      return (-magnitude.abs(), false);
    }
    if (soHaMarker == 'H') {
      return (magnitude.abs(), false);
    }
    // No sign indicator at all: guess "expense" (the vast majority of
    // statement lines) but flag it for user review.
    return (-magnitude.abs(), true);
  }
}
