import 'package:finance_analyzer/models/category.dart';
import 'package:finance_analyzer/services/optimization_service.dart';
import 'package:finance_analyzer/models/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Transaction _tx({
  required String id,
  required DateTime date,
  required double amount,
  required String description,
  required String categoryId,
  String? subcategoryId,
  bool isRecurring = false,
}) {
  return Transaction(
    id: id,
    date: date,
    amount: amount,
    description: description,
    categoryId: categoryId,
    subcategoryId: subcategoryId,
    isRecurring: isRecurring,
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('de_DE'));

  final categories = [
    Category(
      id: 'fixkosten',
      name: 'Fixkosten & Abos',
      type: CategoryType.expense,
      colorValue: 0xFF000000,
      subcategories: [Subcategory(id: 'streaming', name: 'Streaming-Abos')],
    ),
    Category(id: 'lebensmittel', name: 'Lebensmittel', type: CategoryType.expense, colorValue: 0xFF000000),
  ];

  final service = OptimizationService();
  final month = DateTime(2026, 7);

  test('meldet wiederkehrende Kosten diesen Monat', () {
    final transactions = [
      _tx(id: 'a', date: month, amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.any((i) => i.title == 'Wiederkehrende Kosten'), isTrue);
  });

  test('erkennt mehrere Abos in derselben Unterkategorie', () {
    final transactions = [
      _tx(id: 'a', date: month, amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
      _tx(id: 'b', date: month, amount: -9.99, description: 'Spotify', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
    ];
    final insights = service.analyze(transactions, categories, month);
    final match = insights.where((i) => i.title.contains('Mehrere Abos'));
    expect(match, isNotEmpty);
    expect(match.first.description, contains('Netflix'));
    expect(match.first.description, contains('Spotify'));
    expect(match.first.severity, InsightSeverity.warning);
  });

  test('erkennt keine mehrfach-Abos wenn nur ein Abo in der Unterkategorie läuft', () {
    final transactions = [
      _tx(id: 'a', date: month, amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.where((i) => i.title.contains('Mehrere Abos')), isEmpty);
  });

  test('erkennt Ausgabenspitze gegenüber dem 3-Monats-Schnitt', () {
    final transactions = [
      _tx(id: 'm1', date: DateTime(2026, 4), amount: -50, description: 'Supermarkt', categoryId: 'lebensmittel'),
      _tx(id: 'm2', date: DateTime(2026, 5), amount: -55, description: 'Supermarkt', categoryId: 'lebensmittel'),
      _tx(id: 'm3', date: DateTime(2026, 6), amount: -45, description: 'Supermarkt', categoryId: 'lebensmittel'),
      _tx(id: 'm4', date: month, amount: -150, description: 'Supermarkt', categoryId: 'lebensmittel'),
    ];
    final insights = service.analyze(transactions, categories, month);
    final match = insights.where((i) => i.title.contains('Ausgabenspitze'));
    expect(match, isNotEmpty);
    expect(match.first.severity, InsightSeverity.warning);
  });

  test('keine Ausgabenspitze bei stabilen Ausgaben', () {
    final transactions = [
      _tx(id: 'm1', date: DateTime(2026, 4), amount: -50, description: 'Supermarkt', categoryId: 'lebensmittel'),
      _tx(id: 'm2', date: DateTime(2026, 5), amount: -50, description: 'Supermarkt', categoryId: 'lebensmittel'),
      _tx(id: 'm3', date: DateTime(2026, 6), amount: -50, description: 'Supermarkt', categoryId: 'lebensmittel'),
      _tx(id: 'm4', date: month, amount: -52, description: 'Supermarkt', categoryId: 'lebensmittel'),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.where((i) => i.title.contains('Ausgabenspitze')), isEmpty);
  });

  test('erkennt seit mind. 3 Monaten unverändert laufendes Abo', () {
    final transactions = [
      _tx(id: 'm1', date: DateTime(2026, 5), amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
      _tx(id: 'm2', date: DateTime(2026, 6), amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
      _tx(id: 'm3', date: month, amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.any((i) => i.title.contains('Läuft seit 3 Monaten')), isTrue);
  });

  test('kein Streak-Hinweis bei erst 2 Monaten', () {
    final transactions = [
      _tx(id: 'm1', date: DateTime(2026, 6), amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
      _tx(id: 'm2', date: month, amount: -12.99, description: 'Netflix', categoryId: 'fixkosten', subcategoryId: 'streaming', isRecurring: true),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.where((i) => i.title.contains('Läuft seit')), isEmpty);
  });

  test('erkennt eine ungewöhnliche Buchung bei einem sonst regelmäßigen Empfänger', () {
    final transactions = [
      _tx(id: 'h1', date: DateTime(2026, 4), amount: -40, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
      _tx(id: 'h2', date: DateTime(2026, 5), amount: -45, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
      _tx(id: 'h3', date: DateTime(2026, 6), amount: -38, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
      _tx(id: 'h4', date: month, amount: -220, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
    ];
    final insights = service.analyze(transactions, categories, month);
    final match = insights.where((i) => i.title.contains('Ungewöhnliche Buchung'));
    expect(match, isNotEmpty);
    expect(match.first.description, contains('220'));
    expect(match.first.severity, InsightSeverity.warning);
  });

  test('keine Anomalie-Meldung ohne ausreichende Historie bei diesem Empfänger', () {
    final transactions = [
      _tx(id: 'h1', date: DateTime(2026, 6), amount: -40, description: 'Neuer Laden', categoryId: 'lebensmittel'),
      _tx(id: 'h2', date: month, amount: -220, description: 'Neuer Laden', categoryId: 'lebensmittel'),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.where((i) => i.title.contains('Ungewöhnliche Buchung')), isEmpty);
  });

  test('keine Anomalie-Meldung bei üblichen Schwankungen', () {
    final transactions = [
      _tx(id: 'h1', date: DateTime(2026, 4), amount: -40, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
      _tx(id: 'h2', date: DateTime(2026, 5), amount: -45, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
      _tx(id: 'h3', date: DateTime(2026, 6), amount: -38, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
      _tx(id: 'h4', date: month, amount: -50, description: 'REWE SAGT DANKE', categoryId: 'lebensmittel'),
    ];
    final insights = service.analyze(transactions, categories, month);
    expect(insights.where((i) => i.title.contains('Ungewöhnliche Buchung')), isEmpty);
  });

  test('keine Hinweise bei leeren Buchungen', () {
    expect(service.analyze([], categories, month), isEmpty);
  });
}
