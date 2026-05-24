import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:family_health/core/api/statistics_api.dart';
import 'package:family_health/core/providers/profile_provider.dart';
import 'package:family_health/core/models/profile.dart';
import 'package:family_health/core/theme/app_theme.dart';
import 'package:family_health/widgets/kline_chart.dart';

/// Indicator type configuration.
class _IndicatorType {
  final String key;
  final String label;
  final String unit;

  const _IndicatorType({
    required this.key,
    required this.label,
    required this.unit,
  });
}

const _indicatorTypes = [
  _IndicatorType(key: 'heart_rate', label: '心率', unit: 'bpm'),
  _IndicatorType(key: 'blood_pressure', label: '血压', unit: 'mmHg'),
  _IndicatorType(key: 'blood_oxygen', label: '血氧', unit: '%'),
  _IndicatorType(key: 'temperature', label: '体温', unit: '°C'),
  _IndicatorType(key: 'weight', label: '体重', unit: 'kg'),
  _IndicatorType(key: 'smoking', label: '吸烟', unit: '支'),
  _IndicatorType(key: 'drinking', label: '饮酒', unit: 'ml'),
  _IndicatorType(key: 'sleep', label: '睡眠', unit: '小时'),
];

/// Period options.
const _periods = [
  ('day', '日'),
  ('week', '周'),
  ('month', '月'),
  ('quarter', '季'),
  ('year', '年'),
];

/// Charts & Statistics page with K-line chart, statistics summary,
/// correlation analysis, and health report generation.
class ChartsPage extends ConsumerStatefulWidget {
  const ChartsPage({super.key});

  @override
  ConsumerState<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends ConsumerState<ChartsPage> {
  String _selectedPeriod = 'month';
  MemberProfile? _selectedMember;
  _IndicatorType _selectedIndicator = _indicatorTypes[0];
  KlinePeriod _selectedKlinePeriod = KlinePeriod.month;

  // Statistics result
  Map<String, dynamic>? _statsData;
  bool _statsLoading = false;

  // K-line result
  List<KlinePoint>? _klinePoints;
  bool _klineLoading = false;

  // Report
  Map<String, dynamic>? _reportData;
  bool _reportLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAllData());
  }

  Future<void> _loadAllData() async {
    final member = _selectedMember ?? ref.read(profileProvider).selectedProfile;
    if (member == null) return;

    setState(() {
      _statsLoading = true;
      _klineLoading = true;
    });

    try {
      final api = ref.read(statisticsApiProvider);

      // Load statistics
      try {
        final stats = await api.getStatistics(
          member.id.toString(),
          _selectedIndicator.key,
          period: _selectedPeriod,
        );
        if (mounted) setState(() => _statsData = stats);
      } catch (e) {
        if (mounted) setState(() => _statsData = null);
      }

      // Load K-line
      try {
        final kline = await api.getKLine(
          member.id.toString(),
          _selectedIndicator.key,
          period: _selectedKlinePeriod.apiValue,
        );
        if (mounted) {
          final pointsJson = kline['points'] as List<dynamic>? ?? [];
          setState(() {
            _klinePoints = pointsJson
                .map((j) => KlinePoint.fromJson(j as Map<String, dynamic>))
                .toList();
          });
        }
      } catch (e) {
        if (mounted) setState(() => _klinePoints = null);
      }
    } finally {
      if (mounted) {
        setState(() {
          _statsLoading = false;
          _klineLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计与报告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReport,
            tooltip: '分享报告',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAllData(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── Period Selector ──
            _buildPeriodSelector(),

            const SizedBox(height: 8),

            // ── Member Profile Selector ──
            _buildMemberSelector(profileState),

            const SizedBox(height: 8),

            // ── Indicator Type Selector ──
            _buildIndicatorSelector(),

            const SizedBox(height: 16),

            // ── Statistics Summary Cards ──
            _buildStatisticsCards(),

            const SizedBox(height: 16),

            // ── K-line Chart ──
            _buildKlineSection(),

            const SizedBox(height: 16),

            // ── Correlation Analysis ──
            _buildCorrelationSection(),

            const SizedBox(height: 16),

            // ── Generate Report Button ──
            _buildReportButton(),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periods.map((p) {
            final key = p.$1;
            final label = p.$2;
            final isSelected = _selectedPeriod == key;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedPeriod = key);
                  _loadAllData();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMemberSelector(ProfileState profileState) {
    final profiles = profileState.profiles;
    final member = _selectedMember ?? profileState.selectedProfile;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            '成员: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: member?.id,
                isExpanded: true,
                hint: const Text('选择成员'),
                items: [
                  ...profiles.map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.displayName),
                    ),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedMember =
                        profiles.where((p) => p.id == val).firstOrNull;
                  });
                  _loadAllData();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _indicatorTypes.map((ind) {
            final isSelected = _selectedIndicator.key == ind.key;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(ind.label),
                selected: isSelected,
                onSelected: (_) {
                  setState(() => _selectedIndicator = ind);
                  _loadAllData();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    if (_statsLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_statsData == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            '暂无统计数据',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ),
      );
    }

    final data = _statsData!;
    final mean = data['mean'] != null ? (data['mean'] as num).toDouble() : null;
    final median = data['median'] != null ? (data['median'] as num).toDouble() : null;
    final minVal = data['min'] != null ? (data['min'] as num).toDouble() : null;
    final max = data['max'] != null ? (data['max'] as num).toDouble() : null;
    final refMin = data['reference_min'] as num?;
    final refMax = data['reference_max'] as num?;
    final status = data['status'] as String? ?? 'no_data';
    final dataPoints = data['data_points'] as int? ?? 0;

    final unit = _selectedIndicator.unit;

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'normal':
        statusLabel = '正常';
        statusColor = AppTheme.normal;
        break;
      case 'above_range':
        statusLabel = '偏高';
        statusColor = AppTheme.warningLevel;
        break;
      case 'below_range':
        statusLabel = '偏低';
        statusColor = AppTheme.warning;
        break;
      default:
        statusLabel = '暂无数据';
        statusColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '${_selectedIndicator.label} 统计摘要',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              _buildStatCard(
                '均值',
                mean != null ? '${mean.toStringAsFixed(1)} $unit' : '--',
                Icons.calculate,
                AppTheme.healthGreen,
              ),
              _buildStatCard(
                '中位数',
                median != null ? '${median.toStringAsFixed(1)} $unit' : '--',
                Icons.show_chart,
                AppTheme.blue,
              ),
              _buildStatCard(
                dataPoints > 0 ? '当前值' : '参考值',
                dataPoints > 0 && max != null
                    ? '${max.toStringAsFixed(1)} $unit'
                    : refMax != null
                        ? '~${refMax.toStringAsFixed(1)} $unit'
                        : '--',
                Icons.trending_up,
                AppTheme.warning,
              ),
              _buildStatCard(
                '状态',
                statusLabel,
                Icons.check_circle,
                statusColor,
              ),
            ],
          ),
          if (refMin != null || refMax != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4),
              child: Text(
                '参考范围: ${refMin?.toStringAsFixed(1) ?? "--"} ~ ${refMax?.toStringAsFixed(1) ?? "--"} $unit  |  数据点: $dataPoints',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKlineSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: KlineChart(
          points: _klinePoints ?? [],
          isLoading: _klineLoading,
          chartLabel: '${_selectedIndicator.label}走势图',
          selectedPeriod: _selectedKlinePeriod,
          onPeriodChanged: (period) {
            setState(() => _selectedKlinePeriod = period);
            _loadAllData();
          },
        ),
      ),
    );
  }

  Widget _buildCorrelationSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '关联分析',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '多指标关联分析',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                    ),
                    Text(
                      '(例如: 睡眠与血压的关系)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
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

  Widget _buildReportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _reportLoading ? null : _generateReport,
        icon: _reportLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.description),
        label: Text(_reportLoading ? '生成中...' : '生成健康报告'),
      ),
    );
  }

  Future<void> _generateReport() async {
    final member = _selectedMember ?? ref.read(profileProvider).selectedProfile;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择成员'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _reportLoading = true);

    try {
      final api = ref.read(statisticsApiProvider);
      final response = await api.generateReport(member.id.toString());
      if (mounted) {
        setState(() => _reportData = response);
        _showReportDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成报告失败: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  void _showReportDialog(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('健康报告'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '报告 ID: ${report['id'] ?? '--'}',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              if (report['report'] is Map<String, dynamic>)
                ..._buildReportContent(report['report'] as Map<String, dynamic>),
              if (report['report'] is! Map<String, dynamic>)
                const Text('报告内容加载中...'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _shareGeneratedReport(report);
            },
            child: const Text('分享'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReportContent(Map<String, dynamic> data) {
    final widgets = <Widget>[];
    if (data.containsKey('summary') && data['summary'] is Map) {
      final summary = data['summary'] as Map;
      summary.forEach((key, value) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text('$key: $value', style: const TextStyle(fontSize: 13)),
          ),
        );
      });
    }
    if (data.containsKey('generated_at')) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '生成时间: ${data['generated_at']}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }
    return widgets;
  }

  void _shareReport() {
    final member = _selectedMember ?? ref.read(profileProvider).selectedProfile;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择成员'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final text = '''
健康报告 - ${member.displayName}
指标: ${_selectedIndicator.label}
周期: ${_getPeriodLabel()}
${_statsData != null ? '均值: ${_statsData!['mean'] ?? '--'} ${_selectedIndicator.unit}' : ''}
${_statsData != null ? '状态: ${_statsData!['status'] ?? '--'}' : ''}
-- 由家庭健康助手生成
''';

    Share.share(text);
  }

  void _shareGeneratedReport(Map<String, dynamic> report) {
    final reportStr = report.toString();
    Share.share(reportStr);
  }

  String _getPeriodLabel() {
    for (final p in _periods) {
      if (p.$1 == _selectedPeriod) return p.$2;
    }
    return _selectedPeriod;
  }
}
