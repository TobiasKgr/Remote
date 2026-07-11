import 'package:intl/intl.dart';

final currencyFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
final dateFormat = DateFormat('dd.MM.yyyy', 'de_DE');
final monthYearFormat = DateFormat('MMMM yyyy', 'de_DE');

const monthNamesDe = [
  'Januar',
  'Februar',
  'März',
  'April',
  'Mai',
  'Juni',
  'Juli',
  'August',
  'September',
  'Oktober',
  'November',
  'Dezember',
];
