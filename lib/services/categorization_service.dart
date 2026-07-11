import '../models/category.dart';

class CategoryMatch {
  const CategoryMatch(this.categoryId, this.subcategoryId);

  final String categoryId;
  final String? subcategoryId;
}

/// Matches a free-text transaction description against the keywords stored
/// on each [Subcategory] to suggest a category automatically, e.g. when
/// importing a PDF bank statement.
class CategorizationService {
  const CategorizationService(this.categories);

  final List<Category> categories;

  CategoryMatch? suggest(String description) {
    final lower = description.toLowerCase();
    for (final category in categories) {
      for (final subcategory in category.subcategories) {
        for (final keyword in subcategory.keywords) {
          if (keyword.isNotEmpty && lower.contains(keyword.toLowerCase())) {
            return CategoryMatch(category.id, subcategory.id);
          }
        }
      }
    }
    return null;
  }

  /// Fallback category id used when no keyword matches.
  String fallbackCategoryId(bool isIncome) {
    if (isIncome) {
      final match = categories.where((c) => c.type == CategoryType.income);
      if (match.isNotEmpty) return match.first.id;
    }
    final sonstiges = categories.where((c) => c.id == 'sonstiges');
    if (sonstiges.isNotEmpty) return sonstiges.first.id;
    return categories.first.id;
  }
}
