import 'package:finance_analyzer/models/transaction.dart';
import 'package:finance_analyzer/services/salary_duplicate_detection_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Transaction tx(DateTime date, double amount, String description, {String id = 't1'}) {
    return Transaction(id: id, date: date, amount: amount, description: description, categoryId: 'income');
  }

  test('findet eine exakt übereinstimmende Einnahme im selben Monat', () {
    final existing = [tx(DateTime(2026, 3, 5), 2500.00, 'Gehalt Muster GmbH')];
    final match = findLikelyMatchingIncome(date: DateTime(2026, 3, 27), amount: 2500.00, existing: existing);
    expect(match, isNotNull);
    expect(match!.description, 'Gehalt Muster GmbH');
  });

  test('toleriert kleine Rundungsabweichungen innerhalb der Toleranz', () {
    final existing = [tx(DateTime(2026, 3, 5), 2500.00, 'Gehalt')];
    final match = findLikelyMatchingIncome(date: DateTime(2026, 3, 27), amount: 2510.00, existing: existing);
    expect(match, isNotNull);
  });

  test('unterschiedlicher Monat wird nicht als Übereinstimmung gewertet', () {
    final existing = [tx(DateTime(2026, 2, 27), 2500.00, 'Gehalt')];
    final match = findLikelyMatchingIncome(date: DateTime(2026, 3, 1), amount: 2500.00, existing: existing);
    expect(match, isNull);
  });

  test('deutlich abweichender Betrag wird nicht als Übereinstimmung gewertet', () {
    final existing = [tx(DateTime(2026, 3, 5), 50.00, 'Rückerstattung')];
    final match = findLikelyMatchingIncome(date: DateTime(2026, 3, 27), amount: 2500.00, existing: existing);
    expect(match, isNull);
  });

  test('Ausgaben (negative Beträge) werden ignoriert', () {
    final existing = [tx(DateTime(2026, 3, 5), -2500.00, 'Miete')];
    final match = findLikelyMatchingIncome(date: DateTime(2026, 3, 27), amount: 2500.00, existing: existing);
    expect(match, isNull);
  });

  test('leere Liste liefert keine Übereinstimmung', () {
    expect(findLikelyMatchingIncome(date: DateTime(2026, 3, 27), amount: 2500.00, existing: const []), isNull);
  });
}
