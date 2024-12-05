import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to handle user sign-in with email and password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print(e);
      rethrow; // Rethrow the exception to be handled by the calling code
    }
  }

  // Method to handle user sign-up with email and password
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Optional: Send an email verification
      // User? user = result.user;
      // if (user != null && !user.emailVerified) {
      //   await user.sendEmailVerification();
      // }
      return result.user;
    } on FirebaseAuthException catch (e) {
      print(e);
      rethrow; // Rethrow the exception to be handled by the calling code
    }
  }

  // Method to handle user sign-out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Method to get the current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}