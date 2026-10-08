import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/analytics_filter.dart';

/// Customer Turnover Analytics Screen faithful to Assignment 2 prototype
class CustomerTurnoverScreen extends StatefulWidget {
  final String restaurantId;

  const CustomerTurnoverScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<CustomerTurnoverScreen> createState() => _CustomerTurnoverScreenState();
}

class _CustomerTurnoverScreenState extends State<CustomerTurnoverScreen> {
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
        ChartDataPoint(label: 'Mon', value: 2.8, displayValue: '2.8x'),
        ChartDataPoint(label: 'Tue', value: 3.1, displayValue: '3.1x'),
        ChartDataPoint(label: 'Wed', value: 3.0, displayValue: '3.0x'),
        ChartDataPoint(label: 'Thu', value: 3.4, displayValue: '3.4x'),
        ChartDataPoint(label: 'Fri', value: 4.2, displayValue: '4.2x'),
        ChartDataPoint(label: 'Sat', value: 4.6, displayValue: '4.6x'),
        ChartDataPoint(label: 'Sun', value: 3.9, displayValue: '3.9x'),
      ];
    } else if (_selectedPeriod == 'This Month') {
      return const [
        ChartDataPoint(label: 'W1', value: 3.2, displayValue: '3.2x'),
        ChartDataPoint(label: 'W2', value: 3.5, displayValue: '3.5x'),
        ChartDataPoint(label: 'W3', value: 3.3, displayValue: '3.3x'),
        ChartDataPoint(label: 'W4', value: 3.8, displayValue: '3.8x'),
      ];
    }
    return const [
      ChartDataPoint(label: 'T1-T4', value: 4.2, displayValue: '4.2x'),
      ChartDataPoint(label: 'T5-T8', value: 3.8, displayValue: '3.8x'),
      ChartDataPoint(label: 'T9-T12', value: 3.5, displayValue: '3.5x'),
      ChartDataPoint(label: 'T13-T16', value: 2.9, displayValue: '2.9x'),
      ChartDataPoint(label: 'T17-T20', value: 2.4, displayValue: '2.4x'),
      ChartDataPoint(label: 'T21-T24', value: 3.1, displayValue: '3.1x'),
    ];
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _getStream() {
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'turnover')
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
            title: 'Customer Turnover',
            subtitle: 'Table Rotation & Dining Duration',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Customer Turnover'),
                    content: const Text(
                      'Turnover measures how many times a dining table is occupied by different parties per service shift.',
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
                            title: 'Avg Daily Turnover',
                            value: _selectedPeriod == 'Today' ? '3.4x' : '3.6x',
                            subtitle: 'Turns per active table',
                            icon: Icons.loop_rounded,
                            iconColor: const Color(0xFF059669),
                            trendText: '+0.4x',
                            isPositiveTrend: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Avg Dining Duration',
                            value: '42 min',
                            subtitle: '-5 min vs target duration',
                            icon: Icons.hourglass_bottom_rounded,
                            iconColor: const Color(0xFF2563EB),
                            trendText: '-5 min',
                            isPositiveTrend: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    ChartCard(
                      title: _selectedPeriod == 'Today'
                          ? 'Turnover Rate per Table Group'
                          : 'Turnover Rate Trend',
                      subtitle: 'Number of seated groups served per table',
                      data: chartData,
                      chartType: ChartType.bar,
                      primaryColor: const Color(0xFF059669),
                      unit: 'Rate',
                    ),
                      const SizedBox(height: 20),

                      // Dining duration segment performance
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
                              'Seating Efficiency by Party Size',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildEfficiencyRow('2-Person Tables', '32 min avg', '4.2 turns/day', AppTheme.success),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildEfficiencyRow('4-Person Tables', '46 min avg', '3.4 turns/day', AppTheme.primary),
                            const Divider(height: 20, color: AppTheme.cardBorder),
                            _buildEfficiencyRow('6+ Group Tables', '68 min avg', '2.1 turns/day', const Color(0xFFD97706)),
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

  Widget _buildEfficiencyRow(String label, String duration, String turns, Color indicatorColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
            ),
          ],
        ),
        Row(
          children: [
            Text(duration, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            Text(turns, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          ],
        ),
      ],
    );
  }
}
