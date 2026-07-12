import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<String?> saveTextFile({required String fileName, required String content}) async {
  final bytes = Uint8List.fromList(utf8.encode(content));

  if (Platform.isAndroid || Platform.isIOS) {
    // file_picker writes the file itself on mobile and requires bytes.
    return FilePicker.platform.saveFile(fileName: fileName, bytes: bytes);
  }

  // On desktop, file_picker's saveFile only returns a chosen path (it
  // ignores `bytes` on Windows/Linux and throws if given on macOS) - the
  // caller has to write the file itself.
  final path = await FilePicker.platform.saveFile(
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (path == null) return null;

  final resolvedPath = path.toLowerCase().endsWith('.json') ? path : '$path.json';
  await File(resolvedPath).writeAsBytes(bytes);
  return resolvedPath;
}
