import 'package:flutter/material.dart';

import '../models/wallet_models.dart';
import '../utils/format.dart';

class TxTile extends StatelessWidget {
  const TxTile({super.key, required this.tx});

  final WalletTx tx;

  String get _title {
    switch (tx.type) {
      case TxType.topup:
        return 'Top up';
      case TxType.withdraw:
        return 'Withdraw';
      case TxType.transferOut:
        return 'Transfer to ${tx.counterparty}';
      case TxType.transferIn:
        return 'Received from ${tx.counterparty}';
    }
  }

  IconData get _icon {
    switch (tx.type) {
      case TxType.topup:
        return Icons.add_circle_outline;
      case TxType.withdraw:
        return Icons.south_west;
      case TxType.transferOut:
        return Icons.north_east;
      case TxType.transferIn:
        return Icons.call_received;
    }
  }

  @override
  Widget build(BuildContext context) {
    final income = tx.type.isIncome;
    final color = income ? const Color(0xFF1FAA59) : const Color(0xFFE53935);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.12),
        child: Icon(_icon, color: color, size: 20),
      ),
      title: Text(_title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(formatDateTime(tx.createdAt),
          style: const TextStyle(fontSize: 11)),
      trailing: Text(
        '${income ? '+' : '-'}${formatMoney(tx.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
