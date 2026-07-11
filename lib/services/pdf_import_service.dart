import 'dart:typed_data';

import 'pdf_text_extractor.dart';

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
