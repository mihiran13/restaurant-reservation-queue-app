import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

/// Owner Dashboard / Home Screen faithful to Assignment 2 prototype
class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentNavIndex = 0;
  final DashboardSummary _summary = DashboardSummary.initial;

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out from the Owner Portal?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerLoginScreen()),
        );
      }
    }
  }

  void _onNavigationChanged(int index) {
    if (index == _currentNavIndex) return;

    setState(() {
      _currentNavIndex = index;
    });

    if (index == 1) {
      _showAnalyticsMenu();
      return;
    } else if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OperationalReportsScreen()),
      ).then((_) {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
      return;
    } else if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ).then((_) {
        if (mounted) setState(() => _currentNavIndex = 0);
      });
      return;
    }
  }

  void _showAnalyticsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                title: const Text('Peak Hours', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Hourly customer influx patterns'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PeakHoursScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.loop_rounded, color: Color(0xFF059669), size: 20),
                ),
                title: const Text('Customer Turnover', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Table rotation and dining durations'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CustomerTurnoverScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_off_outlined, color: Color(0xFFEF4444), size: 20),
                ),
                title: const Text('Walk-Away Metrics', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Queue drop-offs & lost parties'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WalkAwayScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_outlined, color: Color(0xFFD97706), size: 20),
                ),
                title: const Text('Average Waiting Time', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Customer check-in to seating delay'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WaitingTimeScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_busy_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                title: const Text('No-Show Rate', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Unfulfilled reservations analysis'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoShowScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _currentNavIndex = 0);
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _getSettingsStream() {
    try {
      return FirebaseFirestore.instance.collection('settings').doc('default_bistro_01').snapshots();
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentUser;
    final ownerEmail = currentUser?.email ?? 'owner@restaurant.com';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // App Header
          AppHeader(
            title: 'Owner Dashboard',
            subtitle: 'Overview & Service Status',
            trailing: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
              tooltip: 'Sign Out',
              onPressed: _handleLogout,
            ),
          ),

          // Main Scrollable Dashboard Content
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _getSettingsStream(),
              builder: (context, snapshot) {
                final settingsData = snapshot.data?.data();
                final restaurantName = settingsData?['restaurantName'] ?? 'The Grand Bistro';
                final branchName = settingsData?['branchName'] ?? 'Main Branch';
                final totalTables = settingsData?['maxSeatingCapacity'] ?? _summary.totalTables;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: AppTheme.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Restaurant Status Banner
                      Container(
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.success,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Live',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                  const SizedBox(height: 20),

                  // Section Title: Key Performance Indicators
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Key Performance Indicators',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2x2 KPI Grid matching Assignment 2 hierarchy
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
                        value: '${_summary.totalGuestsToday}',
                        subtitle: 'Walk-ins & reservations',
                        icon: Icons.people_outline_rounded,
                        iconColor: const Color(0xFF2563EB),
                        trendText: '+12%',
                        isPositiveTrend: true,
                      ),
                      KpiCard(
                        title: 'Avg Waiting Time',
                        value: _summary.avgWaitTime,
                        subtitle: 'From check-in to table',
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFFD97706),
                        trendText: '-4 min',
                        isPositiveTrend: true,
                      ),
                      KpiCard(
                        title: 'Turnover Rate',
                        value: '${_summary.turnoverRate}x',
                        subtitle: 'Turns per active table',
                        icon: Icons.loop_rounded,
                        iconColor: const Color(0xFF059669),
                        trendText: '+0.4',
                        isPositiveTrend: true,
                      ),
                      KpiCard(
                        title: 'Table Occupancy',
                        value: '${_summary.activeTables}/$totalTables',
                        subtitle: 'Capacity occupied',
                        icon: Icons.table_restaurant_outlined,
                        iconColor: AppTheme.primary,
                        trendText: 'Stable',
                        isPositiveTrend: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Live Operational Status Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Service Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Icon(Icons.more_horiz, color: AppTheme.textMuted),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildServiceStat(
                                'Occupied Tables',
                                '${_summary.activeTables}',
                                AppTheme.primary,
                              ),
                            ),
                            Container(width: 1, height: 36, color: AppTheme.cardBorder),
                            Expanded(
                              child: _buildServiceStat(
                                'Available Tables',
                                '${totalTables > _summary.activeTables ? totalTables - _summary.activeTables : 0}',
                                AppTheme.success,
                              ),
                            ),
                            Container(width: 1, height: 36, color: AppTheme.cardBorder),
                            Expanded(
                              child: _buildServiceStat(
                                'Waitlist Queues',
                                '6 groups',
                                const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Analytical Quick Navigation Cards
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
                    subtitle: 'Hourly guest influx patterns and table queues',
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF2563EB),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PeakHoursScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessTile(
                    title: 'Customer Turnover & Table Rotation',
                    subtitle: 'Seat utilization efficiency and party turnover',
                    icon: Icons.loop_rounded,
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CustomerTurnoverScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessTile(
                    title: 'Walk-Away & Queue Abandonment',
                    subtitle: 'Drop-offs and lost parties waiting in queue',
                    icon: Icons.person_off_outlined,
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WalkAwayScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessTile(
                    title: 'Average Waiting Time Analysis',
                    subtitle: 'Check-in to seating delay across service shifts',
                    icon: Icons.timer_outlined,
                    color: const Color(0xFFD97706),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WaitingTimeScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessTile(
                    title: 'No-Show Rate & Unfulfilled Bookings',
                    subtitle: 'Unfulfilled reservations by booking source',
                    icon: Icons.event_busy_rounded,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NoShowScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessTile(
                    title: 'Operational Reports & Shift Audits',
                    subtitle: 'Create, view, edit & delete management reports',
                    icon: Icons.description_outlined,
                    color: AppTheme.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OperationalReportsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessTile(
                    title: 'Restaurant Settings & Control Center',
                    subtitle: 'Operating hours, capacity & queue alerts',
                    icon: Icons.tune_rounded,
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),

          // Owner Bottom Navigation Bar
          OwnerNavigation(
            currentIndex: _currentNavIndex,
            onItemSelected: _onNavigationChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
