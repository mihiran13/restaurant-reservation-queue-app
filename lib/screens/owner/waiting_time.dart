import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/analytics_filter.dart';

/// Average Waiting Time Analytics Screen faithful to Assignment 2 prototype
class WaitingTimeScreen extends StatefulWidget {
  final String restaurantId;

  const WaitingTimeScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<WaitingTimeScreen> createState() => _WaitingTimeScreenState();
}

class _WaitingTimeScreenState extends State<WaitingTimeScreen> {
  String _selectedPeriod = 'Today';

  void _onPeriodChanged(String period) {
    if (period == _selectedPeriod) return;
    setState(() {
      _selectedPeriod = period;
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.error(StateError('Firebase is not initialized.'));
    }
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'waiting_time')
          .where('period', isEqualTo: _selectedPeriod)
          .snapshots();
    } catch (error) {
      return Stream.error(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Average Waiting Time',
            subtitle: 'Check-In to Table Seating Delay',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Average Waiting Time'),
                    content: const Text(
                      'Tracks the elapsed time between customer arrival check-in and when their designated table is ready and occupied.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'Unable to load waiting-time analytics: ${snapshot.error}',
                          textAlign: TextAlign.center));
                }

                final chartData =
                    normalizeChartData((snapshot.data?.docs ?? []).map((doc) {
                  final data = doc.data();
                  final value = data['value'];
                  final label = data['label']?.toString().trim();
                  return ChartDataPoint(
                    label: label == null || label.isEmpty ? doc.id : label,
                    value: value is num ? value.toDouble() : double.nan,
                    displayValue: data['displayValue']?.toString(),
                    sortKey: data['date']?.toString(),
                  );
                }).toList());
                final averageWait = chartData.isEmpty
                    ? null
                    : chartData.fold<double>(
                            0, (total, point) => total + point.value) /
                        chartData.length;
                final highestWait = chartData.isEmpty
                    ? null
                    : chartData.reduce((a, b) => a.value >= b.value ? a : b);

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AnalyticsFilter(
                      selectedOption: _selectedPeriod,
                      onSelected: _onPeriodChanged,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            title: 'Mean Recorded Wait',
                            value: averageWait == null
                                ? 'No data'
                                : '${averageWait.toStringAsFixed(1)} min',
                            subtitle:
                                'Unweighted mean of selected-period analytics points',
                            icon: Icons.timer_outlined,
                            iconColor: AppTheme.warning,
                            trendText: '-4 min',
                            isPositiveTrend: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Highest Recorded Value',
                            value: highestWait == null
                                ? 'No data'
                                : '${highestWait.value.toStringAsFixed(1)} min',
                            subtitle: highestWait?.label ??
                                'No waiting-time data available',
                            icon: Icons.hourglass_top_rounded,
                            iconColor: AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Line / Sparkline Chart for Waiting times
                    ChartCard(
                      title: 'Waiting Time Fluctuation',
                      subtitle: 'Average minutes in queue by hour of service',
                      data: chartData,
                      chartType: ChartType.line,
                      primaryColor: AppTheme.warning,
                      unit: 'Minutes',
                    ),
                    const SizedBox(height: 20),

                    // Wait Time Distribution
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Queue Wait Time Distribution',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (chartData.isEmpty)
                            const Text(
                                'No waiting-time detail data available for the selected period.',
                                style: TextStyle(color: AppTheme.textSecondary))
                          else
                            ...chartData.map((point) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(point.label),
                                  trailing: Text(
                                      '${point.value.toStringAsFixed(1)} min'),
                                )),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDistributionRow(
      String range, String parties, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              range,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
        Row(
          children: [
            Text(parties,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            Text(percentage,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ],
    );
  }
}
