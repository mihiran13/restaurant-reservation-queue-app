import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../theme.dart';
import '../../data/firebase_data.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/owner_navigation.dart';

import 'owner_login.dart';
import 'peak_hours.dart';
import 'customer_turnover.dart';
import 'walk_away.dart';
import 'waiting_time.dart';
import 'no_show.dart';
import 'operational_reports.dart';
import 'settings_screen.dart';
import 'staff_management_screen.dart';
import 'staff_allocation_screen.dart';

/// Owner Dashboard connected to Firestore analytics.
class OwnerDashboardScreen extends StatefulWidget {
  final String restaurantId;

  const OwnerDashboardScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentNavIndex = 0;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to sign out from the Owner Portal?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const OwnerLoginScreen(),
        ),
      );
    }
  }

  void _onNavigationChanged(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    if (index == 1) {
      _showAnalyticsMenu();
    } else if (index == 2) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) =>
              StaffManagementScreen(restaurantId: widget.restaurantId),
        ),
      )
          .then((_) {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
    } else if (index == 3) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) =>
              OperationalReportsScreen(restaurantId: widget.restaurantId),
        ),
      )
          .then((_) {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
    } else if (index == 4) {
      Navigator.of(context)
          .push(
        MaterialPageRoute(
          builder: (_) => SettingsScreen(restaurantId: widget.restaurantId),
        ),
      )
          .then((_) {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
    }
  }

  void _showAnalyticsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Owner Analytics Dashboards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _analyticsMenuItem(
                  ctx,
                  Icons.schedule_rounded,
                  'Peak Hours',
                  'Hourly customer influx patterns',
                  PeakHoursScreen(restaurantId: widget.restaurantId),
                  AppTheme.accentBlue,
                ),
                _analyticsMenuItem(
                  ctx,
                  Icons.loop_rounded,
                  'Customer Turnover',
                  'Table rotation and dining durations',
                  CustomerTurnoverScreen(restaurantId: widget.restaurantId),
                  AppTheme.accentGreen,
                ),
                _analyticsMenuItem(
                  ctx,
                  Icons.person_off_outlined,
                  'Walk-Away Metrics',
                  'Queue drop-offs and lost parties',
                  WalkAwayScreen(restaurantId: widget.restaurantId),
                  AppTheme.error,
                ),
                _analyticsMenuItem(
                  ctx,
                  Icons.timer_outlined,
                  'Average Waiting Time',
                  'Customer check-in to seating delay',
                  WaitingTimeScreen(restaurantId: widget.restaurantId),
                  AppTheme.warning,
                ),
                _analyticsMenuItem(
                  ctx,
                  Icons.event_busy_rounded,
                  'No-Show Rate',
                  'Unfulfilled reservations analysis',
                  NoShowScreen(restaurantId: widget.restaurantId),
                  AppTheme.primary,
                ),
                ListTile(
                  leading: const Icon(
                    Icons.people_alt_rounded,
                    color: AppTheme.primary,
                  ),
                  title: const Text(
                    'Staff Allocation & Scheduling',
                  ),
                  subtitle: const Text(
                    'Demand-based staff shift allocation',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StaffAllocationScreen(
                            restaurantId: widget.restaurantId),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _currentNavIndex = 0);
      }
    });
  }

  Widget _analyticsMenuItem(
    BuildContext ctx,
    IconData icon,
    String title,
    String subtitle,
    Widget screen,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        Navigator.of(ctx).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getSettingsStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.error(StateError('Firebase is not initialized.'));
    }
    try {
      return FirebaseFirestore.instance
          .collection('settings')
          .doc(widget.restaurantId)
          .snapshots();
    } catch (error) {
      return Stream.error(error);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getAnalyticsStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.error(StateError('Firebase is not initialized.'));
    }
    try {
      return FirebaseFirestore.instance
          .collection('analytics')
          .where(
            'restaurantId',
            isEqualTo: widget.restaurantId,
          )
          .where('period', isEqualTo: 'Today')
          .snapshots();
    } catch (error) {
      return Stream.error(error);
    }
  }

  User? get _currentUser =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser;

  double? _averageMetric(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String type,
  ) {
    final values = docs
        .where((doc) =>
            doc.data()['type'] == type && doc.data()['period'] == 'Today')
        .map((doc) => doc.data()['value'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .where((value) => value.isFinite && value >= 0)
        .toList();

    if (values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _peakHourRecord(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    QueryDocumentSnapshot<Map<String, dynamic>>? peakRecord;
    var peakValue = double.negativeInfinity;

    for (final doc in docs) {
      final data = doc.data();
      final value = data['value'];
      if (data['type'] != 'peak_hours' ||
          data['period'] != 'Today' ||
          value is! num ||
          !value.isFinite ||
          value < 0) {
        continue;
      }

      final numericValue = value.toDouble();
      if (peakRecord == null || numericValue > peakValue) {
        peakRecord = doc;
        peakValue = numericValue;
      }
    }

    return peakRecord;
  }

  String _formatMetric(double? value, {String suffix = ''}) {
    if (value == null) return 'No data';

    return '${value.toStringAsFixed(1)}$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final ownerEmail = _currentUser?.email ?? 'Owner account';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Owner Dashboard',
            subtitle: 'Overview & Analytics',
            trailing: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppTheme.textSecondary,
              ),
              tooltip: 'Sign Out',
              onPressed: _handleLogout,
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _getSettingsStream(),
              builder: (context, settingsSnapshot) {
                if (settingsSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load restaurant settings.\n${settingsSnapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ),
                  );
                }
                if (settingsSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !settingsSnapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.primary));
                }
                final settings = settingsSnapshot.data?.data() ?? {};

                final restaurantName =
                    settings['restaurantName'] ?? 'Restaurant';

                final branchName = settings['branchName'] ?? 'Branch not set';

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _getAnalyticsStream(),
                  builder: (context, analyticsSnapshot) {
                    if (analyticsSnapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Unable to load analytics data.\n'
                            '${analyticsSnapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      );
                    }

                    if (analyticsSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !analyticsSnapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    final docs = analyticsSnapshot.data?.docs ?? [];
                    final analyticsRecords = docs
                        .map((doc) =>
                            AnalyticsRecord.fromMap(doc.data(), doc.id))
                        .toList();
                    final totalGuests =
                        AnalyticsMetrics.totalGuestsFromTodayPeakBuckets(
                      analyticsRecords,
                    );
                    final peakHour = _peakHourRecord(docs);
                    final peakHourData = peakHour?.data();
                    final peakHourLabel =
                        peakHourData?['label']?.toString().trim();
                    final peakHourValue = peakHourData?['value'];
                    final peakHourDisplay = peakHourLabel?.isNotEmpty == true
                        ? peakHourLabel!
                        : 'No data';
                    final peakHourSubtitle = peakHourData == null
                        ? 'No peak-hour records available today'
                        : peakHourLabel?.isNotEmpty == true
                            ? 'Highest recorded guest flow: ${peakHourData['displayValue'] ?? peakHourValue}'
                            : 'Peak-hour record is missing its hour label';

                    final waitingAverage = _averageMetric(docs, 'waiting_time');

                    final turnoverAverage = _averageMetric(docs, 'turnover');

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      color: AppTheme.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildRestaurantBanner(
                            restaurantName.toString(),
                            branchName.toString(),
                            ownerEmail,
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Key Performance Indicators',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'Available analytics',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.15,
                            children: [
                              KpiCard(
                                title: 'Total Guests',
                                value: totalGuests?.toString() ?? 'No data',
                                subtitle: totalGuests == null
                                    ? 'Requires distinct Today peak-hour guest buckets'
                                    : 'Sum of ${analyticsRecords.where((r) => r.type == 'peak_hours' && r.period == 'Today').length} guest buckets today',
                                icon: Icons.people_outline_rounded,
                                iconColor: AppTheme.accentBlue,
                              ),
                              KpiCard(
                                title: 'Peak Hour',
                                value: peakHourDisplay,
                                subtitle: peakHourSubtitle,
                                icon: Icons.schedule_rounded,
                                iconColor: AppTheme.primary,
                              ),
                              KpiCard(
                                title: 'Avg Waiting Time',
                                value: _formatMetric(
                                  waitingAverage,
                                  suffix: ' min',
                                ),
                                subtitle: 'Mean of today\'s analytics records',
                                icon: Icons.timer_outlined,
                                iconColor: AppTheme.warning,
                              ),
                              KpiCard(
                                title: 'Turnover Rate',
                                value: _formatMetric(
                                  turnoverAverage,
                                  suffix: 'x',
                                ),
                                subtitle: 'Mean of today\'s analytics records',
                                icon: Icons.loop_rounded,
                                iconColor: AppTheme.accentGreen,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Quick Reports & Deep-Dives',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildQuickAccessTile(
                            title: 'Peak Hours & Waiting Time',
                            subtitle: 'Hourly guest influx and queue patterns',
                            icon: Icons.schedule_rounded,
                            color: AppTheme.accentBlue,
                            onTap: () => _openScreen(
                              PeakHoursScreen(
                                  restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'Customer Turnover & Table Rotation',
                            subtitle: 'Table rotation and seating efficiency',
                            icon: Icons.loop_rounded,
                            color: AppTheme.accentGreen,
                            onTap: () => _openScreen(
                              CustomerTurnoverScreen(
                                  restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'Walk-Away & Queue Abandonment',
                            subtitle: 'Queue drop-offs and lost parties',
                            icon: Icons.person_off_outlined,
                            color: AppTheme.error,
                            onTap: () => _openScreen(
                              WalkAwayScreen(restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'Average Waiting Time Analysis',
                            subtitle: 'Check-in to seating delay',
                            icon: Icons.timer_outlined,
                            color: AppTheme.warning,
                            onTap: () => _openScreen(
                              WaitingTimeScreen(
                                  restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'No-Show Rate',
                            subtitle: 'Unfulfilled reservation analysis',
                            icon: Icons.event_busy_rounded,
                            color: AppTheme.primary,
                            onTap: () => _openScreen(
                              NoShowScreen(restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'Staff Allocation & Scheduling',
                            subtitle: 'Staff shifts, allocation and rules',
                            icon: Icons.badge_outlined,
                            color: AppTheme.primary,
                            onTap: () => _openScreen(
                              StaffAllocationScreen(
                                  restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'Operational Reports & Shift Audits',
                            subtitle: 'Management reports and shift audits',
                            icon: Icons.description_outlined,
                            color: AppTheme.secondary,
                            onTap: () => _openScreen(
                              OperationalReportsScreen(
                                  restaurantId: widget.restaurantId),
                            ),
                          ),
                          _buildQuickAccessTile(
                            title: 'Restaurant Settings',
                            subtitle: 'Operating hours and restaurant capacity',
                            icon: Icons.tune_rounded,
                            color: AppTheme.primary,
                            onTap: () => _openScreen(
                              SettingsScreen(restaurantId: widget.restaurantId),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          OwnerNavigation(
            currentIndex: _currentNavIndex,
            onItemSelected: _onNavigationChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantBanner(
    String restaurantName,
    String branchName,
    String ownerEmail,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurantName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$branchName • $ownerEmail',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget _buildQuickAccessTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
