import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  List<ChartDataPoint> _getFallbackData() {
    if (_selectedPeriod == 'This Week') {
      return const [
        ChartDataPoint(label: 'Mon', value: 2, displayValue: '2'),
        ChartDataPoint(label: 'Tue', value: 1, displayValue: '1'),
        ChartDataPoint(label: 'Wed', value: 3, displayValue: '3'),
        ChartDataPoint(label: 'Thu', value: 4, displayValue: '4'),
        ChartDataPoint(label: 'Fri', value: 7, displayValue: '7'),
        ChartDataPoint(label: 'Sat', value: 9, displayValue: '9'),
        ChartDataPoint(label: 'Sun', value: 5, displayValue: '5'),
      ];
    } else if (_selectedPeriod == 'This Month') {
      return const [
        ChartDataPoint(label: 'W1', value: 18, displayValue: '18'),
        ChartDataPoint(label: 'W2', value: 24, displayValue: '24'),
        ChartDataPoint(label: 'W3', value: 15, displayValue: '15'),
        ChartDataPoint(label: 'W4', value: 14, displayValue: '14'),
      ];
    }
    return const [
      ChartDataPoint(label: 'Lunch', value: 2, displayValue: '2'),
      ChartDataPoint(label: 'Early Din', value: 1, displayValue: '1'),
      ChartDataPoint(label: 'Prime Din', value: 4, displayValue: '4'),
      ChartDataPoint(label: 'Late Din', value: 1, displayValue: '1'),
    ];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getStream() {
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'no_show')
          .where('period', isEqualTo: _selectedPeriod)
          .snapshots();
    } catch (_) {
      return null;
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
              icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
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
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }

                List<ChartDataPoint> chartData = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  chartData = snapshot.data!.docs.map((doc) {
                    final data = doc.data();
                    return ChartDataPoint(
                      label: data['label'] ?? '',
                      value: (data['value'] is num) ? (data['value'] as num).toDouble() : 0.0,
                      displayValue: data['displayValue']?.toString(),
                    );
                  }).toList();
                }

                if (chartData.isEmpty) {
                  chartData = _getFallbackData();
                }

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
                              value: _selectedPeriod == 'Today' ? '4.8%' : '5.5%',
                              subtitle: '-0.8% reduction this week',
                              icon: Icons.event_busy_rounded,
                              iconColor: const Color(0xFFEF4444),
                              trendText: '-0.8%',
                              isPositiveTrend: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: KpiCard(
                              title: 'Unfulfilled Bookings',
                              value: _selectedPeriod == 'Today' ? '4 Bookings' : '31 Bookings',
                              subtitle: 'Est. lost covers: 14',
                              icon: Icons.cancel_schedule_send_rounded,
                              iconColor: const Color(0xFFD97706),
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
                            _buildSourceRow('Mobile App Bookings', '2 no-shows', '3.1%', AppTheme.success),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildSourceRow('Direct Phone Reservations', '2 no-shows', '7.4%', const Color(0xFFD97706)),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildSourceRow('Third-party Platforms', '0 no-shows', '0.0%', AppTheme.primary),
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

  Widget _buildSourceRow(String channel, String count, String rate, Color rateColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: rateColor),
          ),
        ),
      ],
    );
  }
}
