import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Please enter your email and password.');
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('Login succeeded but no Firebase user was returned.');
      }

      return {
        'uid': user.uid,
        'email': user.email ?? normalizedEmail,
        'message': 'Login successful',
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();

    if (normalizedName.isEmpty) {
      throw Exception('Please enter your name.');
    }

    if (normalizedEmail.isEmpty) {
      throw Exception('Please enter your email.');
    }

    if (password.isEmpty) {
      throw Exception('Please enter a password.');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception(
          'Registration succeeded but no Firebase user was returned.',
        );
      }

      await user.updateDisplayName(normalizedName);

      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': normalizedName,
        'email': normalizedEmail,
        'phone': normalizedPhone,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'uid': user.uid,
        'email': user.email ?? normalizedEmail,
        'name': normalizedName,
        'message': 'Account created successfully',
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(_authErrorMessage(e));
    }
  }

  Future<String?> getToken() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    return user.getIdToken();
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<bool> validateSession() async {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      await user.getIdToken(true);
      return true;
    } on FirebaseAuthException {
      return false;
    }
  }

  Future<String?> getSavedEmail() async {
    return _auth.currentUser?.email;
  }

  User? get currentUser => _auth.currentUser;

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> clearSession() async {
    await _auth.signOut();
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'wrong-password':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection failed. Please try again.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
