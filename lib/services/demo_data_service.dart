import '../models/account.dart';
import '../models/asset.dart';
import '../models/company_car.dart';
import '../models/person.dart';
import '../models/salary_slip.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

/// A ready-to-save bundle of realistic sample data, used to let a new user
/// try out every feature (categorization, budgets*, insights, accounts,
/// net worth, ...) without typing anything in first. Deliberately covers
/// two household members with their own accounts plus a credit card, a
/// savings account and a tracked loan, so that scenario is demonstrated
/// out of the box rather than just described in the README.
///
/// (*Budgets are intentionally left out: a default budget's id is just its
/// categoryId, so seeding one could silently overwrite a real budget the
/// user already set for that category.)
class DemoDataBundle {
  const DemoDataBundle({
    required this.persons,
    required this.accounts,
    required this.companyCars,
    required this.assets,
    required this.salarySlips,
    required this.transactions,
  });

  final List<Person> persons;
  final List<Account> accounts;
  final List<CompanyCar> companyCars;
  final List<Asset> assets;
  final List<SalarySlip> salarySlips;
  final List<Transaction> transactions;
}

/// Builds [DemoDataBundle]s. Every generated id is prefixed with `demo_` so
/// the demo entries can be reliably identified and removed again later
/// ([isDemoId]), and re-loading is idempotent (same ids get overwritten
/// rather than duplicated).
class DemoDataService {
  static bool isDemoId(String id) => id.startsWith('demo_');

  static const personAliceId = 'demo_person_alice';
  static const personBobId = 'demo_person_bob';

  static const accountGiroAliceId = 'demo_account_giro_alice';
  static const accountGiroBobId = 'demo_account_giro_bob';
  static const accountTagesgeldId = 'demo_account_tagesgeld';
  static const accountKreditkarteId = 'demo_account_kreditkarte';
  static const accountKreditId = 'demo_account_kredit';

  static const carId = 'demo_car';
  static const assetEtfId = 'demo_asset_etf';
  static const assetMortgageId = 'demo_asset_mortgage';

  DemoDataBundle build({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return DemoDataBundle(
      persons: _persons(),
      accounts: _accounts(),
      companyCars: _companyCars(),
      assets: _assets(),
      salarySlips: _salarySlips(reference),
      transactions: _transactions(reference),
    );
  }

  List<Person> _persons() => [
        Person(id: personAliceId, name: 'Alice (Demo)', colorValue: AppleColors.purple.toARGB32()),
        Person(id: personBobId, name: 'Bob (Demo)', colorValue: AppleColors.teal.toARGB32()),
      ];

  /// Five accounts covering the exact "mehrere Konten" scenario: a checking
  /// account per person, a shared savings account, one person's credit card
  /// and a tracked loan (negative starting balance, reduced by repayment
  /// Umbuchungen further below - see [_transactions]).
  List<Account> _accounts() => [
        Account(
          id: accountGiroAliceId,
          name: 'Girokonto Alice (Demo)',
          startingBalance: 1500,
          colorValue: AppleColors.blue.toARGB32(),
          personId: personAliceId,
        ),
        Account(
          id: accountGiroBobId,
          name: 'Girokonto Bob (Demo)',
          startingBalance: 900,
          colorValue: AppleColors.orange.toARGB32(),
          personId: personBobId,
        ),
        Account(
          id: accountTagesgeldId,
          name: 'Tagesgeldkonto (Demo)',
          startingBalance: 5000,
          colorValue: AppleColors.green.toARGB32(),
          type: AccountType.tagesgeld,
        ),
        Account(
          id: accountKreditkarteId,
          name: 'Kreditkarte Bob (Demo)',
          startingBalance: 0,
          colorValue: AppleColors.pink.toARGB32(),
          personId: personBobId,
          type: AccountType.kreditkarte,
        ),
        Account(
          id: accountKreditId,
          name: 'Autokredit (Demo)',
          startingBalance: -12000,
          colorValue: AppleColors.red.toARGB32(),
          personId: personAliceId,
          type: AccountType.kredit,
        ),
      ];

  List<CompanyCar> _companyCars() => [
        CompanyCar(
          id: carId,
          name: 'BMW 320d (Demo)',
          personId: personAliceId,
          monthlyBenefitInKind: 350,
          monthlyEmployeeContribution: 120,
          notes: 'Beispiel-Firmenwagen',
        ),
      ];

  /// Alongside the fully transaction-tracked [AccountType.kredit] account
  /// above, this also shows the alternative for a debt you don't want
  /// booking-by-booking: a plain manually-updated liability entry.
  List<Asset> _assets() => [
        Asset(id: assetEtfId, name: 'ETF-Depot (Demo)', category: AssetCategory.investment, value: 8000, colorValue: AppleColors.indigo.toARGB32()),
        Asset(
          id: assetMortgageId,
          name: 'Baufinanzierung (Demo, geschätzt)',
          category: AssetCategory.liability,
          value: 45000,
          colorValue: AppleColors.brown.toARGB32(),
          notes: 'Nicht buchungsbasiert - Restschuld wird hier nur gelegentlich manuell aktualisiert.',
        ),
      ];

  List<SalarySlip> _salarySlips(DateTime now) {
    DateTime periodMonthsAgo(int n) => DateTime(now.year, now.month - n);
    return [
      SalarySlip(id: 'demo_salary_0', period: periodMonthsAgo(0), gross: 4200, net: 3180, incomeTax: 750, socialSecurity: 270, personId: personAliceId),
      SalarySlip(id: 'demo_salary_1', period: periodMonthsAgo(1), gross: 4200, net: 3180, incomeTax: 750, socialSecurity: 270, personId: personAliceId),
    ];
  }

  List<Transaction> _transactions(DateTime now) {
    DateTime dateAt(int monthsAgo, int day) {
      final targetMonth = DateTime(now.year, now.month - monthsAgo);
      final lastDayOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
      // For the current month, never generate a date after "now" - demo
      // bookings must look like they already happened.
      final maxDay = monthsAgo == 0 ? now.day : lastDayOfMonth;
      return DateTime(targetMonth.year, targetMonth.month, day.clamp(1, maxDay));
    }

    var counter = 0;
    String nextId() => 'demo_txn_${counter++}';

    final transactions = <Transaction>[];
    for (final monthsAgo in [2, 1, 0]) {
      final isCurrentMonth = monthsAgo == 0;
      transactions.addAll([
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 1),
          amount: 3180,
          description: 'Gehalt (Demo)',
          categoryId: 'income',
          subcategoryId: 'income_gehalt',
          isRecurring: true,
          personId: personAliceId,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 3),
          amount: -950,
          description: 'Miete (Demo)',
          categoryId: 'wohnen',
          subcategoryId: 'wohnen_miete',
          isRecurring: true,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 3),
          amount: -120,
          description: 'Nebenkosten (Demo)',
          categoryId: 'wohnen',
          subcategoryId: 'wohnen_nebenkosten',
          isRecurring: true,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 5),
          amount: -65,
          description: 'Stadtwerke Strom (Demo)',
          categoryId: 'wohnen',
          subcategoryId: 'wohnen_energie',
          isRecurring: true,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 7),
          amount: -12.99,
          description: 'Netflix (Demo)',
          categoryId: 'fixkosten',
          subcategoryId: 'fixkosten_streaming',
          isRecurring: true,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 7),
          amount: -9.99,
          description: 'Spotify (Demo)',
          categoryId: 'fixkosten',
          subcategoryId: 'fixkosten_streaming',
          isRecurring: true,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 10),
          amount: -34.99,
          description: 'Telekom Mobilfunk (Demo)',
          categoryId: 'fixkosten',
          subcategoryId: 'fixkosten_mobilfunk',
          isRecurring: true,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 12),
          amount: -120,
          description: 'Firmenwagen Eigenanteil (Demo)',
          categoryId: 'mobilitaet',
          subcategoryId: 'mobilitaet_firmenwagen',
          isRecurring: true,
          personId: personAliceId,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 4),
          amount: isCurrentMonth ? -68.40 : -58.20,
          description: 'Tankstelle Aral (Demo)',
          categoryId: 'mobilitaet',
          subcategoryId: 'mobilitaet_tanken',
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 18),
          amount: -49.90,
          description: 'Bahn Ticket (Demo)',
          categoryId: 'mobilitaet',
          subcategoryId: 'mobilitaet_oepnv',
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 6),
          // Deliberately higher in the current month to demonstrate the
          // "Ausgabenspitze" (spending spike) optimization insight.
          amount: isCurrentMonth ? -175.30 : -95.60,
          description: 'Rewe Supermarkt (Demo)',
          categoryId: 'lebensmittel',
          subcategoryId: 'lebensmittel_supermarkt',
          personId: personAliceId,
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 20),
          amount: -88.10,
          description: 'Edeka Supermarkt (Demo)',
          categoryId: 'lebensmittel',
          subcategoryId: 'lebensmittel_supermarkt',
          personId: personBobId,
          accountId: accountGiroBobId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 14),
          amount: -32.50,
          description: 'Restaurant (Demo)',
          categoryId: 'lebensmittel',
          subcategoryId: 'lebensmittel_restaurant',
          accountId: accountGiroAliceId,
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 9),
          amount: -24.99,
          description: 'Apotheke (Demo)',
          categoryId: 'gesundheit',
          subcategoryId: 'gesundheit_apotheke',
          accountId: accountGiroAliceId,
        ),
        // Bob's credit card - a couple of purchases booked directly against it.
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 16),
          amount: -45.00,
          description: 'Media Markt (Demo)',
          categoryId: 'shopping',
          subcategoryId: 'shopping_elektronik',
          personId: personBobId,
          accountId: accountKreditkarteId,
        ),
        // Autokredit-Tilgung: an Umbuchung from Alice's checking account to
        // the tracked loan account, reducing its (negative) balance over time.
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 27),
          amount: -300,
          description: 'Autokredit Tilgung (Demo)',
          categoryId: 'umbuchung',
          accountId: accountGiroAliceId,
          isTransfer: true,
          transferGroupId: 'demo_transfer_kredit_$monthsAgo',
        ),
        Transaction(
          id: nextId(),
          date: dateAt(monthsAgo, 27),
          amount: 300,
          description: 'Autokredit Tilgung (Demo)',
          categoryId: 'umbuchung',
          accountId: accountKreditId,
          isTransfer: true,
          transferGroupId: 'demo_transfer_kredit_$monthsAgo',
        ),
      ]);

      if (isCurrentMonth) {
        transactions.add(Transaction(
          id: nextId(),
          date: dateAt(0, 22),
          amount: -89.95,
          description: 'Zalando Bestellung (Demo)',
          categoryId: 'shopping',
          subcategoryId: 'shopping_kleidung',
          personId: personBobId,
          accountId: accountKreditkarteId,
        ));
        transactions.add(Transaction(
          id: nextId(),
          date: dateAt(0, 15),
          amount: -200,
          description: 'Umbuchung zu Tagesgeldkonto (Demo)',
          categoryId: 'umbuchung',
          accountId: accountGiroAliceId,
          isTransfer: true,
          transferGroupId: 'demo_transfer_0',
        ));
        transactions.add(Transaction(
          id: nextId(),
          date: dateAt(0, 15),
          amount: 200,
          description: 'Umbuchung von Girokonto (Demo)',
          categoryId: 'umbuchung',
          accountId: accountTagesgeldId,
          isTransfer: true,
          transferGroupId: 'demo_transfer_0',
        ));
      }
    }
    return transactions;
  }
}
