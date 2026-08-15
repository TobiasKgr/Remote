import '../models/transaction.dart';
import '../utils/description_normalizer.dart';

/// True when a candidate booking (same date, amount and normalized
/// description) already exists among [existing] transactions - used to
/// keep PDF imports from silently creating duplicate bookings when a
/// statement's date range overlaps a previous import (or the same file is
/// imported twice by mistake).
bool isDuplicateBooking({
  required DateTime date,
  required double amount,
  required String description,
  required Iterable<Transaction> existing,
}) {
  final normalized = normalizeDescription(description);
  return existing.any((t) =>
      t.date.year == date.year &&
      t.date.month == date.month &&
      t.date.day == date.day &&
      (t.amount - amount).abs() < 0.005 &&
      normalizeDescription(t.description) == normalized);
}
