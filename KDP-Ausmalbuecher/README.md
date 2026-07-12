# KDP-Ausmalbuch-Produktionssystem

Vollautomatisiertes System zur Erstellung von Ausmalbüchern für Amazon KDP
(Taschenbuch), gebaut mit Claude + Canva.

## Ordnerstruktur

```
KDP-Ausmalbuecher/
├── README.md                  ← Diese Übersicht
├── SYSTEM.md                  ← Regeln, Formeln, Checklisten (das "Betriebssystem")
├── Serienplanung.md           ← Langfristige Serien- und Themenplanung
└── Band-01-Baustelle/         ← Ein Ordner pro Band
    ├── 01_Themenwahl.md       ← Thema, Zielgruppe, Begründung, Motiv-Cluster
    ├── 02_Motivliste.md       ← Alle 50 Motive mit Beschreibung + Canva-Prompt
    ├── 03_canva_bulk_import.csv ← Bulk-Import-Datei für Canva (Massenerstellung)
    ├── 04_KDP_Formularfelder.md ← Alle KDP-Eingabefelder, fertig ausgefüllt
    ├── 05_Cover.md            ← Cover-Maße, Frontcover-Prompt, Backcover-Text
    └── 06_Format_und_Export.md ← Innenlayout, Maße, Export- und Dateiregeln
```

## Workflow pro Band (7 Schritte)

1. **Themenwahl** — automatisch nach Markttrend, Saison, Wettbewerb → `01_Themenwahl.md`
2. **Motive erzeugen** — 50 Motive in 5 Clustern à 10 → `02_Motivliste.md`
3. **Bilder generieren** — CSV in Canva Bulk-Erstellung / KI-Bildgenerator laden → `03_canva_bulk_import.csv`
4. **Innenteil bauen** — Canva-Dokument 8,5 × 11 Zoll, 1 Motiv pro Seite, Export „PDF Druck"
5. **Cover bauen** — Maße aus `05_Cover.md`, Export „PDF Druck"
6. **KDP-Formular ausfüllen** — 1:1 aus `04_KDP_Formularfelder.md` übernehmen
7. **Veröffentlichen** — Vorschau prüfen, freigeben, nächsten Band aus `Serienplanung.md` starten

## Lokale Ablage (Windows)

Dieses Repository ist der zentrale Speicherort. Um die Dateien lokal unter
`C:\Users\t.paschedag\Desktop\Mobile App Entwicklung\` zu haben:

```
cd "C:\Users\t.paschedag\Desktop\Mobile App Entwicklung"
git clone https://github.com/TobiasKgr/Remote.git --branch claude/kdp-coloring-book-automation-ldopun
```

Oder den Ordner `KDP-Ausmalbuecher` über GitHub als ZIP herunterladen und dort entpacken.

## Status

| Band | Thema | Status | Erstellt |
|------|-------|--------|----------|
| 1 | Baustellen-Fahrzeuge („Mein Baustellen-Malbuch") | ✅ Komplett — bereit für Canva-Produktion | 2026-07-12 |
| 2 | Feuerwehr | 🔜 Geplant (siehe Serienplanung) | — |
