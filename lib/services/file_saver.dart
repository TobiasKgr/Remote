/// Lets the user choose where to save [content] as a text file (used for
/// backup export). Returns a location descriptor on success (a file path on
/// desktop/mobile, the file name on web), or `null` if the user cancelled.
///
/// Platform differences in `file_picker`'s `saveFile` are substantial enough
/// (Android/iOS require `bytes`, desktop ignores/rejects them and instead
/// returns a path to write to, web doesn't implement it at all) that this is
/// split into platform-specific implementations picked via conditional
/// export.
library;

export 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart';
