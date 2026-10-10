import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// Single data point for analytics charts
class ChartDataPoint {
  final String label;
  final double value;
  final String? displayValue;
  final String? sortKey;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.displayValue,
    this.sortKey,
  });
}

List<ChartDataPoint> normalizeChartData(List<ChartDataPoint> data) {
  final points = data
      .where((point) =>
          point.label.trim().isNotEmpty &&
          point.value.isFinite &&
          point.value >= 0)
      .toList();
  int? timeMinutes(String label) {
    final match =
        RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?$', caseSensitive: false)
            .firstMatch(label.trim());
    if (match == null) return null;
    var hour = int.parse(match.group(1)!);
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final meridiem = match.group(3)?.toUpperCase();
    if (meridiem == 'AM' && hour == 12) hour = 0;
    if (meridiem == 'PM' && hour < 12) hour += 12;
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  const weekdays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  int? categoryOrder(String label) {
    final normalized = label.trim().toLowerCase();
    final weekday = weekdays.indexWhere(normalized.startsWith);
    if (weekday >= 0) return weekday;
    final week = RegExp(r'^w(\d+)$').firstMatch(normalized);
    if (week != null) return int.parse(week.group(1)!);
    return null;
  }

  points.sort((a, b) {
    final aKey = a.sortKey ?? a.label;
    final bKey = b.sortKey ?? b.label;
    final aDate = DateTime.tryParse(aKey);
    final bDate = DateTime.tryParse(bKey);
    if (aDate != null && bDate != null) {
      final dateComparison = aDate.compareTo(bDate);
      if (dateComparison != 0) return dateComparison;
    }
    if (aDate != null && bDate == null) return -1;
    if (aDate == null && bDate != null) return 1;
    final aTime = timeMinutes(a.label);
    final bTime = timeMinutes(b.label);
    if (aTime != null && bTime != null) return aTime.compareTo(bTime);
    final aCategory = categoryOrder(a.label);
    final bCategory = categoryOrder(b.label);
    if (aCategory != null && bCategory != null) {
      return aCategory.compareTo(bCategory);
    }
    return aKey.compareTo(bKey);
  });
  return points;
}

/// Chart style mode
enum ChartType { bar, line }

/// Clean, responsive, lightweight analytics chart card built purely with Flutter built-ins.
/// Eliminates heavy third-party chart dependencies while guaranteeing rock-solid responsiveness.
class ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<ChartDataPoint> data;
  final ChartType chartType;
  final Color primaryColor;
  final double height;
  final String? unit;

  const ChartCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.data,
    this.chartType = ChartType.bar,
    this.primaryColor = AppTheme.primary,
    this.height = 190,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = normalizeChartData(data);
    if (chartData.isEmpty) {
      return Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: const Center(
          child: Text(
            'No analytics data available for selected period',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    final maxValue = chartData.map((e) => e.value).reduce(math.max);
    final normalizedMax = maxValue == 0 ? 1.0 : maxValue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surfaceElevated,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (unit != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: height,
            child: chartType == ChartType.bar
                ? _buildBarChart(chartData, normalizedMax)
                : _buildLineChart(chartData, normalizedMax),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<ChartDataPoint> points, double maxVal) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: points.map((dp) {
        final heightRatio =
            dp.value == 0 ? 0.0 : (dp.value / maxVal).clamp(0.05, 1.0);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  dp.displayValue ?? '${dp.value.round()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barHeight = constraints.maxHeight * heightRatio;
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 22,
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                primaryColor,
                                primaryColor.withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dp.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLineChart(List<ChartDataPoint> points, double maxVal) {
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(
        data: points,
        maxVal: maxVal,
        lineColor: primaryColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points.map((dp) {
              return Expanded(
                child: Text(
                  dp.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<ChartDataPoint> data;
  final double maxVal;
  final Color lineColor;

  _SparklinePainter({
    required this.data,
    required this.maxVal,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final bottomPadding = 24.0;
    final topPadding = 16.0;
    final chartHeight = size.height - bottomPadding - topPadding;
    final stepX = size.width / (data.length - 1);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, topPadding, size.width, chartHeight))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotInnerPaint = Paint()
      ..color = AppTheme.textPrimary
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final ratio = (data[i].value / maxVal).clamp(0.0, 1.0);
      final y = topPadding + (chartHeight * (1.0 - ratio));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, topPadding + chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * stepX, topPadding + chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Draw data points
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final ratio = (data[i].value / maxVal).clamp(0.0, 1.0);
      final y = topPadding + (chartHeight * (1.0 - ratio));

      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => true;
}
