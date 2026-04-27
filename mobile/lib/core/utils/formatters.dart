import 'package:intl/intl.dart';

final _tl = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);
final _date = DateFormat('dd.MM.yyyy', 'tr_TR');

String formatCurrency(num value) => _tl.format(value);
String formatDate(DateTime value) => _date.format(value);
