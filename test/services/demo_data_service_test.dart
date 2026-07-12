import 'package:finance_analyzer/services/demo_data_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = DemoDataService();

  test('isDemoId erkennt nur Demo-Präfix', () {
    expect(DemoDataService.isDemoId('demo_txn_0'), isTrue);
    expect(DemoDataService.isDemoId('fixkosten'), isFalse);
  });

  test('build() liefert nicht-leere Listen mit ausschließlich demo_-IDs', () {
    final bundle = service.build(now: DateTime(2026, 7, 15));

    expect(bundle.persons, isNotEmpty);
    expect(bundle.accounts, isNotEmpty);
    expect(bundle.companyCars, isNotEmpty);
    expect(bundle.assets, isNotEmpty);
    expect(bundle.salarySlips, isNotEmpty);
    expect(bundle.transactions, isNotEmpty);

    for (final p in bundle.persons) {
      expect(DemoDataService.isDemoId(p.id), isTrue);
    }
    for (final a in bundle.accounts) {
      expect(DemoDataService.isDemoId(a.id), isTrue);
    }
    for (final c in bundle.companyCars) {
      expect(DemoDataService.isDemoId(c.id), isTrue);
    }
    for (final a in bundle.assets) {
      expect(DemoDataService.isDemoId(a.id), isTrue);
    }
    for (final s in bundle.salarySlips) {
      expect(DemoDataService.isDemoId(s.id), isTrue);
    }
    for (final t in bundle.transactions) {
      expect(DemoDataService.isDemoId(t.id), isTrue);
    }
  });

  test('alle generierten Transaktions-IDs sind eindeutig', () {
    final bundle = service.build(now: DateTime(2026, 7, 15));
    final ids = bundle.transactions.map((t) => t.id).toSet();
    expect(ids, hasLength(bundle.transactions.length));
  });

  test('Umbuchung zwischen den beiden Demo-Konten ist ausgeglichen', () {
    final bundle = service.build(now: DateTime(2026, 7, 15));
    final transfers = bundle.transactions.where((t) => t.isTransfer).toList();
    expect(transfers, hasLength(2));
    expect(transfers.fold<double>(0, (s, t) => s + t.amount), 0);
    expect(transfers.map((t) => t.transferGroupId).toSet(), hasLength(1));
  });

  test('build() ist deterministisch für dasselbe Referenzdatum', () {
    final now = DateTime(2026, 7, 15);
    final first = service.build(now: now);
    final second = service.build(now: now);
    expect(first.transactions.map((t) => t.id), second.transactions.map((t) => t.id));
    expect(first.transactions.map((t) => t.amount), second.transactions.map((t) => t.amount));
  });

  test('keine Transaktion liegt in der Zukunft bezogen auf das Referenzdatum', () {
    final now = DateTime(2026, 7, 15);
    final bundle = service.build(now: now);
    for (final t in bundle.transactions) {
      expect(t.date.isAfter(now), isFalse, reason: '${t.description} liegt nach $now');
    }
  });
}
