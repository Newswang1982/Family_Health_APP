import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:family_health/core/theme/app_theme.dart';

/// A single K-line data point returned by the backend.
class KlinePoint {
  final String date;
  final double open;
  final double close;
  final double high;
  final double low;
  final double mean;
  final int count;

  const KlinePoint({
    required this.date,
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.mean,
    required this.count,
  });

  factory KlinePoint.fromJson(Map<String, dynamic> json) {
    return KlinePoint(
      date: json['date'] as String,
      open: (json['open'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      mean: (json['mean'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );
  }
}

/// Period options for the K-line chart.
enum KlinePeriod {
  day,
  week,
  month,
  quarter,
  year;

  String get label {
    switch (this) {
      case KlinePeriod.day:
        return '日';
      case KlinePeriod.week:
        return '周';
      case KlinePeriod.month:
        return '月';
      case KlinePeriod.quarter:
        return '季';
      case KlinePeriod.year:
        return '年';
    }
  }

  String get apiValue {
    switch (this) {
      case KlinePeriod.day:
        return 'day';
      case KlinePeriod.week:
        return 'week';
      case KlinePeriod.month:
        return 'month';
      case KlinePeriod.quarter:
        return 'quarter';
      case KlinePeriod.year:
        return 'year';
    }
  }
}

/// A K-line style chart for health data using fl_chart.
///
/// Displays a line for [mean] with shaded area between [min] and [max].
/// Touch tooltips show date + values. Includes a period selector.
class KlineChart extends StatefulWidget {
  /// K-line data points.
  final List<KlinePoint> points;

  /// Whether data is still loading.
  final bool isLoading;

  /// Callback when period changes.
  final ValueChanged<KlinePeriod>? onPeriodChanged;

  /// Currently selected period.
  final KlinePeriod selectedPeriod;

  /// The label for the chart (e.g., "心率", "血压").
  final String? chartLabel;

  /// The minimum value for the Y-axis. Auto-calculated if null.
  final double? minY;

  /// The maximum value for the Y-axis. Auto-calculated if null.
  final double? maxY;

  /// The height of the chart widget.
  final double height;

  const KlineChart({
    super.key,
    required this.points,
    this.isLoading = false,
    this.onPeriodChanged,
    this.selectedPeriod = KlinePeriod.day,
    this.chartLabel,
    this.minY,
    this.maxY,
    this.height = 280,
  });

  @override
  State<KlineChart> createState() => _KlineChartState();
}

class _KlineChartState extends State<KlineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return _buildChart();
  }

  Widget _buildChart() {
    final spots = widget.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.mean))
        .toList();

    final allValues = widget.points.expand((p) => [p.high, p.low, p.mean]).toList();
    final yMin = widget.minY ?? allValues.reduce((a, b) => a < b ? a : b) * 0.9;
    final yMax = widget.maxY ?? allValues.reduce((a, b) => a > b ? a : b) * 1.1;

    return SizedBox(
      height: widget.height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with period selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.chartLabel != null)
                  Text(
                    widget.chartLabel!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  )
                else
                  const SizedBox.shrink(),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: KlinePeriod.values.map((p) {
                      final isSelected = p == widget.selectedPeriod;
                      return Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: ChoiceChip(
                          label: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? AppTheme.healthGreen : null,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppTheme.healthGreen.withValues(alpha: 0.12),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) {
                            widget.onPeriodChanged?.call(p);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, left: 8, bottom: 4),
              child: LineChart(
                LineChartData(
                  minY: yMin,
                  maxY: yMax,
                  clipData: const FlClipData.all(),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          if (idx < 0 || idx >= widget.points.length) {
                            return null;
                          }
                          final pt = widget.points[idx];
                          return LineTooltipItem(
                            '${pt.date}\n'
                            '均值: ${pt.mean.toStringAsFixed(1)}\n'
                            '最高: ${pt.high.toStringAsFixed(1)}\n'
                            '最低: ${pt.low.toStringAsFixed(1)}\n'
                            '记录数: ${pt.count}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (event, response) {
                      if (event.isInterestedForInteractions &&
                          response != null &&
                          response.lineBarSpots != null &&
                          response.lineBarSpots!.isNotEmpty) {
                        setState(() {
                          _touchedIndex = response.lineBarSpots!.first.spotIndex;
                        });
                      } else {
                        setState(() => _touchedIndex = null);
                      }
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= widget.points.length) {
                            return const SizedBox.shrink();
                          }
                          final n = widget.points.length;
                          if (n > 12 && idx % (n ~/ 6).clamp(1, 999) != 0) {
                            return const SizedBox.shrink();
                          }
                          final label = widget.points[idx].date;
                          // Shorten date display
                          final short = label.length > 5 ? label.substring(5) : label;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              short,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: _calculateInterval(yMin, yMax),
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(
                            value.toStringAsFixed(value.abs() >= 100 ? 0 : 1),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _calculateInterval(yMin, yMax),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 0.5,
                    ),
                  ),
                  lineBarsData: [
                    // Shaded area between min and max
                    LineChartBarData(
                      spots: widget.points
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.high))
                          .toList(),
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: Colors.transparent,
                      barWidth: 0,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: widget.points.length > 1,
                        color: AppTheme.healthGreen.withValues(alpha: 0.06),
                      ),
                    ),
                    // Mean line
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      preventCurveOverShooting: true,
                      color: AppTheme.healthGreen,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isTouched = _touchedIndex == index;
                          return FlDotCirclePainter(
                            radius: isTouched ? 5 : 3,
                            color: Colors.white,
                            strokeWidth: isTouched ? 3 : 2,
                            strokeColor: AppTheme.healthGreen,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: widget.points.length > 1,
                        color: AppTheme.healthGreen.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: _buildRangeLines(),
                  ),
                ),
              ),
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _legendDot(AppTheme.healthGreen, '均值'),
                const SizedBox(width: 16),
                _legendDot(Colors.green.withValues(alpha: 0.3), '范围(最高/最低)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  List<HorizontalLine> _buildRangeLines() {
    final lines = <HorizontalLine>[];
    if (widget.points.isEmpty) return lines;

    final highs = widget.points.map((p) => p.high);
    final lows = widget.points.map((p) => p.low);
    final globalHigh = highs.reduce((a, b) => a > b ? a : b);
    final globalLow = lows.reduce((a, b) => a < b ? a : b);

    if (widget.points.length > 1) {
      lines.addAll([
        HorizontalLine(
          y: globalHigh,
          color: Colors.red.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
            labelResolver: (_) => '最高 ${globalHigh.toStringAsFixed(1)}',
          ),
        ),
        HorizontalLine(
          y: globalLow,
          color: Colors.blue.withValues(alpha: 0.3),
          strokeWidth: 1,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.bottomRight,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.grey,
            ),
            labelResolver: (_) => '最低 ${globalLow.toStringAsFixed(1)}',
          ),
        ),
      ]);
    }
    return lines;
  }

  double _calculateInterval(double min, double max) {
    final range = max - min;
    if (range <= 0) return 1;
    if (range <= 10) return 2;
    if (range <= 50) return 10;
    if (range <= 100) return 20;
    return (range / 5).ceilToDouble();
  }
}
