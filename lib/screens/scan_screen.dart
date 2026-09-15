import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<ScanResult> _results = [];
  bool _scanning = false;
  String? _connectingId;

  Future<void> _ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> _startScan() async {
    await _ensurePermissions();
    if (!mounted) return;
    setState(() {
      _results = [];
      _scanning = true;
    });
    final appState = context.read<AppState>();
    appState.scan().listen((results) {
      if (!mounted) return;
      setState(() => _results = results);
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  Future<void> _connect(ScanResult r) async {
    setState(() => _connectingId = r.device.remoteId.str);
    final appState = context.read<AppState>();
    await appState.stopScan();
    await appState.connect(r.device);
    if (!mounted) return;
    setState(() => _connectingId = null);
    if (appState.isConnected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else if (appState.connectionError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: ${appState.connectionError}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
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
                            const Text(
                              'CONNECT DEVICE',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Find your PHUD Box nearby',
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
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BluetoothIllustration(scanning: _scanning),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _scanning ? null : _startScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.teal.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _scanning
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Scanning...',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bluetooth_searching_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Scan for PHUD Box Devices',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_results.isEmpty)
                      _EmptyState(scanning: _scanning)
                    else
                      Column(
                        children: _results
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _DeviceCard(
                                    result: r,
                                    connecting: _connectingId == r.device.remoteId.str,
                                    onConnect: () => _connect(r),
                                  ),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BluetoothIllustration extends StatelessWidget {
  final bool scanning;
  const _BluetoothIllustration({required this.scanning});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(color: AppColors.tealBg, shape: BoxShape.circle),
        child: Icon(
          scanning ? Icons.bluetooth_searching_rounded : Icons.bluetooth_rounded,
          size: 42,
          color: AppColors.teal,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool scanning;
  const _EmptyState({required this.scanning});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderLight),
      ),
      child: Text(
        scanning
            ? 'Looking for nearby devices...'
            : 'No devices found yet. Make sure the box is powered on and in range.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.mutedLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final ScanResult result;
  final bool connecting;
  final VoidCallback onConnect;

  const _DeviceCard({
    required this.result,
    required this.connecting,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final advertisedName = result.advertisementData.advName;
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : advertisedName.isNotEmpty
            ? advertisedName
            : 'Unnamed device';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.tealBg, shape: BoxShape.circle),
            child: const Icon(Icons.bluetooth_rounded, size: 18, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'RSSI ${result.rssi} dBm',
                  style: const TextStyle(
                    color: AppColors.mutedLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: connecting ? null : onConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.successGreen.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: connecting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Connect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}