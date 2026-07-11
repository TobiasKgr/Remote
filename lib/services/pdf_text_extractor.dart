import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Shared helper to pull raw text out of a PDF, used by both the bank
/// statement importer and the salary slip importer.
Future<String> extractPdfText(Uint8List bytes) async {
  final document = PdfDocument(inputBytes: bytes);
  try {
    return PdfTextExtractor(document).extractText();
  } finally {
    document.dispose();
  }
}
