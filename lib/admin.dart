import 'package:firebase_auth/firebase_auth.dart';

/// KEEP THESE LOWERCASE.
const Set<String> adminEmails = {
  'gonzales.amanda92@yahoo.com',
  'nyari.app@gmail.com',
};

bool get isCurrentUserAdmin {
  final email = FirebaseAuth.instance.currentUser?.email?.toLowerCase();
  return email != null && adminEmails.contains(email);
}
