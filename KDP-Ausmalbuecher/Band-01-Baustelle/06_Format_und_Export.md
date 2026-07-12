# Band 1 — Format & Export-Spezifikation

**Buch:** Mein Baustellen-Malbuch · **Trim:** 8,5 × 11 Zoll · **Seiten:** 54

---

## Innenteil (Interior PDF)

### Seitengröße & Layout

| Parameter | Wert | Konversion |
|-----------|------|------------|
| **Trim-Größe** | 8,5 × 11 Zoll | 21,6 × 27,9 cm |
| **Pixel (@ 300 DPI)** | 2550 × 3300 px | — |
| **Auflösung** | 300 DPI | Pflicht für KDP |
| **Farbe** | Schwarz & Weiß | Line-Art nur |

### Ränder & Sicherheitszone

| Bereich | Wert | Konvertierung |
|---------|------|---------------|
| **Weißer Rand (außen)** | 0,75 Zoll | 226,8 px ≈ 227 px |
| **Motiv-Spielbereich** | 7 × 9,5 Zoll (ca.) | 2097 × 2850 px (ca.) |
| **Beschnitt-Zone** | keiner (Motive laufen nicht bis Rand) | — |

> **Hinweis:** 0,75 Zoll Rand erfüllt KDP-Anforderung von mind. 0,5 Zoll.

### Struktur (54 Seiten)

```
Seite 1:   Titelseite
           "Mein Baustellen-Malbuch"
           "Dieses Buch gehört: _______________"
           (Feld zum Eintragen des Namens)

Seiten 2–51:   Die 50 Motive (page_01 bis page_50)
           Ein Motiv pro Seite, zentriert
           Große Flächen, dicke Linien
           Schwarz-Weiß Line-Art

Seite 52:  Impressum & Copyright
           © 2026 Tobias Paschedag
           Illustrationen: KI-generiert
           Design: Claude + Canva
           Hergestellt mit Amazon KDP
           www.amazon.de

Seite 53:  Stifte-Testseite
           "Teste deine Stifte hier!"
           Kleine Testfelder für verschiedene Farben
           (Optional, aber beliebt bei Kindern)

Seite 54:  Abschluss-Urkunde
           "Glückwunsch! 🎉"
           "Du hast alle Ausmalbilder fertig!"
           Platz für Unterschrift/Datum
           Motivierendes Abschluss-Design
```

---

## Bildformat für einzelne Seiten

### Dateiformat & Nomenklatur

| Parameter | Wert |
|-----------|------|
| **Dateiname** | `page_01.png, page_02.png, … page_50.png` |
| **Format** | PNG (24-bit RGB, obwohl s/w) oder TIFF (unkomprimiert) |
| **Auflösung** | 300 DPI |
| **Größe pro Bild** | 2550 × 3300 px (8,5 × 11 Zoll) |
| **Farbraum** | RGB (aber nur Schwarz & Weiß) |
| **Hintergrund** | Weiß (#FFFFFF) |
| **Randbearbeitung** | Weißer Rand 0,75" rings herum (bereits in generierten Bildern enthalten) |

### Erzeugung (Canva / KI-Bildgenerator)

1. **KI-Bildgenerator** (DALL·E, Ideogram, Midjourney, etc.) oder
   **Canva Magic Media:**
   - Prompt aus CSV `03_canva_bulk_import.csv` verwenden
   - Größe: 2550 × 3300 px (oder hochskalieren)
   - Format: PNG exportieren

2. **Nachbearbeitung (optional):**
   - Kontrastschwelle erhöhen (damit Linien knackig schwarz sind)
   - Rauscheentfernung (falls nötig)
   - Größe auf exakt 2550 × 3300 px Zuschneiden
   - Hintergrund zu reinem Weiß ändern (falls grau)

3. **Archivieren:**
   - Alle 50 PNGs im Ordner `Band-01-Baustelle/images/` speichern
   - Benennungskonvention: `page_01.png … page_50.png`

---

## PDF-Erstellung (Canva oder externe PDF-Software)

### Canva-Methode (empfohlen)

1. **Neues Dokument anlegen:**
   - Größe: **8,5 × 11 Zoll**
   - 54 Seiten
   - Farbe: Schwarz-Weiß

2. **Seiten füllen:**
   - Seite 1: Titelseite (Text + optional Grafikband oben/unten)
   - Seiten 2–51: Einzelne Motiv-PNG einfügen, zentrieren, auf 7 × 9,5 Zoll skalieren
   - Seite 52–54: Zusatzseiten (siehe oben)

3. **Exportieren:**
   - Datei → Herunterladen → **PDF Druck**
   - 300 DPI bestätigen
   - Beschnitt-Markierungen: **AUS** (KDP braucht keine Markierungen)
   - Dateiname: `baustelle_band1_interior.pdf`

### LibreOffice / LaTeX-Methode (Alternative)

Falls Canva nicht verfügbar:

1. **LibreOffice Writer:**
   - Seite: 8,5 × 11 Zoll, Ränder 0,75" links/rechts/oben/unten
   - Jede Motiv-PNG auf seine Seite
   - Zentriert, skaliert auf max. Spielbereich

2. **PDF-Export:**
   - Datei → Export als PDF
   - Auflösung: 300 DPI
   - PDF Standard: wählen (nicht „Hybrid PDF")

---

## Qualitäts-Checkliste (vor Upload zu KDP)

### Bildqualität

- [ ] Alle 50 Motive: Schwarz-Weiß Line-Art (keine Graustufen)?
- [ ] Linien durchgehend geschlossen (keine offenen Striche)?
- [ ] Linien stark genug (mind. 1–2 pt), nicht zu dünn?
- [ ] Motiv zentriert auf der Seite (weißer Rand 0,75" allseits)?
- [ ] Hintergrund rein weiß (#FFFFFF)?
- [ ] Keine Artefakte, Rauschen oder Komprimierungsfehler?

### Datei-Struktur

- [ ] PDF: 54 Seiten?
- [ ] Seite 1: Titelseite (lesbar)?
- [ ] Seiten 2–51: Motive page_01 bis page_50?
- [ ] Seiten 52–54: Zusatzseiten vorhanden?
- [ ] PDF-Dateigröße: 15–50 MB (typisch für s/w Bild-PDFs)?

### KDP-Vorschau

- [ ] PDF mit KDP-Previewer öffnen
- [ ] Alle 54 Seiten sichtbar?
- [ ] Keine Warnungen (roter/gelber Banner)?
- [ ] Text lesbar & korrekt positioniert (Titelseite, Impressum)?
- [ ] Ränder OK (nichts abgeschnitten)?
- [ ] Schwarze Linien kontrastreich?

---

## Datei-Architektur (Endspeicherung)

```
KDP-Ausmalbuecher/
├── Band-01-Baustelle/
│   ├── 01_Themenwahl.md
│   ├── 02_Motivliste.md
│   ├── 03_canva_bulk_import.csv
│   ├── 04_KDP_Formularfelder.md
│   ├── 05_Cover.md
│   ├── 06_Format_und_Export.md  ← Du bist hier
│   ├── images/
│   │   ├── page_01.png
│   │   ├── page_02.png
│   │   └── … page_50.png
│   └── exports/
│       ├── baustelle_band1_interior.pdf  ← Innenteil-PDF
│       └── baustelle_band1_cover.pdf     ← Cover-PDF
│
└── Serienplanung.md
```

---

## Production Workflow (Step-by-Step)

### Phase 1: Bild-Erzeugung (30–60 min)
1. CSV `03_canva_bulk_import.csv` öffnen
2. Jeden Prompt in KI-Generator geben (oder Canva Bulk-Upload)
3. Bilder als `page_01.png … page_50.png` speichern (2550 × 3300 px, 300 DPI)
4. Bilder-Ordner in `images/` archivieren

### Phase 2: Innenteil-PDF (20–40 min)
1. Canva: Dokument 8,5 × 11 Zoll, 54 Seiten
2. Seite 1: Titelseite gestalten
3. Seiten 2–51: PNG-Bilder einfügen (zentriert, skaliert)
4. Seiten 52–54: Zusatzseiten (Text)
5. PDF Druck exportieren → `exports/baustelle_band1_interior.pdf`
6. Mit KDP-Previewer überprüfen

### Phase 3: Cover-PDF (15–30 min)
1. Canva: Dokument 5212 × 3375 px
2. Frontcover & Backcover gestalten
3. Barcode-Bereich freihalten (rechts unten)
4. PDF Druck exportieren → `exports/baustelle_band1_cover.pdf`

### Phase 4: KDP-Upload (10 min pro Formular)
1. KDP.amazon.de anmelden (oder .com für international)
2. „Neues Taschenbuch" → Formular ausfüllen (aus `04_KDP_Formularfelder.md`)
3. Innenteil-PDF hochladen
4. Cover-PDF hochladen
5. Vorschau (Previewer) prüfen
6. Preis setzen (10,99 € empfohlen)
7. **Veröffentlichen**

---

## Speicherplatz-Rechnung

| Datei | Größe (ca.) |
|-------|-------------|
| 50 × PNG @ 2550 × 3300 px, 300 DPI | 50 × 5–8 MB = 250–400 MB |
| Innenteil-PDF (54 Seiten) | 20–40 MB |
| Cover-PDF | 3–5 MB |
| **Gesamt** | **275–445 MB** |

> Git-Hinweis: PNGs sollten `.gitignore` hinzugefügt werden (nicht ins Repository),
> nur PDFs & CSVs / Markdown-Dokumente versionieren.

---

**Zuletzt aktualisiert:** 2026-07-12
