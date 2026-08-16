import '../models/custom_import_profile.dart';
import 'pdf_import_service.dart' show ParsedTransaction;

/// Parses bank-statement text using a user-taught [CustomImportProfile]
/// instead of a bespoke bank-specific parser. Scans the *entire* text for
/// date markers (rather than splitting on newlines) since some PDF layouts
/// flatten pages into very few line breaks - the same lesson learned while
/// building the TARGOBANK parser. For each date found, the amount is taken
/// either right after it or at the end of the text up to the next date,
/// depending on the profile's [CustomImportProfile.amountPosition]; the sign
/// follows the same S/H (Soll/Haben) convention as the built-in generic
/// parser when no explicit +/- is present.
List<ParsedTransaction> parseWithCustomProfile(String text, CustomImportProfile profile) {
  final dateRegex = switch (profile.dateFormat) {
    ImportDateFormat.ddMMyyyy => RegExp(r'(\d{2})\.(\d{2})\.(\d{4})'),
    ImportDateFormat.ddMMyy => RegExp(r'(\d{2})\.(\d{2})\.(\d{2})'),
  };
  final amountRegex = switch (profile.decimalSeparator) {
    ImportDecimalSeparator.comma => RegExp(r'([+-]?\d{1,3}(?:\.\d{3})*,\d{2})\s*(S|H)?'),
    ImportDecimalSeparator.dot => RegExp(r'([+-]?\d{1,3}(?:,\d{3})*\.\d{2})\s*(S|H)?'),
  };

  final dateMatches = dateRegex.allMatches(text).toList();
  final results = <ParsedTransaction>[];

  for (var i = 0; i < dateMatches.length; i++) {
    final dateMatch = dateMatches[i];
    final rowEnd = i + 1 < dateMatches.length ? dateMatches[i + 1].start : text.length;
    final rowText = text.substring(dateMatch.end, rowEnd);

    final amountMatches = amountRegex.allMatches(rowText).toList();
    if (amountMatches.isEmpty) continue;
    final amountMatch = profile.amountPosition == ImportAmountPosition.afterDate ? amountMatches.first : amountMatches.last;

    final date = _parseDate(dateMatch, profile.dateFormat);
    final (amount, ambiguous) = _parseAmount(amountMatch, profile.decimalSeparator);
    final description = (rowText.substring(0, amountMatch.start) + rowText.substring(amountMatch.end))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    results.add(ParsedTransaction(date: date, description: description, amount: amount, amountAmbiguous: ambiguous));
  }

  return results;
}

DateTime _parseDate(RegExpMatch match, ImportDateFormat format) {
  final day = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final yearPart = match.group(3)!;
  final year = format == ImportDateFormat.ddMMyy ? 2000 + int.parse(yearPart) : int.parse(yearPart);
  return DateTime(year, month, day);
}

/// Returns (signedAmount, wasAmbiguous) - same convention as the built-in
/// parsers: an explicit sign or S/H marker is trusted, otherwise the amount
/// is assumed to be an expense and flagged for the user to double check.
(double, bool) _parseAmount(RegExpMatch match, ImportDecimalSeparator separator) {
  final numberPart = match.group(1)!;
  final soHaMarker = match.group(2);

  final hasExplicitSign = numberPart.startsWith('-') || numberPart.startsWith('+');
  final normalized = switch (separator) {
    ImportDecimalSeparator.comma => numberPart.replaceAll('.', '').replaceAll(',', '.'),
    ImportDecimalSeparator.dot => numberPart.replaceAll(',', ''),
  };
  final magnitude = double.parse(normalized.replaceAll('+', ''));

  if (hasExplicitSign) return (magnitude, false);
  if (soHaMarker == 'S') return (-magnitude.abs(), false);
  if (soHaMarker == 'H') return (magnitude.abs(), false);
  return (-magnitude.abs(), true);
}
