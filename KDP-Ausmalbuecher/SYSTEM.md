# SYSTEM.md — Regeln & Formeln des Produktionssystems

Dieses Dokument ist das „Betriebssystem" aller Bände. Jeder neue Band wird
nach diesen Regeln erzeugt, damit alle Bücher konsistent und KDP-konform sind.

---

## 1. Automatische Themenwahl

Bewertung jedes Themenkandidaten (je 1–5 Punkte):

| Kriterium | Gewicht |
|-----------|---------|
| Nachfrage / Suchvolumen (Amazon.de) | ×3 |
| Wettbewerbsniveau (niedrig = mehr Punkte) | ×3 |
| Evergreen-Faktor (ganzjährig verkäuflich) | ×2 |
| Motivvielfalt (reicht es für 50+ Motive und Folgebände?) | ×2 |
| Geschenk-Eignung | ×1 |
| Saisonaler Bonus (nur bei Spezialbänden) | ×1 |

Regeln:
- Kein Thema zweimal hintereinander aus derselben Themenwelt.
- Pro Kalenderjahr max. 2 saisonale Spezialbände (Weihnachten, Ostern).
- Jedes Thema muss mind. 3 Folgebände tragen können (Serienfähigkeit).

## 2. Schwierigkeitsstufen

| Stufe | Merkmale | Lesealter (KDP) | Linienstärke |
|-------|----------|-----------------|--------------|
| Leicht | große Flächen, dicke Linien, einfache Formen, 1 Hauptobjekt | 3–8 | sehr dick (ca. 4–6 pt Wirkung) |
| Mittel | mehr Details, klar getrennte Bereiche, kleine Szenen | 6–10 | dick (ca. 3–4 pt) |
| Komplex | feine Muster, Mandala-Elemente, detaillierte Figuren | 9–99 (inkl. Erwachsene) | mittel (ca. 2 pt) |

Wahl: Zielgruppe des Themas → Stufe. Innerhalb eines Buches dürfen einzelne
Motive eine halbe Stufe abweichen (Abwechslung), das Buch trägt die Hauptstufe.

## 3. Motiv-Struktur

- **50 Motive pro Buch**, aufgeteilt in **5 Cluster à 10 Motive**.
- Pro Motiv: Dateiname, deutsche Beschreibung, englischer Canva-/KI-Prompt,
  Schwierigkeitsgrad, Cluster.
- Letztes Motiv (page_50) = „Finale-Motiv" (Gruppenbild / Feier-Szene).

### Bildstil-Regeln (gelten für jeden Prompt)

Standard-Suffix, das an jeden Motiv-Prompt angehängt wird:

```
cute children's coloring book style, thick black outlines, simple shapes,
black and white line art, no shading, no gray, no color, white background
```

- Schwarz-weiß Line-Art, keine Graustufen, keine Farbflächen
- Keine Hintergründe (Ausnahme: einfache Bodenlinie bei Szenen-Motiven)
- Kinderfreundlich, freundliche Gesichter
- 300 DPI

## 4. Taschenbuch-Format (fix)

| Parameter | Wert |
|-----------|------|
| Trim-Größe | **8,5 × 11 Zoll** (Standard) — Alternative: 8 × 10 Zoll |
| Innenteil | Schwarz-weiß, weißes Papier |
| Auflösung | 300 DPI |
| Innenseite in Pixel | 2550 × 3300 px (8,5 × 11) |
| Weißer Rand ums Motiv | mind. 0,75 Zoll (≈ 1,9 cm) rundum — erfüllt KDP-Mindestränder |
| Beschnitt (Innenteil) | keiner (Motive laufen nicht bis zum Rand) |
| Layout | 1 Seite = 1 Motiv, zentriert |

### Seitenanzahl (Standard-Modus laut Spezifikation)

```
Gesamtseiten = 50 Motive + 4 Zusatzseiten = 54 Seiten
```

Zusatzseiten: ① Titelseite („Dieses Buch gehört …"), ② Impressum/Copyright,
③ Stifte-Testseite, ④ Abschluss-Seite (Urkunde „Geschafft!").

> **Profi-Variante (optional, empfohlen bei Filzstift-Zielgruppe):** jedes
> Motiv einseitig drucken (Rückseite leer, verhindert Durchdrücken):
> 50 Motive + 50 Leerseiten + 4 Zusatzseiten = **104 Seiten**. Dann Rückenbreite
> und Cover neu berechnen (Formel unten). Beide Varianten sind KDP-konform
> (Minimum 24 Seiten ✓).

## 5. Cover-Berechnung (Formeln)

```
Rückenbreite (Zoll)  = Seitenanzahl × 0.002252        (weißes Papier, s/w)
Coverbreite  (Zoll)  = 0.125 + Trimbreite + Rückenbreite + Trimbreite + 0.125
Coverhöhe    (Zoll)  = Trimhöhe + 0.125 + 0.125
Pixel                = Zoll × 300 (aufrunden)
```

> ⚠️ Korrektur zur ursprünglichen Spezifikation: KDP verlangt **0,125 Zoll
> Beschnitt pro Kante**, also 0,25 Zoll gesamt in Breite UND Höhe — nicht
> 0,125 gesamt. Diese Formel hier ist die KDP-konforme.

Weitere Regeln:
- **Rückentext erst ab 79 Seiten erlaubt** → bei 54 Seiten: Buchrücken nur Farbe/Muster, keine Schrift.
- Sicherheitsabstand Text/Barcode: 0,25 Zoll von jeder Trim-Kante; KDP platziert den Barcode unten rechts auf dem Backcover (2 × 1,2 Zoll freihalten).
- Export: „PDF Druck" (Canva), 300 DPI, Beschnittzugabe aktivieren.

## 6. Canva-Produktionslogik

1. **Bulk-Import:** `03_canva_bulk_import.csv` (Standard-CSV mit Kopfzeile
   `filename,prompt,description,difficulty,cluster`) in Canva
   „Massenerstellung" laden oder Prompts einzeln in einen KI-Bildgenerator
   (Canva Magic Media / DALL·E / Ideogram) geben.
2. Generierte Bilder als `page_01.png … page_50.png` (300 DPI) benennen.
3. Canva-Dokument **8,5 × 11 Zoll** anlegen → Seiten in Reihenfolge einfügen,
   Motiv zentriert, Ränder einhalten.
4. Export Innenteil: **Datei → Herunterladen → PDF Druck** (kein Beschnitt).
5. Cover-Dokument in exakter Covergröße anlegen → Export **PDF Druck** mit Beschnitt.

## 7. Dateibenennung (fix)

| Datei | Muster | Beispiel Band 1 |
|-------|--------|-----------------|
| Innenteil | `themenwelt_bandN_interior.pdf` | `baustelle_band1_interior.pdf` |
| Cover | `themenwelt_bandN_cover.pdf` | `baustelle_band1_cover.pdf` |
| Einzelseiten | `page_01.png … page_50.png` | `page_01.png` |
| Band-Ordner | `Band-NN-Themenwelt/` | `Band-01-Baustelle/` |

## 8. KDP-Formular — feste Standardwerte

| Feld | Standard |
|------|----------|
| Sprache | Deutsch |
| Auflage | 1 |
| Autor | Tobias Paschedag (oder Pseudonym) |
| Mitwirkende | keine Pflichtangabe; intern: Illustration KI-generiert, Design Claude + Canva |
| KI-Offenlegung (KDP-Pflichtfrage) | „Ja — Bilder: mit KI-Werkzeugen erstellt" |
| Veröffentlichungsrechte | „Ich bin Inhaber des Urheberrechts …" |
| Sexuell explizite Inhalte | Nein |
| Primärer Shop | Amazon.de (Empfehlung für deutschsprachige Bücher; Spez.-Vorgabe Amazon.com ebenfalls möglich) |
| Bücher mit wenig Inhalt (Low Content) | **Ja** |
| Großdruck | Nein |
| Vorherige Veröffentlichung | „Mein Buch wurde zuvor nicht veröffentlicht." |
| Erscheinungsdatum | Tagesdatum der Veröffentlichung |
| Keywords | 7 Stück, je max. 50 Zeichen |
| Kategorien | 3 Stück, passend zur Themenwelt |

## 9. Serien-Logik (Kurzfassung)

- Serienname: **„Kleine Entdecker – Ausmalwelten"**, fortlaufende Bandnummern.
- Pro Themenwelt sind Spin-offs möglich: Altersstufen-Version (komplexere
  Variante „ab 6"), saisonaler Spezialband, Lern-Variante (Malen + erste Wörter).
- Details und Roadmap: `Serienplanung.md`.

## 10. Qualitäts-Checkliste vor Veröffentlichung

- [ ] 54 Seiten im PDF? (bzw. 104 bei Profi-Variante)
- [ ] Alle Motive s/w, keine Graustufen, Linien durchgehend geschlossen?
- [ ] Ränder ≥ 0,75 Zoll, nichts im Beschnitt?
- [ ] Cover-PDF in exakt berechneter Größe, Rücken ohne Text (< 79 Seiten)?
- [ ] Titel auf Cover = Titel im KDP-Formular (exakt)?
- [ ] 7 Keywords ≤ 50 Zeichen, keine Markennamen?
- [ ] KI-Offenlegung im Formular beantwortet?
- [ ] KDP-Vorschau (Previewer) ohne Warnungen?
