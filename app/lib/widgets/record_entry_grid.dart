import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:family_health/core/theme/app_theme.dart';

/// A record type definition for the quick entry grid.
class _RecordType {
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const _RecordType({
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

/// Quick entry grid widget showing health record types as icon buttons.
///
/// Displays a 3-column grid of large icon buttons for common health record
/// types. Each button navigates to /record/{type}/{pid} using the provided
/// [selectedProfileId].
class RecordEntryGrid extends StatelessWidget {
  /// The ID of the currently selected profile.
  final int? selectedProfileId;

  const RecordEntryGrid({
    super.key,
    this.selectedProfileId,
  });

  /// All record types with their icons, colors, and route segments.
  static const List<_RecordType> _recordTypes = [
    _RecordType(
      label: '睡眠',
      icon: Icons.bed,
      color: AppTheme.blue,
      route: 'sleep',
    ),
    _RecordType(
      label: '吸烟',
      icon: Icons.smoke_free,
      color: AppTheme.warning,
      route: 'smoking',
    ),
    _RecordType(
      label: '饮酒',
      icon: Icons.local_bar,
      color: AppTheme.warningLight,
      route: 'drinking',
    ),
    _RecordType(
      label: '工作姿势',
      icon: Icons.accessibility_new,
      color: AppTheme.healthGreen,
      route: 'work_posture',
    ),
    _RecordType(
      label: '饮食',
      icon: Icons.restaurant,
      color: AppTheme.healthGreenLight,
      route: 'diet',
    ),
    _RecordType(
      label: '血糖',
      icon: Icons.monitor_heart_outlined,
      color: Colors.pink,
      route: 'sugar',
    ),
    _RecordType(
      label: '食物详情',
      icon: Icons.egg,
      color: Colors.orange,
      route: 'food_detail',
    ),
    _RecordType(
      label: '环境',
      icon: Icons.cloud,
      color: Colors.cyan,
      route: 'environment',
    ),
    _RecordType(
      label: '生命体征',
      icon: Icons.favorite,
      color: AppTheme.error,
      route: 'vitals',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.1,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: _recordTypes.map((type) {
        return _QuickEntryButton(
          icon: type.icon,
          label: type.label,
          color: type.color,
          onTap: () => _onTap(context, type),
        );
      }).toList(),
    );
  }

  void _onTap(BuildContext context, _RecordType type) {
    if (selectedProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择家庭成员'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.push('/record/${type.route}/$selectedProfileId');
  }
}

/// A single quick entry button in the grid.
class _QuickEntryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickEntryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
