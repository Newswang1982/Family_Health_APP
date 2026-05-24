import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

/// A page to scan and manage BLE health band devices.
class BleScanPage extends StatefulWidget {
  final String familyId;
  const BleScanPage({super.key, required this.familyId});

  @override
  State<BleScanPage> createState() => _BleScanPageState();
}

class _BleScanPageState extends State<BleScanPage> {
  bool _isScanning = false;
  List<ScanResult> _devices = [];
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _checkBluetooth();
  }

  Future<void> _checkBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('该设备不支持蓝牙')),
          );
        }
        return;
      }
    } catch (_) {}
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      // Start scan
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        setState(() {
          _devices = results;
        });
      });

      // Wait for timeout
      await Future.delayed(const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('扫描失败: $e')),
        );
      }
    } finally {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectDevice(ScanResult device) async {
    try {
      await device.device.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已连接: ${device.device.remoteId}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('蓝牙设备扫描')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                label: Text(_isScanning ? '正在扫描...' : '开始扫描'),
                onPressed: _isScanning ? null : _startScan,
              ),
            ),
          ),
          if (_isScanning)
            const LinearProgressIndicator(),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text('未发现设备\n点击"开始扫描"搜索附近蓝牙设备', textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (ctx, i) {
                      final d = _devices[i];
                      final name = d.device.advName.isNotEmpty
                          ? d.device.advName
                          : d.device.remoteId.toString().substring(0, 17);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth, color: Colors.blue),
                          title: Text(name),
                          subtitle: Text('RSSI: ${d.rssi} dBm'),
                          trailing: TextButton(
                            onPressed: () => _connectDevice(d),
                            child: const Text('连接'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
