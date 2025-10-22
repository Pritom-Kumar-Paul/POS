import 'package:intl/intl.dart';

final _moneyFmt = NumberFormat.decimalPattern();

String money(int v) => '৳${_moneyFmt.format(v)}';

String fmtDate(DateTime d) => DateFormat('yyyy-MM-dd HH:mm').format(d);
