import 'package:flutter/foundation.dart';

class AppSession extends ChangeNotifier {
  String? orgId;
  String role = 'cashier';

  bool get ready => orgId != null;
  bool get canManageCatalog => role == 'admin' || role == 'manager';
  bool get canViewReports => role == 'admin' || role == 'manager';
  bool get canManageCustomers => role == 'admin' || role == 'manager';

  void setProfile({required String orgId, required String role}) {
    this.orgId = orgId;
    this.role = role;
    notifyListeners();
  }

  void clear() {
    orgId = null;
    role = 'cashier';
    notifyListeners();
  }
}

final session = AppSession();
