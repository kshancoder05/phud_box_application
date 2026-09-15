import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final CycleResult result;

  const StatusBadge({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final pass = result == CycleResult.pass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: pass ? AppColors.greenDark : AppColors.redDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        pass ? 'PASS' : 'FAIL',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
