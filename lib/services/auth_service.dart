import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utils/app_logger.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _ggSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Stream<User?> get authChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Đăng ký bằng Email/Password
  Future<UserCredential> register(String email, String password,
      {String? name}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (name != null && name.isNotEmpty) {
      await cred.user!.updateDisplayName(name);
    }
    logger.i('User registered: ${cred.user!.email}');
    return cred;
  }

  /// Đăng nhập Basic Auth (Email/Password)
  Future<UserCredential> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    logger.i('User logged in: ${cred.user!.email}');
    return cred;
  }

  /// Đăng nhập Google. Trả về null nếu người dùng hủy.
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _ggSignIn.signIn();
    if (googleUser == null) {
      logger.i('Người dùng đã hủy đăng nhập Google');
      return null;
    }
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    logger.i('Google signed in: ${cred.user!.email}');
    return cred;
  }

  /// "Read Messages as Guest" - cần bật provider Anonymous trong Firebase
  Future<UserCredential> signInAnonymously() => _auth.signInAnonymously();

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    try {
      await _ggSignIn.signOut();
    } catch (e) {
      logger.w('Google signOut: $e');
    }
    await _auth.signOut();
  }

  static String message(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Sai email hoặc mật khẩu';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'network-request-failed':
        return 'Không có kết nối mạng';
      case 'too-many-requests':
        return 'Thử quá nhiều lần, vui lòng thử lại sau';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập chưa được bật trong Firebase Console';
      default:
        return e.message ?? 'Lỗi xác thực: ${e.code}';
    }
  }
}
