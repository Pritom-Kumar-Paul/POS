import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_paths.dart';

class UserProfile {
  final String uid;
  final String role;
  final String orgId;
  final String? email;

  UserProfile({
    required this.uid,
    required this.role,
    required this.orgId,
    this.email,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> m) {
    return UserProfile(
      uid: uid,
      role: (m['role'] as String?) ?? 'cashier',
      orgId: (m['orgId'] as String?) ?? uid,
      email: m['email'] as String?,
    );
  }
}

class UserRepository {
  Future<UserProfile> ensureProfile(User user) async {
    final ref = FF.userDoc(user.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'role': 'admin',
        'orgId': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return UserProfile(
        uid: user.uid,
        role: 'admin',
        orgId: user.uid,
        email: user.email,
      );
    } else {
      return UserProfile.fromMap(
        user.uid,
        snap.data()! as Map<String, dynamic>,
      );
    }
  }
}
