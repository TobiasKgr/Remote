/// Normalizes a booking description down to its "merchant text" so that
/// e.g. "REWE SAGT DANKE 3141" and "REWE SAGT DANKE 8827" - the same
/// merchant, differing only by a trailing reference number - collapse to
/// the same key. Shared by everything that needs to recognize "the same
/// recurring payment" across bookings: learned-history categorization,
/// recurring-transaction generation, and the yearly planner's row grouping.
String normalizeDescription(String description) {
  return description
      .toLowerCase()
      .replaceAll(RegExp(r'[0-9]+'), '')
      .replaceAll(RegExp(r'[^a-zäöüß\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
