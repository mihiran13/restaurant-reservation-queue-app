import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/analytics_filter.dart';

/// Peak Hours Analytics Screen faithful to Assignment 2 prototype
class PeakHoursScreen extends StatefulWidget {
  final String restaurantId;

  const PeakHoursScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<PeakHoursScreen> createState() => _PeakHoursScreenState();
}

class _PeakHoursScreenState extends State<PeakHoursScreen> {
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
          .where('type', isEqualTo: 'peak_hours')
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
            title: 'Peak Hours',
            subtitle: 'Hourly Customer Flow & Influx',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Peak Hours Metric'),
                    content: const Text(
                      'Peak hours reflect table occupancy surges and incoming queue density to assist with staff shift scheduling.',
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
                          'Unable to load peak-hour analytics: ${snapshot.error}',
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
                final peakPoint = chartData.isEmpty
                    ? null
                    : chartData.reduce((a, b) => a.value >= b.value ? a : b);

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Filter Control
                    AnalyticsFilter(
                      selectedOption: _selectedPeriod,
                      onSelected: _onPeriodChanged,
                    ),
                    const SizedBox(height: 20),

                    // Metric Cards
                    Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            title: 'Peak Time Window',
                            value: peakPoint?.label ?? 'No data',
                            subtitle: 'Label of the highest recorded value',
                            icon: Icons.schedule_rounded,
                            iconColor: AppTheme.accentBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Peak Volume',
                            value: peakPoint?.displayValue ??
                                peakPoint?.value.toStringAsFixed(0) ??
                                'No data',
                            subtitle: 'Highest recorded analytics value',
                            icon: Icons.groups_rounded,
                            iconColor: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bar Chart
                    ChartCard(
                      title: 'Guest Traffic Distribution',
                      subtitle: _selectedPeriod == 'Today'
                          ? 'Volume distribution across lunch and dinner shifts'
                          : 'Volume trends over selected period',
                      data: chartData,
                      chartType: ChartType.bar,
                      primaryColor: AppTheme.accentBlue,
                      unit: 'Guests',
                    ),
                    const SizedBox(height: 20),

                    // Shift Breakdown Card
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
                            'Shift Analysis',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            peakPoint == null
                                ? 'No peak-hour data available for the selected period.'
                                : 'Peak category: ${peakPoint.label} (${peakPoint.displayValue ?? peakPoint.value.toStringAsFixed(0)}).',
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                          ),
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
}
