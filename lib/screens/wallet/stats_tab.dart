import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/wallet_models.dart';
import '../../services/wallet_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/format.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/tx_tile.dart';

enum StatRange { month, quarter, year }

class _StatData {
  _StatData(this.labels, this.income, this.expense, this.txs);
  final List<String> labels;
  final List<double> income;
  final List<double> expense;
  final List<WalletTx> txs;

  double get totalIncome => income.fold(0.0, (a, b) => a + b);
  double get totalExpense => expense.fold(0.0, (a, b) => a + b);
}

/// Thống kê dòng tiền theo 1 tháng / 1 quý / 1 năm
class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  final WalletService _service = WalletService();
  StatRange _range = StatRange.month;
  late Future<_StatData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  DateTime _rangeStart(StatRange r, DateTime now) {
    switch (r) {
      case StatRange.month: // 30 ngày gần nhất
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
      case StatRange.quarter: // 3 tháng gần nhất
        return DateTime(now.year, now.month - 2, 1);
      case StatRange.year: // 12 tháng gần nhất
        return DateTime(now.year, now.month - 11, 1);
    }
  }

  int _bucketCount(StatRange r) =>
      r == StatRange.month ? 6 : (r == StatRange.quarter ? 3 : 12);

  int _bucketIndex(StatRange r, DateTime from, DateTime d) {
    final max = _bucketCount(r) - 1;
    if (r == StatRange.month) {
      return (d.difference(from).inDays ~/ 5).clamp(0, max).toInt();
    }
    final i = (d.year - from.year) * 12 + d.month - from.month;
    return i.clamp(0, max).toInt();
  }

  Future<_StatData> _load() async {
    final now = DateTime.now();
    final from = _rangeStart(_range, now);
    final to = now.add(const Duration(days: 1));
    final txs = await _service.getTransactions(from, to);

    final n = _bucketCount(_range);
    final income = List<double>.filled(n, 0);
    final expense = List<double>.filled(n, 0);
    for (final t in txs) {
      final i = _bucketIndex(_range, from, t.createdAt);
      if (t.type.isIncome) {
        income[i] += t.amount;
      } else {
        expense[i] += t.amount;
      }
    }

    final labels = <String>[];
    for (var i = 0; i < n; i++) {
      if (_range == StatRange.month) {
        final d = from.add(Duration(days: i * 5));
        labels.add('${two(d.day)}/${two(d.month)}');
      } else {
        final d = DateTime(from.year, from.month + i, 1);
        labels.add('${two(d.month)}/${two(d.year % 100)}');
      }
    }
    return _StatData(labels, income, expense, txs.reversed.toList());
  }

  void _changeRange(StatRange r) {
    setState(() {
      _range = r;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Statistics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SegmentedButton<StatRange>(
          segments: const [
            ButtonSegment(value: StatRange.month, label: Text('1 tháng')),
            ButtonSegment(value: StatRange.quarter, label: Text('1 quý')),
            ButtonSegment(value: StatRange.year, label: Text('1 năm')),
          ],
          selected: {_range},
          onSelectionChanged: (s) => _changeRange(s.first),
        ),
        const SizedBox(height: 16),
        FutureBuilder<_StatData>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError) {
              logger.e('Stats error: ${snap.error}');
              return Text('Lỗi: ${snap.error}');
            }
            final data = snap.data!;
            final net = data.totalIncome - data.totalExpense;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SummaryCard('Tổng thu', data.totalIncome,
                        const Color(0xFF1FAA59)),
                    const SizedBox(width: 8),
                    _SummaryCard('Tổng chi', data.totalExpense,
                        const Color(0xFFE53935)),
                    const SizedBox(width: 8),
                    _SummaryCard('Chênh lệch', net, kWalletPurple),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Biểu đồ dòng tiền',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    _Legend(Color(0xFF1FAA59), 'Thu'),
                    SizedBox(width: 12),
                    _Legend(Color(0xFFE53935), 'Chi'),
                  ],
                ),
                const SizedBox(height: 8),
                _BarChart(
                    labels: data.labels,
                    income: data.income,
                    expense: data.expense),
                const SizedBox(height: 20),
                const Text('Giao dịch trong kỳ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (data.txs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Không có giao dịch trong khoảng thời gian này',
                        style: TextStyle(color: Colors.black45)),
                  )
                else
                  for (final t in data.txs) TxTile(tx: t),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.title, this.value, this.color);

  final String title;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(formatMoney(value),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.text);

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// Biểu đồ cột đơn giản (không cần thư viện ngoài)
class _BarChart extends StatelessWidget {
  const _BarChart(
      {required this.labels, required this.income, required this.expense});

  final List<String> labels;
  final List<double> income;
  final List<double> expense;

  @override
  Widget build(BuildContext context) {
    final maxVal = math.max(1.0, [...income, ...expense].reduce(math.max));
    const chartHeight = 130.0;

    Widget bar(double v, Color c) => Container(
          width: 8,
          height: v / maxVal * chartHeight,
          decoration: BoxDecoration(
            color: c,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: chartHeight + 28,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        bar(income[i], const Color(0xFF1FAA59)),
                        const SizedBox(width: 2),
                        bar(expense[i], const Color(0xFFE53935)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i], style: const TextStyle(fontSize: 9)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
