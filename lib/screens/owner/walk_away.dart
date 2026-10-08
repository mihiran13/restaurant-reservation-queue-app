import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/analytics_filter.dart';

/// Walk-Away Metrics Analytics Screen faithful to Assignment 2 prototype
class WalkAwayScreen extends StatefulWidget {
  final String restaurantId;

  const WalkAwayScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<WalkAwayScreen> createState() => _WalkAwayScreenState();
}

class _WalkAwayScreenState extends State<WalkAwayScreen> {
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
        ChartDataPoint(label: 'Mon', value: 4, displayValue: '4'),
        ChartDataPoint(label: 'Tue', value: 5, displayValue: '5'),
        ChartDataPoint(label: 'Wed', value: 6, displayValue: '6'),
        ChartDataPoint(label: 'Thu', value: 7, displayValue: '7'),
        ChartDataPoint(label: 'Fri', value: 14, displayValue: '14'),
        ChartDataPoint(label: 'Sat', value: 18, displayValue: '18'),
        ChartDataPoint(label: 'Sun', value: 11, displayValue: '11'),
      ];
    } else if (_selectedPeriod == 'This Month') {
      return const [
        ChartDataPoint(label: 'W1', value: 38, displayValue: '38'),
        ChartDataPoint(label: 'W2', value: 42, displayValue: '42'),
        ChartDataPoint(label: 'W3', value: 31, displayValue: '31'),
        ChartDataPoint(label: 'W4', value: 29, displayValue: '29'),
      ];
    }
    return const [
      ChartDataPoint(label: '12 PM', value: 2, displayValue: '2'),
      ChartDataPoint(label: '1 PM', value: 4, displayValue: '4'),
      ChartDataPoint(label: '2 PM', value: 1, displayValue: '1'),
      ChartDataPoint(label: '6 PM', value: 3, displayValue: '3'),
      ChartDataPoint(label: '7 PM', value: 6, displayValue: '6'),
      ChartDataPoint(label: '8 PM', value: 8, displayValue: '8'),
      ChartDataPoint(label: '9 PM', value: 2, displayValue: '2'),
    ];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getStream() {
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'walk_away')
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
            title: 'Walk-Away Metrics',
            subtitle: 'Queue Abandonment & Drop-Offs',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Walk-Away Metrics'),
                    content: const Text(
                      'Walk-aways indicate waiting customers who left the queue before being assigned a dining table, usually due to excessive estimated wait times.',
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
                            title: 'Walk-Away Rate',
                            value: _selectedPeriod == 'Today' ? '5.2%' : '6.4%',
                            subtitle: '-1.4% improvement',
                            icon: Icons.person_off_outlined,
                            iconColor: const Color(0xFFEF4444),
                            trendText: '-1.4%',
                            isPositiveTrend: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Lost Parties',
                            value: _selectedPeriod == 'Today' ? '8 Parties' : '65 Parties',
                            subtitle: 'Avg wait before leaving: 24m',
                            icon: Icons.directions_walk_rounded,
                            iconColor: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ChartCard(
                      title: 'Queue Abandonment Occurrences',
                      subtitle: 'Walk-aways recorded across service hours',
                      data: chartData,
                      chartType: ChartType.bar,
                      primaryColor: const Color(0xFFEF4444),
                      unit: 'Parties',
                    ),
                      const SizedBox(height: 20),

                      // Walk-away threshold reasons
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
                              'Drop-Off Wait Duration Breakdown',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildReasonRow('Left within 10-15 mins', '2 parties (25%)', const Color(0xFF10B981)),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildReasonRow('Left within 15-30 mins', '4 parties (50%)', const Color(0xFFF59E0B)),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildReasonRow('Left after 30+ mins', '2 parties (25%)', const Color(0xFFEF4444)),
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

  Widget _buildReasonRow(String title, String count, Color color) {
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
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
