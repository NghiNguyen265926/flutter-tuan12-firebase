import 'package:flutter/material.dart';

import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../widgets/tx_tile.dart';

/// Lịch sử giao dịch (History / see all)
class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<WalletTx>>(
        stream: WalletService().watchTransactions(limit: 200),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(child: Text('Chưa có giao dịch nào'));
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (_, i) => TxTile(tx: list[i]),
          );
        },
      ),
    );
  }
}
