import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/analytics_filter.dart';

/// No-Show Rate Analytics Screen faithful to Assignment 2 prototype
class NoShowScreen extends StatefulWidget {
  final String restaurantId;

  const NoShowScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<NoShowScreen> createState() => _NoShowScreenState();
}

class _NoShowScreenState extends State<NoShowScreen> {
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
          .where('type', isEqualTo: 'no_show')
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
            title: 'No-Show Rate',
            subtitle: 'Unfulfilled Reservations Analysis',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textSecondary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('No-Show Rate'),
                    content: const Text(
                      'No-shows represent booked reservations where guests did not arrive or cancel prior to their reservation grace period.',
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
                          'Unable to load no-show analytics: ${snapshot.error}',
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
                final recordedNoShows = chartData.fold<double>(
                    0, (total, point) => total + point.value);

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
                            title: 'No-Show Rate',
                            value: 'No data',
                            subtitle:
                                'No eligible-reservation denominator is recorded',
                            icon: Icons.event_busy_rounded,
                            iconColor: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Recorded No-Shows',
                            value: chartData.isEmpty
                                ? 'No data'
                                : recordedNoShows.toStringAsFixed(0),
                            subtitle: 'Sum of current-period no-show records',
                            icon: Icons.cancel_schedule_send_rounded,
                            iconColor: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ChartCard(
                      title: 'No-Shows by Dining Shift',
                      subtitle: 'Breakdown of unfulfilled bookings',
                      data: chartData,
                      chartType: ChartType.bar,
                      primaryColor: const Color(0xFFEF4444),
                      unit: 'Bookings',
                    ),
                    const SizedBox(height: 20),

                    // Channel breakdown
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
                            'Booking Source No-Show Rates',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (chartData.isEmpty)
                            const Text('No no-show detail data available.',
                                style: TextStyle(color: AppTheme.textSecondary))
                          else
                            ...chartData.map((point) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(point.label),
                                  trailing:
                                      Text(point.value.toStringAsFixed(0)),
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
  Widget _buildSourceRow(
      String channel, String count, String rate, Color rateColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channel,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style:
                  const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: rateColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rate,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: rateColor),
          ),
        ),
      ],
    );
  }
}
