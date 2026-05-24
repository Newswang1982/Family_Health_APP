import 'package:flutter/material.dart';
import 'package:family_health/core/theme/app_theme.dart';

/// A model for an abnormal health indicator alert.
class HealthAlert {
  final String memberName;
  final String indicatorName;
  final String indicatorValue;
  final String threshold;
  final String severity; // 'warning' or 'critical'
  final DateTime timestamp;

  HealthAlert({
    required this.memberName,
    required this.indicatorName,
    required this.indicatorValue,
    required this.threshold,
    required this.severity,
    required this.timestamp,
  });
}

/// A page that displays abnormal health indicator alerts.
class AlertNotificationsPage extends StatelessWidget {
  final List<HealthAlert> alerts;

  const AlertNotificationsPage({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('异常指标通知')),
      body: alerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('所有指标正常', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('今日无异常指标通知', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (ctx, i) {
                final alert = alerts[i];
                final isCritical = alert.severity == 'critical';
                return Card(
                  color: isCritical ? AppTheme.errorLight : AppTheme.warningLight,
                  child: ListTile(
                    leading: Icon(
                      isCritical ? Icons.warning : Icons.info_outline,
                      color: isCritical ? AppTheme.error : AppTheme.warning,
                      size: 32,
                    ),
                    title: Text(
                      '${alert.memberName} - ${alert.indicatorName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCritical ? AppTheme.error : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('当前值: ${alert.indicatorValue}'),
                        Text('参考范围: ${alert.threshold}'),
                        Text(
                          '${alert.timestamp.month}/${alert.timestamp.day} ${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}

/// A widget that shows a summary of unread alerts on the home page.
class AlertSummaryCard extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const AlertSummaryCard({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) return const SizedBox.shrink();

    return Card(
      color: AppTheme.warningLight,
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: AppTheme.warning),
        title: Text('$unreadCount 条异常指标'),
        subtitle: const Text('点击查看详情'),
        trailing: TextButton(
          onPressed: onTap,
          child: const Text('查看'),
        ),
        onTap: onTap,
      ),
    );
  }
}
