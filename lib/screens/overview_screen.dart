import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  String _mmss(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final disinfecting = state.status == DeviceStatus.disinfecting;
    final batch = state.activeBatch;
    final etaMin = (state.secondsLeft / 60).ceil();
    final estCycles = state.battery > 0 ? (state.battery / 8).round().clamp(1, 99) : 0;

    return Column(
      children: [
        const _Header(title: 'OVERVIEW', subtitle: 'Disinfection Monitor'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricsCard(
                  batteryPercent: state.battery,
                  estCycles: estCycles,
                ),
                const SizedBox(height: 16),
                _StatusCard(
                  disinfecting: disinfecting,
                  timeText: disinfecting ? _mmss(state.secondsLeft) : null,
                  etaMin: disinfecting ? etaMin : null,
                ),
                const SizedBox(height: 16),
                if (disinfecting && batch != null)
                  _ActiveBatchCard(
                    batchId: batch.id,
                    colorTag: batch.color,
                    instruments: batch.instruments.join(', '),
                    uvIntensity: batch.uvIntensity,
                  )
                else
                  const _NoActiveBatchCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cardBorderLight),
                ),
                child: const Text(
                  'PHUDBox',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorderLight),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderLight),
      ),
      child: child,
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final int batteryPercent;
  final int estCycles;

  const _MetricsCard({required this.batteryPercent, required this.estCycles});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _MetricItem(
              icon: Icons.bolt_rounded,
              title: 'Battery Status',
              subtitle: '$batteryPercent% charged',
            ),
          ),
          Container(width: 1, height: 36, color: AppColors.cardBorderLight),
          Expanded(
            child: _MetricItem(
              icon: Icons.autorenew_rounded,
              title: 'Est. Cycles',
              subtitle: '$estCycles Cycles remaining',
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool alignEnd;

  const _MetricItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: AppColors.tealBg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: AppColors.teal),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.mutedLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(left: alignEnd ? 14 : 0, right: alignEnd ? 0 : 14),
      child: row,
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool disinfecting;
  final String? timeText;
  final int? etaMin;

  const _StatusCard({required this.disinfecting, this.timeText, this.etaMin});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: disinfecting ? AppColors.dangerRedBg : AppColors.pageBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: disinfecting ? AppColors.dangerRed : AppColors.cardBorderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: disinfecting ? AppColors.dangerRed : AppColors.mutedLight,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  disinfecting ? 'SYSTEM DISINFECTING' : 'SYSTEM IDLE',
                  style: TextStyle(
                    color: disinfecting ? AppColors.dangerRed : AppColors.mutedLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _TimerCircle(disinfecting: disinfecting, timeText: timeText),
          const SizedBox(height: 20),
          Text(
            disinfecting
                ? 'DO NOT open the device during disinfection.'
                : 'System checks verified. Chamber is secure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: disinfecting ? AppColors.dangerRed : AppColors.mutedLight,
              fontSize: 12,
              fontWeight: disinfecting ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final bool disinfecting;
  final String? timeText;

  const _TimerCircle({required this.disinfecting, this.timeText});

  @override
  Widget build(BuildContext context) {
    const size = 170.0;

    if (!disinfecting) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _DashedCirclePainter(color: AppColors.cardBorderLight),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '--:--',
                  style: TextStyle(
                    color: AppColors.placeholderLight,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'READY TO START',
                  style: TextStyle(
                    color: AppColors.placeholderLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy, width: 4),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeText ?? '--:--',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'REMAINING',
              style: TextStyle(
                color: AppColors.mutedLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    const dashCount = 40;
    const gapFraction = 0.5;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = (i / dashCount) * 2 * 3.141592653589793;
      final sweep = (2 * 3.141592653589793 / dashCount) * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => false;
}

class _NoActiveBatchCard extends StatelessWidget {
  const _NoActiveBatchCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Center(
        child: Text(
          'No Active Batch Loaded',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActiveBatchCard extends StatelessWidget {
  final String batchId;
  final String colorTag;
  final String instruments;
  final String uvIntensity;

  const _ActiveBatchCard({
    required this.batchId,
    required this.colorTag,
    required this.instruments,
    required this.uvIntensity,
  });

  (Color bg, Color fg) _badgeColors(String tag) {
    switch (tag.toUpperCase()) {
      case 'RED':
        return (AppColors.dangerRedBg, AppColors.dangerRed);
      case 'GREEN':
        return (AppColors.successGreenBg, AppColors.successGreen);
      default:
        return (AppColors.neutralBadgeBg, AppColors.neutralBadgeText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _badgeColors(colorTag);

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Batch Information:',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  colorTag.toUpperCase(),
                  style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoLine(label: 'Batch ID', value: batchId),
          _InfoLine(label: 'Instruments', value: instruments),
          _InfoLine(label: 'UV-C Intensity', value: '$uvIntensity (Dosage Peak)'),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}