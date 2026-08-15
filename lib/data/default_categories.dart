import '../models/category.dart';
import '../theme/app_theme.dart';

/// Seed data shown on first launch. Users can freely rename, extend or
/// delete these afterwards via the Categories screen.
///
/// Keyword lists are deliberately broad (real merchant/brand names as they
/// tend to show up in German bank statement exports) so that automatic
/// categorization (see `CategorizationService`) hits a real category for the
/// large majority of everyday bookings, leaving "Sonstiges" for genuine
/// edge cases rather than common but simply un-listed merchants. Longer,
/// more specific keywords always win over shorter ones on a match (see
/// `CategorizationService._suggestFromKeywords`), so it's safe to mix a
/// short generic term with longer specific brand names in the same list.
List<Category> buildDefaultCategories() {
  return [
    Category(
      id: 'income',
      name: 'Einkommen',
      type: CategoryType.income,
      colorValue: AppleColors.green.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'income_gehalt',
          name: 'Gehalt',
          keywords: ['gehalt', 'lohn', 'lohnzahlung', 'gehaltszahlung', 'vergütung', 'entgeltabrechnung', 'auszahlung gehalt', 'verguetung'],
        ),
        Subcategory(id: 'income_bonus', name: 'Bonus / Prämie', keywords: ['bonus', 'prämie', 'sonderzahlung', 'urlaubsgeld', 'weihnachtsgeld', 'provision', 'praemie']),
        Subcategory(
          id: 'income_transfer',
          name: 'Überweisung erhalten',
          keywords: ['erstattung', 'rückerstattung', 'rückzahlung', 'auszahlung', 'gutschrift', 'rueckerstattung', 'rueckzahlung'],
        ),
        Subcategory(id: 'income_other', name: 'Sonstige Einnahmen', keywords: []),
      ],
    ),
    Category(
      id: 'wohnen',
      name: 'Wohnen',
      type: CategoryType.expense,
      colorValue: AppleColors.brown.toARGB32(),
      subcategories: [
        Subcategory(id: 'wohnen_miete', name: 'Miete', keywords: ['miete', 'kaltmiete', 'warmmiete', 'wohnung', 'vermieter', 'hausverwaltung']),
        Subcategory(id: 'wohnen_nebenkosten', name: 'Nebenkosten', keywords: ['nebenkosten', 'hausgeld', 'betriebskosten', 'wohngeld', 'grundsteuer']),
        Subcategory(
          id: 'wohnen_energie',
          name: 'Strom / Gas',
          keywords: ['stadtwerke', 'strom', 'gas', 'energie', 'eon', 'e.on', 'vattenfall', 'rwe', 'enbw', 'yello', 'lichtblick', 'naturstrom', 'techem', 'wasser', 'wasserwerke', 'fernwärme', 'fernwaerme'],
        ),
        Subcategory(
          id: 'wohnen_einrichtung',
          name: 'Einrichtung / Haushalt',
          keywords: ['ikea', 'poco', 'roller', 'mömax', 'porta', 'xxxlutz', 'dänisches bettenlager', 'hornbach', 'obi', 'bauhaus', 'toom', 'hagebau', 'baumarkt', 'möbel', 'moemax', 'daenisches bettenlager', 'moebel'],
        ),
      ],
    ),
    Category(
      id: 'fixkosten',
      name: 'Fixkosten & Abos',
      type: CategoryType.expense,
      colorValue: AppleColors.indigo.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'fixkosten_streaming',
          name: 'Streaming-Abos',
          keywords: [
            'netflix', 'spotify', 'disney', 'disney+', 'amazon prime', 'prime video', 'apple tv', 'apple music',
            'youtube premium', 'youtube music', 'dazn', 'sky ticket', 'sky deutschland', 'wow ', 'rtl+', 'joyn',
            'paramount', 'audible', 'deezer', 'tidal', 'amazon music', 'crunchyroll', 'mubi', 'discovery+', 'magenta tv',
          ],
        ),
        Subcategory(
          id: 'fixkosten_mobilfunk',
          name: 'Mobilfunk / Internet',
          keywords: [
            'telekom', 'vodafone', 'o2', 'mobilfunk', 'internet', '1&1', 'congstar', 'aldi talk', 'blau.de',
            'freenet', 'mobilcom', 'lidl connect', 'otelo', 'winsim', 'simyo', 'drillisch', 'klarmobil',
            'unitymedia', 'deutsche glasfaser', 'telefonica', 'penny mobil', 'lycamobile',
          ],
        ),
        Subcategory(
          id: 'fixkosten_versicherung',
          name: 'Versicherungen',
          keywords: ['versicherung', 'allianz', 'huk', 'huk24', 'axa', 'ergo', 'generali', 'r+v', 'devk', 'signal iduna', 'debeka', 'lvm', 'gothaer', 'zurich', 'vhv', 'barmenia', 'nürnberger', 'continentale', 'hansemerkur', 'württembergische', 'wgv', 'cosmosdirekt', 'die bayerische', 'alte leipziger', 'itzehoer', 'provinzial', 'sparkassen-versicherung', 'haftpflicht', 'hausrat', 'rechtsschutz', 'berufsunfähigkeit', 'nuernberger', 'wuerttembergische', 'berufsunfaehigkeit'],
        ),
        Subcategory(
          id: 'fixkosten_mitgliedschaft',
          name: 'Mitgliedschaften',
          keywords: [
            'fitnessstudio', 'mitgliedschaft', 'verein', 'mcfit', 'fitx', 'clever fit', 'kieser', 'urban sports club',
            'adac', 'gewerkschaft', 'volkshochschule', 'vhs', 'jahresbeitrag',
          ],
        ),
        Subcategory(
          id: 'fixkosten_software',
          name: 'Software-Abos',
          keywords: [
            'icloud', 'google one', 'google storage', 'dropbox', 'microsoft 365', 'office 365', 'adobe', 'canva',
            'notion', 'chatgpt', 'openai', 'claude.ai', 'anthropic', 'github', 'app store', 'google play', 'playstation plus',
            'xbox game pass', 'nintendo', 'steam', 'nordvpn', 'expressvpn', 'antivirus',
          ],
        ),
      ],
    ),
    Category(
      id: 'lebensmittel',
      name: 'Lebensmittel',
      type: CategoryType.expense,
      colorValue: AppleColors.orange.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'lebensmittel_supermarkt',
          name: 'Supermarkt',
          keywords: [
            'rewe', 'edeka', 'aldi', 'lidl', 'kaufland', 'netto', 'penny', 'real,-', 'norma', 'denns', 'dennree',
            'alnatura', 'bio company', 'tegut', 'globus', 'marktkauf', 'famila', 'combi', 'nahkauf', 'basic bio',
            'hit markt', 'e center', 'e-center', 'wasgau', 'feneberg',
          ],
        ),
        Subcategory(
          id: 'lebensmittel_restaurant',
          name: 'Restaurant / Café',
          keywords: ['restaurant', 'café', 'cafe', 'bistro', 'imbiss', 'mcdonald', 'burger king', 'kfc', 'subway', 'vapiano', 'dean & david', 'starbucks', 'l\'osteria', 'domino', 'pizza hut', 'nordsee', 'sushi', 'lieferando', 'wolt', 'uber eats', 'flink', 'gorillas', 'coffee fellow', 'tchibo', 'bäckerei', 'konditorei', 'metzgerei', 'baeckerei'],
        ),
      ],
    ),
    Category(
      id: 'mobilitaet',
      name: 'Mobilität',
      type: CategoryType.expense,
      colorValue: AppleColors.gray.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'mobilitaet_tanken',
          name: 'Tanken',
          keywords: ['tankstelle', 'aral', 'shell', 'esso', 'jet tankstelle', 'total energies', 'star tankstelle', 'agip', 'eni', 'omv', 'avia', 'sprint tankstelle', 'westfalen ag', 'tank & rast', 'supercharger', 'ladesäule', 'ladesaeule'],
        ),
        Subcategory(
          id: 'mobilitaet_oepnv',
          name: 'ÖPNV',
          keywords: [
            'bahn', 'deutsche bahn', 'db vertrieb', 'bvg', 'vvo', 'mvv', 'vbb', 'hvv', 'rmv', 'vrr', 'kvb', 'mvg',
            'vgn', 'vrs', 'flixbus', 'flixtrain', 'free now', 'mytaxi', 'taxi', 'nahverkehr', 'deutschlandticket',
          ],
        ),
        Subcategory(
          id: 'mobilitaet_kfz',
          name: 'KFZ-Versicherung / Werkstatt',
          keywords: ['kfz', 'werkstatt', 'tüv', 'dekra', 'atu', 'euromaster', 'vergölst', 'pkw-versicherung', 'autohaus', 'reifen', 'point s', 'mobil oil', 'tuev', 'vergoelst'],
        ),
        Subcategory(id: 'mobilitaet_firmenwagen', name: 'Firmenwagen', keywords: ['firmenwagen', 'leasingrate', 'dienstwagen']),
        Subcategory(
          id: 'mobilitaet_sharing',
          name: 'Carsharing / Fahrrad',
          keywords: ['sixt share', 'share now', 'miles mobility', 'call a bike', 'nextbike', 'e-scooter', 'tier mobility', 'lime', 'voi'],
        ),
      ],
    ),
    Category(
      id: 'freizeit',
      name: 'Freizeit & Hobby',
      type: CategoryType.expense,
      colorValue: AppleColors.purple.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'freizeit_hobby',
          name: 'Hobby',
          keywords: ['kino', 'cinestar', 'cinemaxx', 'uci', 'konzert', 'eventim', 'ticketmaster', 'museum', 'schwimmbad', 'therme', 'bowling', 'escape room'],
        ),
        Subcategory(
          id: 'freizeit_urlaub',
          name: 'Urlaub',
          keywords: [
            'reise', 'hotel', 'flug', 'booking.com', 'airbnb', 'expedia', 'tui', 'lufthansa', 'ryanair', 'eurowings',
            'easyjet', 'condor', 'hotels.com', 'trivago', 'ferienwohnung', 'pension', 'jugendherberge',
          ],
        ),
      ],
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      colorValue: AppleColors.pink.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'shopping_kleidung',
          name: 'Kleidung',
          keywords: [
            'zalando', 'h&m', 'zara', 'c&a', 'primark', 'about you', 'peek & cloppenburg', 'esprit', 's.oliver',
            'tommy hilfiger', 'deichmann', 'snipes', 'jd sports', 'new yorker', 'bonprix', 'tk maxx', 'vinted',
          ],
        ),
        Subcategory(
          id: 'shopping_elektronik',
          name: 'Elektronik',
          keywords: [
            'media markt', 'mediamarkt', 'saturn', 'amazon', 'otto', 'cyberport', 'notebooksbilliger', 'conrad',
            'alternate', 'apple store', 'samsung', 'euronics', 'expert', 'gravis',
          ],
        ),
        Subcategory(
          id: 'shopping_drogerie',
          name: 'Drogerie',
          keywords: ['dm-drogerie', 'dm drogerie', 'rossmann', 'müller drogerie', 'douglas', 'flaconi', 'parfümerie', 'mueller drogerie', 'parfuemerie'],
        ),
        Subcategory(id: 'shopping_bücher', name: 'Bücher / Medien', keywords: ['thalia', 'hugendubel', 'weltbild', 'buchhandlung', 'saturn media']),
      ],
    ),
    Category(
      id: 'gesundheit',
      name: 'Gesundheit',
      type: CategoryType.expense,
      colorValue: AppleColors.teal.toARGB32(),
      subcategories: [
        Subcategory(id: 'gesundheit_apotheke', name: 'Apotheke', keywords: ['apotheke', 'docmorris', 'shop-apotheke', 'medpex']),
        Subcategory(id: 'gesundheit_arzt', name: 'Arzt', keywords: ['praxis', 'arzt', 'zahnarzt', 'orthopäde', 'hausarzt', 'facharzt', 'krankenhaus', 'klinik', 'orthopaede']),
        Subcategory(id: 'gesundheit_therapie', name: 'Therapie / Fitness', keywords: ['physiotherapie', 'psychotherapie', 'heilpraktiker', 'massage', 'osteopathie', 'ergotherapie']),
        Subcategory(id: 'gesundheit_krankenversicherung', name: 'Krankenversicherung', keywords: ['krankenkasse', 'aok', 'tk', 'techniker krankenkasse', 'barmer', 'dak', 'ikk', 'knappschaft', 'private krankenversicherung', 'pkv']),
      ],
    ),
    Category(
      id: 'bank',
      name: 'Bank & Gebühren',
      type: CategoryType.expense,
      colorValue: AppleColors.gray3.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'bank_gebuehren',
          name: 'Kontoführung / Gebühren',
          keywords: ['kontoführung', 'kontoführungsgebühr', 'entgelt', 'dispozinsen', 'überziehungszinsen', 'kreditkartengebühr', 'auslandseinsatzentgelt', 'buchungsgebühr', 'jahresgebühr karte', 'kontofuehrung', 'kontofuehrungsgebuehr', 'ueberziehungszinsen', 'kreditkartengebuehr', 'buchungsgebuehr', 'jahresgebuehr karte'],
        ),
        Subcategory(id: 'bank_zinsen', name: 'Kredit / Zinsen', keywords: ['zinsen', 'darlehen', 'ratenkredit', 'kreditrate', 'tilgung', 'baufinanzierung']),
      ],
    ),
    Category(
      id: 'bildung',
      name: 'Bildung & Kinder',
      type: CategoryType.expense,
      colorValue: AppleColors.yellow.toARGB32(),
      subcategories: [
        Subcategory(id: 'bildung_kinderbetreuung', name: 'Kita / Schule', keywords: ['kita', 'kindergarten', 'kindertagesstätte', 'schule', 'hort', 'elternbeitrag', 'schulbedarf', 'kindertagesstaette']),
        Subcategory(id: 'bildung_kurse', name: 'Kurse / Nachhilfe', keywords: ['nachhilfe', 'udemy', 'coursera', 'lernplattform', 'sprachkurs', 'duolingo', 'studiengebühren', 'studiengebuehren']),
        Subcategory(id: 'bildung_spielzeug', name: 'Spielzeug / Baby', keywords: ['spielzeug', 'toys"r"us', 'baby-walz', 'windeln.de', 'babyausstattung']),
      ],
    ),
    Category(
      id: 'spenden',
      name: 'Spenden & Kirche',
      type: CategoryType.expense,
      colorValue: AppleColors.brownDark.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'spenden_organisationen',
          name: 'Spenden',
          keywords: ['spende', 'unicef', 'brot für die welt', 'misereor', 'caritas', 'diakonie', 'rotes kreuz', 'drk', 'ärzte ohne grenzen', 'welthungerhilfe', 'greenpeace', 'wwf', 'brot fuer die welt', 'aerzte ohne grenzen'],
        ),
        Subcategory(id: 'spenden_kirche', name: 'Kirchensteuer / Gemeinde', keywords: ['kirchensteuer', 'kirchengemeinde', 'kirchenbeitrag']),
      ],
    ),
    Category(
      id: 'haustiere',
      name: 'Haustiere',
      type: CategoryType.expense,
      colorValue: AppleColors.tealDark.toARGB32(),
      subcategories: [
        Subcategory(id: 'haustiere_tierarzt', name: 'Tierarzt', keywords: ['tierarzt', 'tierklinik', 'tierärztliche', 'tieraerztliche']),
        Subcategory(id: 'haustiere_zubehoer', name: 'Futter / Zubehör', keywords: ['fressnapf', 'zooplus', 'futterhaus', 'zoohandlung', 'tierfutter']),
      ],
    ),
    Category(
      id: 'sonstiges',
      name: 'Sonstiges',
      type: CategoryType.expense,
      colorValue: AppleColors.gray2.toARGB32(),
      subcategories: [
        Subcategory(id: 'sonstiges_diverses', name: 'Diverses', keywords: []),
      ],
    ),
    // Used exclusively by the transfer flow on the Konten screen - not meant
    // to be picked manually, so the transaction/import forms filter it out.
    Category(
      id: 'umbuchung',
      name: 'Umbuchung',
      type: CategoryType.expense,
      colorValue: AppleColors.gray.toARGB32(),
    ),
  ];
}
