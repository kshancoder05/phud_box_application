import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/batch.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppState>().logs;

    return Column(
      children: [
        const _Header(title: 'DATA LOGS', subtitle: 'Past Disinfection Sessions'),
        Expanded(
          child: logs.isEmpty
              ? const _EmptyLogs()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _LogCard(log: logs[i]),
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

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.tealBg, shape: BoxShape.circle),
              child: const Icon(Icons.assignment_rounded, size: 32, color: AppColors.teal),
            ),
            const SizedBox(height: 16),
            const Text(
              'No completed cycles yet.',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Finished disinfection sessions will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedLight,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends StatelessWidget {
  final BatchLog log;
  const _LogCard({required this.log});

  (Color bg, Color fg) _tagColors(String tag) {
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
    final (tagBg, tagFg) = _tagColors(log.color);
    final pass = log.result == CycleResult.pass;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch #${log.id}',
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration:
                    BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  log.color.toUpperCase(),
                  style: TextStyle(color: tagFg, fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ),
              const Spacer(),
              Text(
                log.date,
                style: const TextStyle(
                  color: AppColors.mutedLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorderLight),
          const SizedBox(height: 12),
          _InfoLine(label: 'Instruments', value: log.instruments),
          _InfoLine(label: 'Duration', value: log.time),
          _InfoLine(label: 'Intensity Peak', value: log.uvIntensity),
          if (log.expiry != null) _InfoLine(label: 'Expiry', value: log.expiry!),
          if (log.error != null)
            _InfoLine(label: 'Error', value: log.error!, valueColor: AppColors.dangerRed),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Disinfection Result',
                style: TextStyle(
                  color: AppColors.mutedLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: pass ? AppColors.successGreenBg : AppColors.dangerRedBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  pass ? 'PASS' : 'FAIL',
                  style: TextStyle(
                    color: pass ? AppColors.successGreen : AppColors.dangerRed,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoLine({required this.label, required this.value, this.valueColor});

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
              style: TextStyle(
                color: valueColor ?? AppColors.navy,
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