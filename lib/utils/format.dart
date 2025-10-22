import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String fmtDate(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);

String fmtMoney(BuildContext context, num amount) {
  final locale = Localizations.localeOf(context).toString();
  final f = NumberFormat.currency(
    locale: locale,
    symbol: '৳',
    decimalDigits: 0,
  );
  return f.format(amount);
}
