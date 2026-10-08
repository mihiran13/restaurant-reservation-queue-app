import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  List<ChartDataPoint> _getFallbackData() {
    if (_selectedPeriod == 'This Week') {
      return const [
        ChartDataPoint(label: 'Mon', value: 48, displayValue: '48'),
        ChartDataPoint(label: 'Tue', value: 55, displayValue: '55'),
        ChartDataPoint(label: 'Wed', value: 62, displayValue: '62'),
        ChartDataPoint(label: 'Thu', value: 70, displayValue: '70'),
        ChartDataPoint(label: 'Fri', value: 96, displayValue: '96'),
        ChartDataPoint(label: 'Sat', value: 110, displayValue: '110'),
        ChartDataPoint(label: 'Sun', value: 88, displayValue: '88'),
      ];
    } else if (_selectedPeriod == 'This Month') {
      return const [
        ChartDataPoint(label: 'W1', value: 340, displayValue: '340'),
        ChartDataPoint(label: 'W2', value: 410, displayValue: '410'),
        ChartDataPoint(label: 'W3', value: 460, displayValue: '460'),
        ChartDataPoint(label: 'W4', value: 520, displayValue: '520'),
      ];
    }
    return const [
      ChartDataPoint(label: '12 PM', value: 32, displayValue: '32'),
      ChartDataPoint(label: '1 PM', value: 45, displayValue: '45'),
      ChartDataPoint(label: '2 PM', value: 28, displayValue: '28'),
      ChartDataPoint(label: '6 PM', value: 38, displayValue: '38'),
      ChartDataPoint(label: '7 PM', value: 54, displayValue: '54'),
      ChartDataPoint(label: '8 PM', value: 68, displayValue: '68'),
      ChartDataPoint(label: '9 PM', value: 42, displayValue: '42'),
    ];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getStream() {
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'peak_hours')
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
            title: 'Peak Hours',
            subtitle: 'Hourly Customer Flow & Influx',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
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

                // If no custom documents in Firestore yet, show sensible fallback data
                if (chartData.isEmpty) {
                  chartData = _getFallbackData();
                }

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
                            value: _selectedPeriod == 'Today' ? '7:30 - 8:30 PM' : 'Fri & Sat Night',
                            subtitle: 'Busiest traffic window',
                            icon: Icons.schedule_rounded,
                            iconColor: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Peak Volume',
                            value: _selectedPeriod == 'Today' ? '68 Guests' : '110 Guests/hr',
                            subtitle: '+18% above average',
                            icon: Icons.groups_rounded,
                            iconColor: AppTheme.primary,
                            trendText: '+18%',
                            isPositiveTrend: true,
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
                      primaryColor: const Color(0xFF2563EB),
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
                            _buildShiftRow(
                              name: 'Lunch Rush (12:00 PM – 2:30 PM)',
                              guestCount: '105 guests',
                              utilization: '72% table capacity',
                              isPeak: false,
                            ),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildShiftRow(
                              name: 'Dinner Rush (6:30 PM – 9:30 PM)',
                              guestCount: '164 guests',
                              utilization: '95% table capacity',
                              isPeak: true,
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

  Widget _buildShiftRow({
    required String name,
    required String guestCount,
    required String utilization,
    required bool isPeak,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 38,
          decoration: BoxDecoration(
            color: isPeak ? AppTheme.primary : AppTheme.info,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                utilization,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          guestCount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
