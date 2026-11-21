import 'package:flutter/material.dart';

/// Bàn phím số. Phím đặc biệt: '.' và '<' (xóa lùi)
class NumPad extends StatelessWidget {
  const NumPad({super.key, required this.onKey});

  final void Function(String key) onKey;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '<'];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.1,
      mainAxisSpacing: 10,
      crossAxisSpacing: 14,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: _keys.map((k) {
        return Material(
          color: const Color(0xFFF1F0FF),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () => onKey(k),
            child: Center(
              child: k == '<'
                  ? const Icon(Icons.backspace_outlined, size: 20)
                  : Text(k,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
