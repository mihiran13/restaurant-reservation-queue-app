import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  List<ChartDataPoint> _getFallbackData() {
    if (_selectedPeriod == 'This Week') {
      return const [
        ChartDataPoint(label: 'Mon', value: 14, displayValue: '14m'),
        ChartDataPoint(label: 'Tue', value: 16, displayValue: '16m'),
        ChartDataPoint(label: 'Wed', value: 15, displayValue: '15m'),
        ChartDataPoint(label: 'Thu', value: 18, displayValue: '18m'),
        ChartDataPoint(label: 'Fri', value: 26, displayValue: '26m'),
        ChartDataPoint(label: 'Sat', value: 31, displayValue: '31m'),
        ChartDataPoint(label: 'Sun', value: 22, displayValue: '22m'),
      ];
    } else if (_selectedPeriod == 'This Month') {
      return const [
        ChartDataPoint(label: 'W1', value: 19, displayValue: '19m'),
        ChartDataPoint(label: 'W2', value: 21, displayValue: '21m'),
        ChartDataPoint(label: 'W3', value: 17, displayValue: '17m'),
        ChartDataPoint(label: 'W4', value: 18, displayValue: '18m'),
      ];
    }
    return const [
      ChartDataPoint(label: '12 PM', value: 12, displayValue: '12m'),
      ChartDataPoint(label: '1 PM', value: 22, displayValue: '22m'),
      ChartDataPoint(label: '2 PM', value: 10, displayValue: '10m'),
      ChartDataPoint(label: '6 PM', value: 14, displayValue: '14m'),
      ChartDataPoint(label: '7 PM', value: 24, displayValue: '24m'),
      ChartDataPoint(label: '8 PM', value: 29, displayValue: '29m'),
      ChartDataPoint(label: '9 PM', value: 15, displayValue: '15m'),
    ];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getStream() {
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'waiting_time')
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
            title: 'Average Waiting Time',
            subtitle: 'Check-In to Table Seating Delay',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
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
                            title: 'Current Avg Wait',
                            value: _selectedPeriod == 'Today' ? '18 min' : '20 min',
                            subtitle: 'Within 25 min SLA target',
                            icon: Icons.timer_outlined,
                            iconColor: const Color(0xFFD97706),
                            trendText: '-4 min',
                            isPositiveTrend: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Longest Wait Today',
                            value: '34 min',
                            subtitle: 'Occurred at 8:15 PM',
                            icon: Icons.hourglass_top_rounded,
                            iconColor: const Color(0xFFEF4444),
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
                      primaryColor: const Color(0xFFD97706),
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
                            _buildDistributionRow('Seated under 10 mins', '45 parties', '62%', AppTheme.success),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildDistributionRow('Seated in 10 - 25 mins', '22 parties', '30%', const Color(0xFFF59E0B)),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildDistributionRow('Exceeded 25 mins', '6 parties', '8%', AppTheme.error),
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

  Widget _buildDistributionRow(String range, String parties, String percentage, Color color) {
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        ),
        Row(
          children: [
            Text(parties, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            Text(percentage, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ],
    );
  }
}
