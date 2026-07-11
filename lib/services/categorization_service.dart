import '../models/category.dart';
import '../models/transaction.dart';

class CategoryMatch {
  const CategoryMatch(this.categoryId, this.subcategoryId);

  final String categoryId;
  final String? subcategoryId;
}

/// Suggests a category/subcategory for a transaction description, e.g. when
/// importing a PDF bank statement.
///
/// Two heuristics are tried, in order:
/// 1. **Learned history**: if an earlier transaction with a near-identical
///    description (same merchant text, ignoring varying trailing numbers/
///    dates) was already categorized - manually or via a previous import -
///    that category is reused. This reflects the user's own corrections and
///    takes priority over the generic keyword lists.
/// 2. **Keyword matching**: falls back to the keyword lists configured per
///    subcategory. When a description matches multiple keywords, the
///    *longest* one wins, since a more specific term (e.g. "amazon prime")
///    is a better signal than a shorter incidental substring match
///    (e.g. "amazon").
class CategorizationService {
  CategorizationService(this.categories, {this.history = const []});

  final List<Category> categories;
  final List<Transaction> history;

  CategoryMatch? suggest(String description) {
    return _suggestFromHistory(description) ?? _suggestFromKeywords(description);
  }

  CategoryMatch? _suggestFromHistory(String description) {
    final normalized = _normalize(description);
    if (normalized.isEmpty) return null;

    final validCategoryIds = categories.map((c) => c.id).toSet();
    final tally = <String, ({int count, DateTime lastSeen})>{};

    for (final t in history) {
      if (_normalize(t.description) != normalized) continue;
      if (!validCategoryIds.contains(t.categoryId)) continue;

      final key = '${t.categoryId}::${t.subcategoryId ?? ''}';
      final existing = tally[key];
      tally[key] = (
        count: (existing?.count ?? 0) + 1,
        lastSeen: existing == null || t.date.isAfter(existing.lastSeen) ? t.date : existing.lastSeen,
      );
    }
    if (tally.isEmpty) return null;

    final best = tally.entries.reduce((a, b) {
      if (a.value.count != b.value.count) return a.value.count > b.value.count ? a : b;
      return a.value.lastSeen.isAfter(b.value.lastSeen) ? a : b;
    });

    final parts = best.key.split('::');
    return CategoryMatch(parts[0], parts[1].isEmpty ? null : parts[1]);
  }

  CategoryMatch? _suggestFromKeywords(String description) {
    final lower = description.toLowerCase();
    CategoryMatch? best;
    var bestKeywordLength = 0;

    for (final category in categories) {
      for (final subcategory in category.subcategories) {
        for (final keyword in subcategory.keywords) {
          if (keyword.isEmpty) continue;
          if (keyword.length > bestKeywordLength && lower.contains(keyword.toLowerCase())) {
            best = CategoryMatch(category.id, subcategory.id);
            bestKeywordLength = keyword.length;
          }
        }
      }
    }
    return best;
  }

  /// Fallback category id used when nothing matches.
  String fallbackCategoryId(bool isIncome) {
    if (isIncome) {
      final match = categories.where((c) => c.type == CategoryType.income);
      if (match.isNotEmpty) return match.first.id;
    }
    final sonstiges = categories.where((c) => c.id == 'sonstiges');
    if (sonstiges.isNotEmpty) return sonstiges.first.id;
    return categories.first.id;
  }

  /// Strips digits and punctuation so "REWE SAGT DANKE 3141" and
  /// "REWE SAGT DANKE 8827" normalize to the same key.
  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[0-9]+'), '')
        .replaceAll(RegExp(r'[^a-zäöüß\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
