import 'package:cloud_firestore/cloud_firestore.dart';

enum TxType { topup, withdraw, transferOut, transferIn }

extension TxTypeX on TxType {
  String get key {
    switch (this) {
      case TxType.topup:
        return 'topup';
      case TxType.withdraw:
        return 'withdraw';
      case TxType.transferOut:
        return 'transfer_out';
      case TxType.transferIn:
        return 'transfer_in';
    }
  }

  /// Giao dịch làm tăng số dư
  bool get isIncome => this == TxType.topup || this == TxType.transferIn;
}

TxType txTypeFromKey(String k) =>
    TxType.values.firstWhere((t) => t.key == k, orElse: () => TxType.topup);

class WalletTx {
  WalletTx({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.counterparty,
    required this.createdAt,
  });

  final String id;
  final TxType type;
  final double amount;
  final String note;
  final String counterparty;
  final DateTime createdAt;

  factory WalletTx.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return WalletTx(
      id: doc.id,
      type: txTypeFromKey((d['type'] ?? '') as String),
      amount: ((d['amount'] ?? 0) as num).toDouble(),
      note: (d['note'] ?? '') as String,
      counterparty: (d['counterparty'] ?? '') as String,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class WalletException implements Exception {
  WalletException(this.message);
  final String message;

  @override
  String toString() => message;
}
