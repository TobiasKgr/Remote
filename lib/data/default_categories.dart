import 'package:flutter/material.dart';

import '../models/category.dart';

/// Seed data shown on first launch. Users can freely rename, extend or
/// delete these afterwards via the Categories screen.
List<Category> buildDefaultCategories() {
  return [
    Category(
      id: 'income',
      name: 'Einkommen',
      type: CategoryType.income,
      colorValue: Colors.green.toARGB32(),
      subcategories: [
        Subcategory(id: 'income_gehalt', name: 'Gehalt', keywords: ['gehalt', 'lohn', 'lohnzahlung']),
        Subcategory(id: 'income_bonus', name: 'Bonus / Prämie', keywords: ['bonus', 'prämie']),
        Subcategory(id: 'income_other', name: 'Sonstige Einnahmen', keywords: []),
      ],
    ),
    Category(
      id: 'wohnen',
      name: 'Wohnen',
      type: CategoryType.expense,
      colorValue: Colors.brown.toARGB32(),
      subcategories: [
        Subcategory(id: 'wohnen_miete', name: 'Miete', keywords: ['miete', 'kaltmiete']),
        Subcategory(id: 'wohnen_nebenkosten', name: 'Nebenkosten', keywords: ['nebenkosten', 'hausgeld']),
        Subcategory(id: 'wohnen_energie', name: 'Strom / Gas', keywords: ['stadtwerke', 'strom', 'gas', 'energie']),
      ],
    ),
    Category(
      id: 'fixkosten',
      name: 'Fixkosten & Abos',
      type: CategoryType.expense,
      colorValue: Colors.indigo.toARGB32(),
      subcategories: [
        Subcategory(
          id: 'fixkosten_streaming',
          name: 'Streaming-Abos',
          keywords: ['netflix', 'spotify', 'disney', 'amazon prime', 'apple tv', 'youtube premium', 'dazn'],
        ),
        Subcategory(id: 'fixkosten_mobilfunk', name: 'Mobilfunk / Internet', keywords: ['telekom', 'vodafone', 'o2', 'mobilfunk', 'internet']),
        Subcategory(id: 'fixkosten_versicherung', name: 'Versicherungen', keywords: ['versicherung', 'allianz', 'huk', 'axa']),
        Subcategory(id: 'fixkosten_mitgliedschaft', name: 'Mitgliedschaften', keywords: ['fitnessstudio', 'mitgliedschaft', 'verein']),
      ],
    ),
    Category(
      id: 'lebensmittel',
      name: 'Lebensmittel',
      type: CategoryType.expense,
      colorValue: Colors.orange.toARGB32(),
      subcategories: [
        Subcategory(id: 'lebensmittel_supermarkt', name: 'Supermarkt', keywords: ['rewe', 'edeka', 'aldi', 'lidl', 'kaufland', 'netto']),
        Subcategory(id: 'lebensmittel_restaurant', name: 'Restaurant / Café', keywords: ['restaurant', 'café', 'bar', 'imbiss']),
      ],
    ),
    Category(
      id: 'mobilitaet',
      name: 'Mobilität',
      type: CategoryType.expense,
      colorValue: Colors.blueGrey.toARGB32(),
      subcategories: [
        Subcategory(id: 'mobilitaet_tanken', name: 'Tanken', keywords: ['tankstelle', 'aral', 'shell', 'esso', 'jet']),
        Subcategory(id: 'mobilitaet_oepnv', name: 'ÖPNV', keywords: ['bahn', 'bvg', 'vvo', 'mvv', 'ticket']),
        Subcategory(id: 'mobilitaet_kfz', name: 'KFZ-Versicherung / Werkstatt', keywords: ['kfz', 'werkstatt', 'tüv']),
        Subcategory(id: 'mobilitaet_firmenwagen', name: 'Firmenwagen', keywords: ['firmenwagen', 'leasingrate']),
      ],
    ),
    Category(
      id: 'freizeit',
      name: 'Freizeit & Hobby',
      type: CategoryType.expense,
      colorValue: Colors.purple.toARGB32(),
      subcategories: [
        Subcategory(id: 'freizeit_hobby', name: 'Hobby', keywords: []),
        Subcategory(id: 'freizeit_urlaub', name: 'Urlaub', keywords: ['reise', 'hotel', 'flug']),
      ],
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      type: CategoryType.expense,
      colorValue: Colors.pink.toARGB32(),
      subcategories: [
        Subcategory(id: 'shopping_kleidung', name: 'Kleidung', keywords: ['zalando', 'h&m', 'zara']),
        Subcategory(id: 'shopping_elektronik', name: 'Elektronik', keywords: ['media markt', 'saturn', 'amazon']),
      ],
    ),
    Category(
      id: 'gesundheit',
      name: 'Gesundheit',
      type: CategoryType.expense,
      colorValue: Colors.teal.toARGB32(),
      subcategories: [
        Subcategory(id: 'gesundheit_apotheke', name: 'Apotheke', keywords: ['apotheke']),
        Subcategory(id: 'gesundheit_arzt', name: 'Arzt', keywords: ['praxis', 'arzt']),
      ],
    ),
    Category(
      id: 'sonstiges',
      name: 'Sonstiges',
      type: CategoryType.expense,
      colorValue: Colors.grey.toARGB32(),
      subcategories: [
        Subcategory(id: 'sonstiges_diverses', name: 'Diverses', keywords: []),
      ],
    ),
  ];
}
