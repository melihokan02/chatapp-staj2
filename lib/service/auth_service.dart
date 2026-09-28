import 'package:flutter/foundation.dart';
import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/service/databases_services.dart';
import 'package:chatapp/service/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseAuth get firebaseAuth => _auth;

  Future<String?> registerWithEmailAndPasswordDetailed(
      String fullName, String email, String password, String username) async {
    try {
      final UserCredential result =
          await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) return 'unknown';

      final isUnique = await DatabaseService(uid: user.uid).checkUsernameUnique(username);
      if (!isUnique) {
        await user.delete();
        return 'username-taken';
      }

      await user.updateDisplayName(fullName);
      await DatabaseService(uid: user.uid).updateUserData(fullName, email, username);

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }

      await HelperFunction.saveUserLoggedInStatus(true);
      await HelperFunction.saveUserNameSF(fullName);
      await HelperFunction.saveUserEmailSF(email);

      debugPrint('Register success: ${user.uid}');
      return null; 
    } on FirebaseAuthException catch (e) {
      debugPrint('Register failed: ${e.code}');
      return e.code;
    }
  }

  Future<String?> signInWithEmailAndPasswordDetailed(
      String email, String password) async {
    try {
      final UserCredential result =
          await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = result.user;
      if (user == null) return 'unknown';

      await HelperFunction.saveUserLoggedInStatus(true);
      await HelperFunction.saveUserEmailSF(email);

      final String? userName = user.displayName;
      if (userName != null && userName.isNotEmpty) {
        await HelperFunction.saveUserNameSF(userName);
      } else {
        final Map<String, dynamic>? userData =
            await DatabaseService(uid: user.uid).getUserData();
        final String? fullName = userData?['fullName'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          await HelperFunction.saveUserNameSF(fullName);
        }
      }

      debugPrint('Login success: ${user.uid}');
      return null; 
    } on FirebaseAuthException catch (e) {
      debugPrint('Login failed: ${e.code}');
      return e.code;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return null; 
    } on FirebaseAuthException catch (e) {
      return e.code;
    } catch (e) {
      return 'unknown';
    }
  }

  Future<bool> registerWithEmailAndPassword(
      String fullName, String email, String password) async {
    final result = await registerWithEmailAndPasswordDetailed(
        fullName, email, password, '');
    return result == null;
  }

  Future<bool> signInWithEmailAndPassword(
      String email, String password) async {
    final result =
        await signInWithEmailAndPasswordDetailed(email, password);
    return result == null;
  }

  Future<void> signOut() async {
    final email = firebaseAuth.currentUser?.email;
    if (email != null) {
      await NotificationService().clearFcmToken(email);
    }
    await firebaseAuth.signOut();
    await HelperFunction.saveUserLoggedInStatus(false);
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await firebaseAuth.currentUser?.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.code;
    }
  }
}
