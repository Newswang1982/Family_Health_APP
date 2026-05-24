import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/providers/family_provider.dart';
import 'package:family_health/core/api/family_api.dart';
import 'package:family_health/core/api/api_providers.dart';
import 'package:family_health/core/api/api_client.dart';
import 'package:family_health/core/models/profile.dart';
import 'package:family_health/core/theme/app_theme.dart';
import 'package:family_health/widgets/ble_scan_page.dart';

/// BLE device management page showing bound devices, scan button,
/// and member assignment. Integrates with [familyApiProvider] for
/// device bind/unbind API calls.
class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  /// List of bound devices
  List<_BoundDevice> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBoundDevices();
  }

  /// Load bound devices from the API or local state.
  Future<void> _loadBoundDevices() async {
    setState(() => _isLoading = true);
    try {
      // Attempt to load devices via the API client (familyApiProvider)
      final familyApi = ref.read(familyApiProvider);
      final families = await familyApi.listFamilies();
      // For now, load mock devices if no families exist yet
      if (_devices.isEmpty && families.isEmpty) {
        setState(() {
          _devices = [
            _BoundDevice(
              id: 'band-001',
              name: '小米手环 7',
              type: '智能手环',
              assignedMemberId: null,
              lastSync: DateTime.now().subtract(const Duration(hours: 2)),
            ),
            _BoundDevice(
              id: 'bp-001',
              name: '欧姆龙血压计',
              type: '血压计',
              assignedMemberId: null,
              lastSync: DateTime.now().subtract(const Duration(days: 1)),
            ),
          ];
        });
      }
    } catch (_) {
      // If API fails, keep existing devices or load defaults
      if (_devices.isEmpty) {
        setState(() {
          _devices = [];
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Start BLE scan by pushing [BleScanPage].
  void _startScan() {
    final familyState = ref.read(familyProvider);
    final familyId = familyState.selectedFamily?.id?.toString() ?? '0';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BleScanPage(familyId: familyId),
      ),
    );
  }

  /// Unbind a device — shows confirmation dialog and calls the API.
  Future<void> _unbindDevice(String deviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('解绑设备'),
        content: const Text('确定要将此设备从账户中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('解绑'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        // Call device unbind via familyApiProvider (using apiClient directly)
        final apiClient = ref.read(apiClientProvider);
        await apiClient.delete('/devices/$deviceId');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('设备已解绑'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('解绑失败: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
      setState(() {
        _devices.removeWhere((d) => d.id == deviceId);
      });
    }
  }

  /// Assign a member to a device via the API.
  Future<void> _assignMember(String deviceId, int? memberId) async {
    setState(() {
      final idx = _devices.indexWhere((d) => d.id == deviceId);
      if (idx != -1) {
        _devices[idx] = _devices[idx].copyWith(assignedMemberId: memberId);
      }
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      if (memberId != null) {
        await apiClient.post('/devices/$deviceId/assign', data: {
          'member_profile_id': memberId,
        });
      } else {
        await apiClient.delete('/devices/$deviceId/assign');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('分配成员失败: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profiles = profileState.profiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBoundDevices,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── 扫描新设备按钮 ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.bluetooth_searching),
                  label: const Text('扫描新设备'),
                ),
              ),
            ),

            // ── 已绑定设备列表 ──
            if (_devices.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '已绑定设备 (${_devices.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                ),
              ),

            if (_devices.isEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无绑定设备\n点击"扫描新设备"开始连接',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._devices.map((device) => _buildDeviceCard(device, profiles)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(
    _BoundDevice device,
    List<MemberProfile> profiles,
  ) {
    final assignedProfile = device.assignedMemberId != null
        ? profiles.where((p) => p.id == device.assignedMemberId).firstOrNull
        : null;

    return Dismissible(
      key: ValueKey(device.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error,
        child: const Icon(Icons.link_off, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        _unbindDevice(device.id);
        return false; // we handle removal ourselves
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 设备信息行 ──
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      device.type == '智能手环'
                          ? Icons.watch
                          : Icons.monitor_heart,
                      color: AppTheme.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          device.type,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // 同步状态
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        device.lastSync != null
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        size: 18,
                        color: device.lastSync != null
                            ? AppTheme.healthGreen
                            : Colors.grey,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.lastSync != null
                            ? _formatTimeAgo(device.lastSync!)
                            : '从未同步',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // ── 成员分配 ──
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '分配给: ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: device.assignedMemberId,
                        isExpanded: true,
                        hint: Text(
                          '未分配',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              '未分配',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          ...profiles.map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                p.displayName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          _assignMember(device.id, val);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // 显示已分配的成员名称
              if (assignedProfile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.healthGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          assignedProfile.displayName,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.healthGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

/// Internal model for a bound device.
class _BoundDevice {
  final String id;
  final String name;
  final String type;
  final int? assignedMemberId;
  final DateTime? lastSync;

  const _BoundDevice({
    required this.id,
    required this.name,
    required this.type,
    this.assignedMemberId,
    this.lastSync,
  });

  _BoundDevice copyWith({
    String? id,
    String? name,
    String? type,
    int? assignedMemberId,
    DateTime? lastSync,
  }) {
    return _BoundDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      assignedMemberId: assignedMemberId,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
