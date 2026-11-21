import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wallet_models.dart';

/// Cấu trúc Firestore:
///   users/{uid}                      : displayName, email, phone, balance, createdAt
///   users/{uid}/transactions/{txId}  : type, amount, note, counterparty, createdAt
class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _txCol(String userId) =>
      _db.collection('users').doc(userId).collection('transactions');

  Future<bool> userExists() async => (await _userRef.get()).exists;

  /// Tạo ví (document users/{uid}) nếu chưa có
  Future<void> ensureUserDoc() async {
    final snap = await _userRef.get();
    if (snap.exists) return;
    final u = _auth.currentUser!;
    await _userRef.set({
      'displayName': u.displayName ?? '',
      'email': (u.email ?? '').toLowerCase(),
      'phone': '',
      'balance': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser() =>
      _userRef.snapshots();

  Stream<List<WalletTx>> watchTransactions({int limit = 50}) {
    return _txCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(WalletTx.fromDoc).toList());
  }

  /// Giao dịch trong khoảng thời gian (dùng cho thống kê dòng tiền)
  Future<List<WalletTx>> getTransactions(DateTime from, DateTime to) async {
    final q = await _txCol(uid)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('createdAt')
        .get();
    return q.docs.map(WalletTx.fromDoc).toList();
  }

  Future<void> topUp(double amount) =>
      _changeBalance(amount, TxType.topup, 'Top up');

  Future<void> withdraw(double amount) =>
      _changeBalance(amount, TxType.withdraw, 'Withdraw');

  Future<void> _changeBalance(double amount, TxType type, String note) async {
    if (amount <= 0) throw WalletException('Số tiền phải lớn hơn 0');
    await _db.runTransaction((t) async {
      final snap = await t.get(_userRef);
      final balance = ((snap.data()?['balance'] ?? 0) as num).toDouble();
      if (!type.isIncome && balance < amount) {
        throw WalletException('Số dư không đủ');
      }
      final newBalance = type.isIncome ? balance + amount : balance - amount;
      t.set(_userRef, {'balance': newBalance}, SetOptions(merge: true));
      t.set(_txCol(uid).doc(), {
        'type': type.key,
        'amount': amount,
        'note': note,
        'counterparty': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Chuyển tiền cho người dùng khác theo email
  Future<void> transfer({
    required String toEmail,
    required double amount,
    String note = '',
  }) async {
    if (amount <= 0) throw WalletException('Số tiền phải lớn hơn 0');
    final email = toEmail.trim().toLowerCase();

    final q = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) {
      throw WalletException('Không tìm thấy người nhận với email này');
    }
    final toRef = q.docs.first.reference;
    if (toRef.id == uid) {
      throw WalletException('Không thể chuyển tiền cho chính mình');
    }
    final myEmail = _auth.currentUser!.email ?? '';

    await _db.runTransaction((t) async {
      final fromSnap = await t.get(_userRef);
      final toSnap = await t.get(toRef);
      final fromBal = ((fromSnap.data()?['balance'] ?? 0) as num).toDouble();
      final toBal = ((toSnap.data()?['balance'] ?? 0) as num).toDouble();
      if (fromBal < amount) throw WalletException('Số dư không đủ');

      t.update(_userRef, {'balance': fromBal - amount});
      t.update(toRef, {'balance': toBal + amount});
      t.set(_txCol(uid).doc(), {
        'type': TxType.transferOut.key,
        'amount': amount,
        'note': note,
        'counterparty': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.set(_txCol(toRef.id).doc(), {
        'type': TxType.transferIn.key,
        'amount': amount,
        'note': note,
        'counterparty': myEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    await _userRef
        .set({'displayName': name, 'phone': phone}, SetOptions(merge: true));
    await _auth.currentUser!.updateDisplayName(name);
  }
}
