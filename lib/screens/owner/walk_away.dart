import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _getStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.error(StateError('Firebase is not initialized.'));
    }
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('type', isEqualTo: 'walk_away')
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
            title: 'Walk-Away Metrics',
            subtitle: 'Queue Abandonment & Drop-Offs',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.info_outline_rounded,
                  color: AppTheme.textSecondary),
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
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                          'Unable to load walk-away analytics: ${snapshot.error}',
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
                final recordedWalkAways = chartData.fold<double>(
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
                            title: 'Walk-Away Rate',
                            value: 'No data',
                            subtitle:
                                'No total queue-arrival denominator is recorded',
                            icon: Icons.person_off_outlined,
                            iconColor: AppTheme.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Lost Parties',
                            value: chartData.isEmpty
                                ? 'No data'
                                : recordedWalkAways.toStringAsFixed(0),
                            subtitle:
                                'Sum of selected-period walk-away records',
                            icon: Icons.directions_walk_rounded,
                            iconColor: AppTheme.warning,
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
                      primaryColor: AppTheme.error,
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
                          if (chartData.isEmpty)
                            const Text(
                                'No walk-away detail data available for the selected period.',
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
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
        Text(
          count,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}
