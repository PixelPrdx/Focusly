import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mevcut kullanıcıyı al
  User? get currentUser => _auth.currentUser;

  // Kullanıcı state değişimlerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // E-posta doğrulandı mı?
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Sign Up
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'fullName': fullName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Doğrulama e-postası gönder
      await userCredential.user!.sendEmailVerification();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign In
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // E-posta doğrulanmamışsa hata fırlat
      if (!userCredential.user!.emailVerified) {
        throw Exception('EMAIL_NOT_VERIFIED');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Doğrulama e-postasını tekrar gönder
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Şifre sıfırlama e-postası gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Kullanıcı bilgilerini yenile (e-posta doğrulama durumunu güncellemek için)
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Kullanıcı bilgilerini al
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUserData({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  // Firebase Auth exception'larını işle
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalıdır.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanılmaktadır.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmıştır.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      default:
        return e.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
