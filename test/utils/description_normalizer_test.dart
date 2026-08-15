import 'package:finance_analyzer/utils/description_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('entfernt Ziffern und Interpunktion, vereinheitlicht Groß-/Kleinschreibung', () {
    expect(normalizeDescription('REWE SAGT DANKE 3141'), normalizeDescription('REWE SAGT DANKE 8827'));
    expect(normalizeDescription('Netflix.com Rechnung 1234'), 'netflix com rechnung');
  });

  test('unterschiedlicher Text normalisiert nicht auf denselben Schlüssel', () {
    expect(normalizeDescription('Netflix.com Rechnung 1234'), isNot(normalizeDescription('Spotify Premium')));
  });

  test('leere/nur-Ziffern-Beschreibung normalisiert zu einem leeren String', () {
    expect(normalizeDescription('123456'), isEmpty);
    expect(normalizeDescription(''), isEmpty);
  });
}
