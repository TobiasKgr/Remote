import 'dart:typed_data';

import 'pdf_text_extractor.dart';

/// Best-effort extraction result for one "Gehaltsabrechnung" PDF. Any field
/// can be null/zero if it wasn't found - the review screen lets the user
/// fill in or correct every value before saving.
class SalarySlipParseResult {
  SalarySlipParseResult({
    this.period,
    this.gross,
    this.net,
    this.incomeTax = 0,
    this.socialSecurity = 0,
  });

  DateTime? period;
  double? gross;
  double? net;

  /// Sum of Lohnsteuer + Kirchensteuer + Solidaritätszuschlag lines found.
  double incomeTax;

  /// Sum of Kranken-/Renten-/Arbeitslosen-/Pflegeversicherung lines found.
  double socialSecurity;
}

/// Parses German "Gehaltsabrechnung" (salary slip) PDFs.
///
/// Like [PdfImportService], this is a heuristic: payroll software (DATEV,
/// SAP, Lexware, Personio, ...) all use different layouts. This parser
/// scans every line for known German payroll labels and takes the
/// German-formatted amount at the end of that line. Results must be
/// reviewed by the user before saving.
class SalarySlipParserService {
  static final _amountRegex = RegExp(r'(\d{1,3}(?:\.\d{3})*,\d{2})\s*[-+]?\s*$');
  static final _monthYearRegex = RegExp(r'\b(\d{2})[./](\d{4})\b');
  static final _germanMonthRegex = RegExp(
    r'(Januar|Februar|März|April|Mai|Juni|Juli|August|September|Oktober|November|Dezember)\s+(\d{4})',
    caseSensitive: false,
  );

  static const _germanMonthNames = [
    'januar',
    'februar',
    'märz',
    'april',
    'mai',
    'juni',
    'juli',
    'august',
    'september',
    'oktober',
    'november',
    'dezember',
  ];

  static const _grossKeywords = ['gesamt-brutto', 'gesamtbrutto', 'bruttoentgelt', 'gesamt-bezüge', 'gesamtbezüge'];
  static const _netKeywords = ['auszahlungsbetrag', 'nettoverdienst', 'gesamt-netto', 'gesamtnetto', 'überweisungsbetrag'];
  static const _incomeTaxKeywords = ['lohnsteuer', 'kirchensteuer', 'solidaritätszuschlag'];
  static const _socialSecurityKeywords = [
    'krankenversicherung',
    'rentenversicherung',
    'arbeitslosenversicherung',
    'pflegeversicherung',
  ];

  Future<String> extractText(Uint8List bytes) => extractPdfText(bytes);

  SalarySlipParseResult parse(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final result = SalarySlipParseResult();

    for (final line in lines) {
      final lower = line.toLowerCase();

      result.period ??= _tryParsePeriod(line);

      final amountMatch = _amountRegex.firstMatch(line);
      if (amountMatch == null) continue;
      final amount = _parseAmount(amountMatch.group(1)!);

      if (result.gross == null && _grossKeywords.any(lower.contains)) {
        result.gross = amount;
      } else if (result.net == null && _netKeywords.any(lower.contains)) {
        result.net = amount;
      } else if (_incomeTaxKeywords.any(lower.contains)) {
        result.incomeTax += amount;
      } else if (_socialSecurityKeywords.any(lower.contains)) {
        result.socialSecurity += amount;
      }
    }

    return result;
  }

  Future<SalarySlipParseResult> parseFromBytes(Uint8List bytes) async {
    final text = await extractText(bytes);
    return parse(text);
  }

  DateTime? _tryParsePeriod(String line) {
    final germanMonthMatch = _germanMonthRegex.firstMatch(line);
    if (germanMonthMatch != null) {
      final monthIndex = _germanMonthNames.indexOf(germanMonthMatch.group(1)!.toLowerCase()) + 1;
      final year = int.parse(germanMonthMatch.group(2)!);
      if (monthIndex > 0) return DateTime(year, monthIndex);
    }
    final monthYearMatch = _monthYearRegex.firstMatch(line);
    if (monthYearMatch != null) {
      final month = int.parse(monthYearMatch.group(1)!);
      final year = int.parse(monthYearMatch.group(2)!);
      if (month >= 1 && month <= 12) return DateTime(year, month);
    }
    return null;
  }

  double _parseAmount(String raw) => double.parse(raw.replaceAll('.', '').replaceAll(',', '.'));
}
