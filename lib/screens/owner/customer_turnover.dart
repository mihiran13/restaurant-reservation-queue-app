import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../theme.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/analytics_filter.dart';

/// Customer Turnover Analytics Screen
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _getStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.error(StateError('Firebase is not initialized.'));
    }
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'turnover')
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
            title: 'Customer Turnover',
            subtitle: 'Table Rotation & Dining Duration',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(
                Icons.info_outline_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Customer Turnover'),
                    content: const Text(
                      'Turnover measures how many times a dining table '
                      'is occupied by different parties per service shift.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
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
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                    ),
                  );
                }

                // Show Firestore errors instead of hiding them.
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 42,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Unable to load turnover data',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Convert Firestore documents into chart points.
                final docs = snapshot.data?.docs ?? [];

                final chartData = normalizeChartData(docs.map((doc) {
                  final data = doc.data();
                  final rawValue = data['value'];
                  final label = data['label']?.toString().trim();

                  return ChartDataPoint(
                    label: label == null || label.isEmpty ? doc.id : label,
                    value: rawValue is num ? rawValue.toDouble() : double.nan,
                    displayValue: data['displayValue']?.toString(),
                    sortKey: data['date']?.toString(),
                  );
                }).toList());

                // Calculate average from available records.
                final averageTurnover = chartData.isEmpty
                    ? null
                    : chartData.fold<double>(
                          0,
                          (total, point) => total + point.value,
                        ) /
                        chartData.length;

                final averageTurnoverText = averageTurnover == null
                    ? 'No data'
                    : '${averageTurnover.toStringAsFixed(1)}x';

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    AnalyticsFilter(
                      selectedOption: _selectedPeriod,
                      onSelected: _onPeriodChanged,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: KpiCard(
                            title: 'Mean Turnover Value',
                            value: averageTurnoverText,
                            subtitle: chartData.isEmpty
                                ? 'No turnover records available'
                                : 'Arithmetic mean of ${chartData.length} $_selectedPeriod records',
                            icon: Icons.loop_rounded,
                            iconColor: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Avg Dining Duration',
                            value: 'No data',
                            subtitle:
                                'Turnover records contain no dining-duration field',
                            icon: Icons.hourglass_bottom_rounded,
                            iconColor: AppTheme.accentBlue,
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
                      primaryColor: AppTheme.accentGreen,
                      unit: 'Rate',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.cardBorder,
                        ),
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
                          if (chartData.isEmpty)
                            const Text(
                              'No turnover detail data available.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            )
                          else
                            Text(
                              '${chartData.length} turnover records '
                              'loaded for $_selectedPeriod.',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
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
