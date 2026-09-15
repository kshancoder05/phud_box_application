import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/info_row.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final disinfecting = state.status == DeviceStatus.disinfecting;
    final canStart = !state.doorOpen && !disinfecting;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
      child: Column(
        children: [
          AppCard(
            child: Column(
              children: [
                const Text('Device Pre-Check',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Door Status:',
                        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: state.doorOpen ? AppColors.redDark : AppColors.greenDark,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        state.doorOpen ? 'OPEN' : 'CLOSED',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InfoRow(label: 'Battery Sufficiency:', value: '${state.battery}%'),
                InfoRow(label: 'Chamber Capacity:', value: '${state.chamberSlotsLeft} slots left'),
                if (state.doorOpen)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Close the door to start a cycle.',
                        style: TextStyle(color: Color(0xFFE78585), fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _CycleButton(
                  label: 'START\nCYCLE',
                  color: AppColors.green,
                  disabledColor: const Color(0xFF3A5A45),
                  enabled: canStart,
                  onTap: () => state.startCycle(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _CycleButton(
                  label: 'END\nCYCLE',
                  color: AppColors.red,
                  disabledColor: const Color(0xFF5A3A3A),
                  enabled: disinfecting,
                  onTap: () => state.endCycle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CycleButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color disabledColor;
  final bool enabled;
  final VoidCallback onTap;

  const _CycleButton({
    required this.label,
    required this.color,
    required this.disabledColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : disabledColor,
          disabledBackgroundColor: disabledColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
        ),
      ),
    );
  }
}
