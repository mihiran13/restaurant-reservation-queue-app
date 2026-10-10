import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../data/staff_data.dart';
import '../../services/staff_allocation_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/owner_navigation.dart';
import 'operational_reports.dart';
import 'settings_screen.dart';
import 'staff_management_screen.dart';

/// Complete Staff Allocation & Scheduling Management System
/// Includes:
/// 1. Dashboard with demand prediction, shortage alerts, and hourly staffing timeline
/// 2. Staff Management CRUD (add, edit, delete, activate/deactivate, search/filter)
/// 3. Staff Allocation CRUD (create, edit, delete, filter, overlap validation)
/// 4. Peak Hour Management CRUD (configure weekly peak times and minimum staff)
/// 5. Allocation Rules CRUD (configurable customer-to-staff tiers)
class StaffAllocationScreen extends StatefulWidget {
  final String restaurantId;

  const StaffAllocationScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<StaffAllocationScreen> createState() => _StaffAllocationScreenState();
}

class _StaffAllocationScreenState extends State<StaffAllocationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StaffAllocationService _service = StaffAllocationService();

  // Selected date and time for recommendation inspection
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime =
      const TimeOfDay(hour: 19, minute: 0); // 7:00 PM default peak

  // Search & Filters for Staff
  String _staffSearchQuery = '';
  String _selectedStaffRoleFilter = 'All';
  String _selectedStaffStatusFilter = 'All';

  // Filters for Allocations
  String _selectedAllocDateFilter = '';
  String _selectedAllocRoleFilter = 'All';
  String _selectedAllocStatusFilter = 'All';

  // Roles & Departments constant lists
  final List<String> _roles = [
    'Manager',
    'Waiter',
    'Cashier',
    'Kitchen Staff',
    'Host',
    'Cleaner',
    'Other',
  ];

  final List<String> _departments = [
    'Dining Hall',
    'Kitchen',
    'Front Desk',
    'Counter',
    'Bar',
    'Sanitation',
  ];

  final List<String> _shiftTypes = ['Normal', 'Peak', 'Low Demand'];
  final List<String> _allocationStatuses = [
    'Scheduled',
    'Active',
    'Completed',
    'Cancelled'
  ];
  final List<String> _demandLevels = ['Low', 'Normal', 'High', 'Very High'];
  final List<String> _daysOfWeek = [
    'Everyday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _selectedAllocDateFilter = '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) => dt.toIso8601String().substring(0, 10);

  String _formatTime(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTimeDisplay(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final tod = TimeOfDay(hour: h, minute: m);
    return tod.format(context);
  }

  void _navigateMainSection(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 2) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              StaffManagementScreen(restaurantId: widget.restaurantId)));
    } else if (index == 3) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              OperationalReportsScreen(restaurantId: widget.restaurantId)));
    } else if (index == 4) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SettingsScreen(restaurantId: widget.restaurantId)));
    }
  }

  Color _getDemandColor(String level) {
    switch (level) {
      case 'Low':
        return AppTheme.info;
      case 'Normal':
        return AppTheme.success;
      case 'High':
        return AppTheme.warning;
      case 'Very High':
        return AppTheme.error;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppHeader(
            title: 'Staff Allocation',
            subtitle: 'Assign staff to a date and time period',
            showBackButton: true,
          ),
          Expanded(
            child: _buildAllocationsTab(),
          ),
        ],
      ),
      bottomNavigationBar: OwnerNavigation(
          currentIndex: 2, onItemSelected: _navigateMainSection),
    );
  }

  // ignore: unused_element
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.auto_graph_rounded, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Smart Staff Allocation',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This system dynamically links restaurant customer influx (reservations + live queue) with shift scheduling.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              '• Peak Hours → More staff allocated\n'
              '• Normal Hours → Standard staff allocation\n'
              '• Low-Demand Hours → Optimized staff allocation',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            SizedBox(height: 10),
            Text(
              'Double-booking and overlapping shifts are automatically detected and prevented.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DASHBOARD
  // ===========================================================================

  // ignore: unused_element
  Widget _buildDashboardTab() {
    final dateStr = _formatDate(_selectedDate);
    final timeStr = _formatTime(_selectedTime);

    return StreamBuilder<List<StaffMember>>(
      stream: _service.streamStaffMembers(widget.restaurantId),
      builder: (context, staffSnap) {
        if (staffSnap.hasError) {
          return Center(
              child: Text('Unable to load staff: ${staffSnap.error}'));
        }
        if (!staffSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final allStaff = staffSnap.data!;
        final activeStaff = allStaff.where((s) => s.isActive).toList();

        return StreamBuilder<List<StaffAllocation>>(
          stream:
              _service.streamAllocations(widget.restaurantId, date: dateStr),
          builder: (context, allocSnap) {
            if (allocSnap.hasError) {
              return Center(
                  child:
                      Text('Unable to load allocations: ${allocSnap.error}'));
            }
            if (!allocSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final allocations = allocSnap.data!;

            return StreamBuilder<List<PeakHourConfig>>(
              stream: _service.streamPeakHours(widget.restaurantId),
              builder: (context, peakSnap) {
                if (peakSnap.hasError) {
                  return Center(
                      child: Text(
                          'Unable to load peak-hour settings: ${peakSnap.error}'));
                }
                if (!peakSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final peakConfigs = peakSnap.data!;

                return StreamBuilder<List<StaffAllocationRule>>(
                  stream: _service.streamRules(widget.restaurantId),
                  builder: (context, ruleSnap) {
                    if (ruleSnap.hasError) {
                      return Center(
                          child: Text(
                              'Unable to load allocation rules: ${ruleSnap.error}'));
                    }
                    if (!ruleSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rules = ruleSnap.data!;
                    if (rules.isEmpty) {
                      return const Center(
                          child: Text('No allocation rules are configured.'));
                    }

                    return FutureBuilder<Map<String, int>>(
                      future:
                          StaffAllocationService.fetchReservationQueueDemand(
                        firestore: _service.firestore,
                        restaurantId: widget.restaurantId,
                        date: dateStr,
                        time: timeStr,
                      ),
                      builder: (context, demandSnap) {
                        if (demandSnap.hasError) {
                          return Center(
                              child: Text(
                                  'Unable to load reservation/queue demand: ${demandSnap.error}'));
                        }
                        if (!demandSnap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final demandData = demandSnap.data!;
                        final resCount = demandData['reservations'] ?? 0;
                        final queueCount = demandData['queue'] ?? 0;

                        // Calculate Smart Recommendation
                        final recommendation =
                            StaffAllocationService.calculateRecommendation(
                          date: _selectedDate,
                          time: timeStr,
                          reservations: resCount,
                          queue: queueCount,
                          peakConfigs: peakConfigs,
                          rules: rules,
                          allocationsOnDate: allocations,
                        );

                        // Calculate Dashboard statistics
                        final allocatedStaffIds = allocations
                            .where((a) => a.status != 'Cancelled')
                            .map((a) => a.staffId)
                            .toSet();
                        final totalAllocatedToday = allocatedStaffIds.length;
                        final availableToday =
                            activeStaff.length - totalAllocatedToday;

                        // Peak hours today
                        final dayName = StaffAllocationService.getDayOfWeekName(
                            _selectedDate);
                        final todayPeaks = peakConfigs
                            .where((p) =>
                                p.dayOfWeek == dayName ||
                                p.dayOfWeek == 'Everyday')
                            .toList();

                        return RefreshIndicator(
                          color: AppTheme.primary,
                          onRefresh: () async {
                            setState(() {});
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Date & Time Inspection Controller Card
                              _buildInspectionCard(dateStr),
                              const SizedBox(height: 14),

                              // Alert Banner (Shortage vs Satisfied)
                              _buildShortageBanner(
                                  recommendation, allStaff, allocations),
                              const SizedBox(height: 16),

                              // 2x3 KPI Summary Grid
                              const Text(
                                "Today's Staff Allocation Overview",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 10),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.25,
                                children: [
                                  KpiCard(
                                    title: 'Total Active Staff',
                                    value: '${activeStaff.length}',
                                    subtitle:
                                        'Out of ${allStaff.length} registered',
                                    icon: Icons.badge_outlined,
                                    iconColor: AppTheme.accentBlue,
                                  ),
                                  KpiCard(
                                    title: 'Allocated Today',
                                    value: '$totalAllocatedToday',
                                    subtitle: 'Working shifts today',
                                    icon: Icons.assignment_ind_outlined,
                                    iconColor: AppTheme.primary,
                                  ),
                                  KpiCard(
                                    title: 'Available Staff',
                                    value:
                                        '${availableToday >= 0 ? availableToday : 0}',
                                    subtitle: 'Unscheduled active staff',
                                    icon: Icons.person_add_alt_1_outlined,
                                    iconColor: AppTheme.success,
                                  ),
                                  KpiCard(
                                    title: 'Current Demand',
                                    value: recommendation.demandLevel,
                                    subtitle:
                                        '${recommendation.totalExpectedCustomers} exp. guests',
                                    icon: Icons.trending_up_rounded,
                                    iconColor: _getDemandColor(
                                        recommendation.demandLevel),
                                  ),
                                  KpiCard(
                                    title: 'Recommended Staff',
                                    value: '${recommendation.recommendedStaff}',
                                    subtitle: 'For $timeStr slot',
                                    icon: Icons.support_agent_rounded,
                                    iconColor: AppTheme.primary,
                                  ),
                                  KpiCard(
                                    title: 'Staff Shortage',
                                    value: recommendation.hasShortage
                                        ? '-${recommendation.shortage}'
                                        : '0 (OK)',
                                    subtitle: recommendation.hasShortage
                                        ? 'Requires action'
                                        : 'Staffing satisfied',
                                    icon: recommendation.hasShortage
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    iconColor: recommendation.hasShortage
                                        ? AppTheme.error
                                        : AppTheme.success,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Detailed Demand & Recommendation Analysis Card
                              _buildRecommendationDetailCard(recommendation,
                                  todayPeaks, allStaff, allocations),
                              const SizedBox(height: 20),

                              // Hourly Staff Allocation Timeline
                              _buildHourlyTimelineCard(
                                  rules, peakConfigs, allocations),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInspectionCard(String dateStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.schedule_rounded,
                      color: AppTheme.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Time Period Evaluation',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  StaffAllocationService.getDayOfWeekName(_selectedDate),
                  style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                        _selectedAllocDateFilter = _formatDate(picked);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.cardBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTime.format(context),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortageBanner(
    RecommendationResult rec,
    List<StaffMember> allStaff,
    List<StaffAllocation> allocations,
  ) {
    if (rec.hasShortage) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cancelledBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.textPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚠️ Staff Shortage Detected',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.error),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${rec.shortage} additional staff member${rec.shortage > 1 ? 's are' : ' is'} recommended for this ${rec.isPeakHour ? 'peak ' : ''}period.',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () =>
                  _showQuickAllocateModal(rec, allStaff, allocations),
              child: const Text('Allocate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.readyBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.45)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✓ Staffing Requirement Satisfied',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.success),
                ),
                SizedBox(height: 2),
                Text(
                  'Sufficient staff members are scheduled for the current expected restaurant demand.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationDetailCard(
    RecommendationResult rec,
    List<PeakHourConfig> todayPeaks,
    List<StaffMember> allStaff,
    List<StaffAllocation> allocations,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Demand & Staff Recommendation',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getDemandColor(rec.demandLevel).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Demand: ${rec.demandLevel.toUpperCase()}',
                  style: TextStyle(
                    color: _getDemandColor(rec.demandLevel),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildDemandPill('Reservations', '${rec.expectedReservations}',
                  Icons.bookmark_added_outlined),
              const SizedBox(width: 8),
              _buildDemandPill(
                  'Queue', '${rec.currentQueue}', Icons.people_outline_rounded),
              const SizedBox(width: 8),
              _buildDemandPill('Total Guests', '${rec.totalExpectedCustomers}',
                  Icons.restaurant_rounded),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.cardBorder),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatMetric(
                  'Recommended', '${rec.recommendedStaff}', AppTheme.primary),
              Container(width: 1, height: 32, color: AppTheme.cardBorder),
              _buildStatMetric('Currently Allocated', '${rec.allocatedStaff}',
                  AppTheme.accentBlue),
              Container(width: 1, height: 32, color: AppTheme.cardBorder),
              _buildStatMetric(
                rec.hasShortage ? 'Shortage' : 'Surplus',
                rec.hasShortage
                    ? '${rec.shortage}'
                    : '${(rec.allocatedStaff - rec.recommendedStaff).abs()}',
                rec.hasShortage ? AppTheme.error : AppTheme.success,
              ),
            ],
          ),
          if (rec.isPeakHour) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppTheme.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Configured Peak Period active (${_formatTimeDisplay(rec.matchedPeakConfig!.startTime)} - ${_formatTimeDisplay(rec.matchedPeakConfig!.endTime)}). Min staff requirement: ${rec.matchedPeakConfig!.minStaff}.',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Allocate Staff For This Period'),
              onPressed: () =>
                  _showQuickAllocateModal(rec, allStaff, allocations),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandPill(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatMetric(String label, String val, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildHourlyTimelineCard(
    List<StaffAllocationRule> rules,
    List<PeakHourConfig> peakConfigs,
    List<StaffAllocation> allocations,
  ) {
    // Generate hours 08:00 to 22:00
    final hours = List.generate(15, (index) => index + 8); // 8 to 22

    return Container(
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
                'Hourly Staff Allocation Schedule',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              Icon(Icons.view_timeline_outlined,
                  color: AppTheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Timeline comparing allocated staff with demand-driven recommendations.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hours.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.cardBorder),
            itemBuilder: (context, idx) {
              final h = hours[idx];
              final timeString = '${h.toString().padLeft(2, '0')}:00';
              final timeOfDay = TimeOfDay(hour: h, minute: 0);

              // Estimate demand based on hour
              int resCount = 3;
              int queueCount = 1;
              if (h >= 18 && h <= 21) {
                resCount = 22;
                queueCount = 5;
              } else if (h >= 12 && h <= 14) {
                resCount = 10;
                queueCount = 3;
              } else if (h >= 15 && h < 18) {
                resCount = 4;
                queueCount = 1;
              }

              final rec = StaffAllocationService.calculateRecommendation(
                date: _selectedDate,
                time: timeString,
                reservations: resCount,
                queue: queueCount,
                peakConfigs: peakConfigs,
                rules: rules,
                allocationsOnDate: allocations,
              );

              final isSelectedHour = _selectedTime.hour == h;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTime = timeOfDay;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelectedHour
                        ? AppTheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          timeOfDay.format(context),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelectedHour
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelectedHour
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (rec.isPeakHour)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PEAK',
                            style: TextStyle(
                                color: AppTheme.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${rec.allocatedStaff} Allocated',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary),
                            ),
                            const Text(' / ',
                                style: TextStyle(color: AppTheme.textMuted)),
                            Text(
                              '${rec.recommendedStaff} Rec.',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: rec.hasShortage
                                    ? AppTheme.error.withValues(alpha: 0.12)
                                    : AppTheme.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                rec.hasShortage
                                    ? '-${rec.shortage} Short'
                                    : 'OK',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: rec.hasShortage
                                      ? AppTheme.error
                                      : AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: STAFF MANAGEMENT CRUD
  // ===========================================================================

  // ignore: unused_element
  Widget _buildStaffTab() {
    return StreamBuilder<List<StaffMember>>(
      stream: _service.streamStaffMembers(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final staffList = snapshot.data ?? [];

        // Apply filters & search
        final filtered = staffList.where((s) {
          final matchesSearch = s.name
                  .toLowerCase()
                  .contains(_staffSearchQuery.toLowerCase()) ||
              s.role.toLowerCase().contains(_staffSearchQuery.toLowerCase()) ||
              s.department
                  .toLowerCase()
                  .contains(_staffSearchQuery.toLowerCase());

          final matchesRole = _selectedStaffRoleFilter == 'All' ||
              s.role == _selectedStaffRoleFilter;
          final matchesStatus = _selectedStaffStatusFilter == 'All' ||
              s.status == _selectedStaffStatusFilter;

          return matchesSearch && matchesRole && matchesStatus;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.person_add_alt_1_rounded,
                color: AppTheme.textPrimary),
            label: const Text('Add Staff',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
            onPressed: () => _showStaffDialog(),
          ),
          body: Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.surface,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search staff by name, role or area...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _staffSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () =>
                                    setState(() => _staffSearchQuery = ''),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) =>
                          setState(() => _staffSearchQuery = val),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStaffRoleFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter Role',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: ['All', ..._roles]
                                .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) => setState(
                                () => _selectedStaffRoleFilter = val ?? 'All'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStaffStatusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Filter Status',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: ['All', 'Active', 'Inactive']
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) => setState(() =>
                                _selectedStaffStatusFilter = val ?? 'All'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Staff List View
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'No Staff Members Found',
                        message:
                            'Try adjusting your search query or add a new staff member.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final staff = filtered[idx];
                          return _buildStaffCard(staff);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffCard(StaffMember staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: staff.isActive
                    ? AppTheme.primary.withValues(alpha: 0.12)
                    : AppTheme.textMuted.withValues(alpha: 0.2),
                child: Text(
                  staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: staff.isActive
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${staff.role} • ${staff.department}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // Active / Inactive switch badge
              InkWell(
                onTap: () async {
                  final newStatus = staff.isActive ? 'Inactive' : 'Active';
                  await _service.toggleStaffStatus(staff.id, newStatus);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${staff.name} is now $newStatus')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: staff.isActive
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.textMuted.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: staff.isActive
                              ? AppTheme.success
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        staff.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: staff.isActive
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppTheme.cardBorder),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text(staff.phone,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 12),
                  const Icon(Icons.timer_outlined,
                      size: 13, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Text('${staff.maxDailyHours}h max/day',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () => _showStaffDialog(staff: staff),
                    tooltip: 'Edit Staff Member',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.error),
                    onPressed: () => _confirmDeleteStaff(staff),
                    tooltip: 'Delete Staff Member',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showStaffDialog({StaffMember? staff}) async {
    final nameCtrl = TextEditingController(text: staff?.name ?? '');
    final phoneCtrl = TextEditingController(text: staff?.phone ?? '');
    final emailCtrl = TextEditingController(text: staff?.email ?? '');
    final maxHoursCtrl =
        TextEditingController(text: '${staff?.maxDailyHours ?? 8}');
    final fromCtrl =
        TextEditingController(text: staff?.availableFrom ?? '08:00');
    final toCtrl = TextEditingController(text: staff?.availableTo ?? '17:00');
    String role = staff?.role ?? _roles.first;
    String department = staff?.department ?? _departments.first;
    String status = staff?.status ?? 'Active';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                    staff == null
                        ? Icons.person_add_rounded
                        : Icons.edit_note_rounded,
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(staff == null ? 'Add Staff Member' : 'Edit Staff Member',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Full Name *'),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter staff name'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: role,
                            decoration:
                                const InputDecoration(labelText: 'Role *'),
                            items: _roles
                                .map((r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r,
                                        style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => role = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: department,
                            decoration: const InputDecoration(
                                labelText: 'Department *'),
                            items: _departments
                                .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d,
                                        style: const TextStyle(fontSize: 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => department = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Phone Number *'),
                      keyboardType: TextInputType.phone,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter phone'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Email Address *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => (val == null ||
                              val.trim().isEmpty ||
                              !val.contains('@'))
                          ? 'Valid email required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: fromCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Available From *'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: false),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter start time';
                              }
                              if (StaffAllocationService.timeToMinutes(
                                      val.trim()) <
                                  0) {
                                return 'Invalid start time';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: toCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Available To *'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: false),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter end time';
                              }
                              final fromMinutes =
                                  StaffAllocationService.timeToMinutes(
                                      fromCtrl.text.trim());
                              final toMinutes =
                                  StaffAllocationService.timeToMinutes(
                                      val.trim());
                              if (toMinutes <= fromMinutes) {
                                return 'Available end time must be later';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: maxHoursCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Maximum Working Hours *'),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        final num = int.tryParse(val ?? '');
                        if (num == null || num <= 0 || num > 24) {
                          return '1-24 hours';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: ['Active', 'Inactive']
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    final maxH = int.tryParse(maxHoursCtrl.text.trim()) ?? 8;
                    if (staff == null) {
                      final newStaff = StaffMember(
                        id: '',
                        restaurantId: widget.restaurantId,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        role: role,
                        department: department,
                        status: status,
                        availableHours:
                            '${fromCtrl.text.trim()} - ${toCtrl.text.trim()}',
                        availableFrom: fromCtrl.text.trim(),
                        availableTo: toCtrl.text.trim(),
                        maxDailyHours: maxH,
                      );
                      await _service.addStaffMember(newStaff);
                    } else {
                      final updated = staff.copyWith(
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        role: role,
                        department: department,
                        status: status,
                        availableHours:
                            '${fromCtrl.text.trim()} - ${toCtrl.text.trim()}',
                        availableFrom: fromCtrl.text.trim(),
                        availableTo: toCtrl.text.trim(),
                        maxDailyHours: maxH,
                      );
                      await _service.updateStaffMember(updated);
                    }
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(staff == null
                              ? 'Staff member added successfully'
                              : 'Staff member updated')),
                    );
                  }
                },
                child: Text(staff == null ? 'Add Staff' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteStaff(StaffMember staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Member',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to delete ${staff.name}? This will remove them from all scheduling lists.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteStaffMember(staff.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${staff.name} deleted')),
        );
      }
    }
  }

  // ===========================================================================
  // TAB 3: STAFF ALLOCATIONS CRUD
  // ===========================================================================

  Widget _buildAllocationsTab() {
    return StreamBuilder<List<StaffMember>>(
      stream: _service.streamStaffMembers(widget.restaurantId),
      builder: (context, staffSnap) {
        if (staffSnap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (staffSnap.hasError) {
          return Center(
              child: Text(
                  'Could not load staff from Firestore: ${staffSnap.error}'));
        }
        final allStaff = staffSnap.data ?? [];

        return StreamBuilder<List<StaffAllocation>>(
          stream: _service.streamAllocations(widget.restaurantId,
              date: _selectedAllocDateFilter),
          builder: (context, allocSnap) {
            if (allocSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary));
            }
            if (allocSnap.hasError) {
              return Center(
                  child: Text(
                      'Could not load allocations from Firestore: ${allocSnap.error}'));
            }

            final allocations = allocSnap.data ?? [];

            // Filter allocations
            final filtered = allocations.where((a) {
              final matchesRole = _selectedAllocRoleFilter == 'All' ||
                  a.staffRole == _selectedAllocRoleFilter;
              final matchesStatus = _selectedAllocStatusFilter == 'All' ||
                  a.status == _selectedAllocStatusFilter;
              return matchesRole && matchesStatus;
            }).toList();

            return Scaffold(
              backgroundColor: Colors.transparent,
              floatingActionButton: FloatingActionButton.extended(
                backgroundColor: AppTheme.primary,
                icon: const Icon(Icons.add_task_rounded,
                    color: AppTheme.textPrimary),
                label: const Text('New Allocation',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700)),
                onPressed: () => _showAllocationDialog(
                    allStaff: allStaff, existingAllocations: allocations),
              ),
              body: Column(
                children: [
                  // Filter header
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppTheme.surface,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.tryParse(
                                            _selectedAllocDateFilter) ??
                                        DateTime.now(),
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 90)),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedAllocDateFilter =
                                          _formatDate(picked);
                                    });
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: AppTheme.cardBorder),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_note_rounded,
                                          size: 16, color: AppTheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Date: ${_selectedAllocDateFilter.isEmpty ? 'All dates' : _selectedAllocDateFilter}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedAllocDateFilter =
                                      _formatDate(DateTime.now());
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Today',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedAllocRoleFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                items: ['All', ..._roles]
                                    .map((r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r,
                                            style:
                                                const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (val) => setState(() =>
                                    _selectedAllocRoleFilter = val ?? 'All'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedAllocStatusFilter,
                                decoration: const InputDecoration(
                                  labelText: 'Shift Status',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                items: ['All', ..._allocationStatuses]
                                    .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s,
                                            style:
                                                const TextStyle(fontSize: 12))))
                                    .toList(),
                                onChanged: (val) => setState(() =>
                                    _selectedAllocStatusFilter = val ?? 'All'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Allocation Cards
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(
                            icon: Icons.calendar_today_rounded,
                            title: 'No Shifts Scheduled',
                            message:
                                'No allocations match this date and filter. Tap below to allocate staff.',
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                            itemCount: filtered.length,
                            itemBuilder: (context, idx) {
                              final alloc = filtered[idx];
                              return _buildAllocationCard(
                                  alloc, allStaff, allocations);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllocationCard(
    StaffAllocation alloc,
    List<StaffMember> allStaff,
    List<StaffAllocation> existingAllocations,
  ) {
    Color shiftTypeColor = AppTheme.primary;
    if (alloc.shiftType == 'Peak') shiftTypeColor = AppTheme.warning;
    if (alloc.shiftType == 'Low Demand') shiftTypeColor = AppTheme.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: shiftTypeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.access_time_filled_rounded,
                        color: shiftTypeColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatTimeDisplay(alloc.startTime)} – ${_formatTimeDisplay(alloc.endTime)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${alloc.staffName} (${alloc.staffRole})',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: alloc.status == 'Active'
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : (alloc.status == 'Scheduled'
                          ? AppTheme.info.withValues(alpha: 0.12)
                          : AppTheme.textMuted.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alloc.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: alloc.status == 'Active'
                        ? AppTheme.success
                        : (alloc.status == 'Scheduled'
                            ? AppTheme.info
                            : AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Text(
                'Area: ${alloc.assignedArea}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: shiftTypeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${alloc.shiftType} Shift',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: shiftTypeColor),
                ),
              ),
            ],
          ),
          if (alloc.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${alloc.notes}',
              style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                onPressed: () => _showAllocationDialog(
                  allocation: alloc,
                  allStaff: allStaff,
                  existingAllocations: existingAllocations,
                ),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppTheme.error),
                label: const Text('Delete',
                    style: TextStyle(fontSize: 12, color: AppTheme.error)),
                onPressed: () => _confirmDeleteAllocation(alloc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAllocationDialog({
    StaffAllocation? allocation,
    required List<StaffMember> allStaff,
    required List<StaffAllocation> existingAllocations,
  }) async {
    String date = allocation?.date ??
        (_selectedAllocDateFilter.isEmpty
            ? _formatDate(DateTime.now())
            : _selectedAllocDateFilter);
    TimeOfDay startTime = allocation != null
        ? TimeOfDay(
            hour: int.tryParse(allocation.startTime.split(':')[0]) ?? 10,
            minute: int.tryParse(allocation.startTime.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 10, minute: 0);

    TimeOfDay endTime = allocation != null
        ? TimeOfDay(
            hour: int.tryParse(allocation.endTime.split(':')[0]) ?? 22,
            minute: int.tryParse(allocation.endTime.split(':')[1]) ?? 0,
          )
        : const TimeOfDay(hour: 14, minute: 0);

    String? selectedStaffId = allocation?.staffId;
    String assignedArea = allocation?.assignedArea ?? 'Dining Area';
    String shiftType = allocation?.shiftType ?? 'Normal';
    String status = allocation?.status ?? 'Scheduled';
    final notesCtrl = TextEditingController(text: allocation?.notes ?? '');
    String? validationError;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final sTimeStr = _formatTime(startTime);
          final eTimeStr = _formatTime(endTime);

          // Find available staff for this slot
          final availableStaff =
              StaffAllocationService.getAvailableStaffForSlot(
            date: date,
            startTime: sTimeStr,
            endTime: eTimeStr,
            allStaff: allStaff,
            allocationsOnDate: existingAllocations,
            currentStaffId: allocation?.staffId,
          );

          // If current selection is no longer available and we are adding new
          if (selectedStaffId != null &&
              !availableStaff.any((s) => s.id == selectedStaffId)) {
            if (allocation == null) {
              selectedStaffId =
                  availableStaff.isNotEmpty ? availableStaff.first.id : null;
            }
          } else if (selectedStaffId == null && availableStaff.isNotEmpty) {
            selectedStaffId = availableStaff.first.id;
          }

          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                    allocation == null
                        ? Icons.add_task_rounded
                        : Icons.edit_calendar_rounded,
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(allocation == null ? 'Schedule Shift' : 'Edit Shift',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (validationError != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cancelledBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppTheme.error, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Date selector
                    const Text('Shift Date *',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(date) ?? DateTime.now(),
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 30)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            date = _formatDate(picked);
                            validationError = null;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.cardBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(date,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            const Icon(Icons.calendar_today,
                                size: 16, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Shift Time Range
                    const Text('Shift Duration *',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: startTime);
                              if (picked != null) {
                                setDialogState(() {
                                  startTime = picked;
                                  validationError = null;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.cardBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Start: ${startTime.format(context)}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: endTime);
                              if (picked != null) {
                                setDialogState(() {
                                  endTime = picked;
                                  validationError = null;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.cardBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('End: ${endTime.format(context)}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Staff Selection Dropdown (Only Available Staff)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Staff Member *',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600)),
                        Text('${availableStaff.length} available',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    availableStaff.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.cancelledBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color:
                                      AppTheme.error.withValues(alpha: 0.45)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allStaff.isEmpty
                                      ? 'No staff records found. Add a staff member in Staff Management first.'
                                      : 'No active staff available for this time window. Check availability or overlapping shifts.',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppTheme.error),
                                ),
                                if (allStaff.isEmpty)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  StaffManagementScreen(
                                                      restaurantId: widget
                                                          .restaurantId)));
                                    },
                                    child: const Text('Open Staff Management'),
                                  ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: selectedStaffId,
                            decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8)),
                            items: availableStaff.map((s) {
                              return DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.name} (${s.role})',
                                    style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                selectedStaffId = val;
                                validationError = null;
                              });
                            },
                            validator: (val) => val == null
                                ? 'Please select a staff member'
                                : null,
                          ),
                    const SizedBox(height: 12),

                    // Area & Shift Type
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: assignedArea,
                            decoration: const InputDecoration(
                                labelText: 'Assigned Area *'),
                            onChanged: (val) => assignedArea = val,
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Enter area'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: shiftType,
                            decoration:
                                const InputDecoration(labelText: 'Shift Type'),
                            items: _shiftTypes
                                .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => shiftType = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: _allocationStatuses
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: notesCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: availableStaff.isEmpty && selectedStaffId == null
                    ? null
                    : () async {
                        // Validate end time > start time
                        final sMins =
                            StaffAllocationService.timeToMinutes(sTimeStr);
                        final eMins =
                            StaffAllocationService.timeToMinutes(eTimeStr);
                        if (eMins <= sMins) {
                          setDialogState(() {
                            validationError =
                                'Shift end time must be after start time';
                          });
                          return;
                        }

                        // Check max daily hours of selected staff
                        final staffObj =
                            allStaff.firstWhere((s) => s.id == selectedStaffId);
                        final durationHours = (eMins - sMins) / 60.0;
                        if (durationHours > staffObj.maxDailyHours) {
                          setDialogState(() {
                            validationError =
                                '${staffObj.name} exceeds max daily hours limit of ${staffObj.maxDailyHours}h (this shift is ${durationHours.toStringAsFixed(1)}h).';
                          });
                          return;
                        }

                        if (formKey.currentState!.validate()) {
                          try {
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            if (allocation == null) {
                              final newAlloc = StaffAllocation(
                                id: '',
                                restaurantId: widget.restaurantId,
                                date: date,
                                startTime: sTimeStr,
                                endTime: eTimeStr,
                                staffId: staffObj.id,
                                staffName: staffObj.name,
                                staffRole: staffObj.role,
                                assignedArea: assignedArea,
                                shiftType: shiftType,
                                status: status,
                                notes: notesCtrl.text.trim(),
                              );
                              await _service.addAllocation(newAlloc);
                            } else {
                              final updated = allocation.copyWith(
                                date: date,
                                startTime: sTimeStr,
                                endTime: eTimeStr,
                                staffId: staffObj.id,
                                staffName: staffObj.name,
                                staffRole: staffObj.role,
                                assignedArea: assignedArea,
                                shiftType: shiftType,
                                status: status,
                                notes: notesCtrl.text.trim(),
                              );
                              await _service.updateAllocation(updated);
                            }

                            nav.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                  content: Text(allocation == null
                                      ? 'Shift scheduled successfully'
                                      : 'Shift updated')),
                            );
                          } catch (e) {
                            setDialogState(() {
                              validationError =
                                  e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        }
                      },
                child: Text(allocation == null ? 'Schedule' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAllocation(StaffAllocation alloc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel / Delete Shift',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Remove shift for ${alloc.staffName} (${alloc.startTime} - ${alloc.endTime}) on ${alloc.date}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteAllocation(alloc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift allocation removed')),
        );
      }
    }
  }

  void _showQuickAllocateModal(
    RecommendationResult rec,
    List<StaffMember> allStaff,
    List<StaffAllocation> allocations,
  ) {
    final dateStr = _formatDate(_selectedDate);
    final startTimeStr = _formatTime(_selectedTime);
    // Default end time +3 hours
    final endHour = (_selectedTime.hour + 3).clamp(0, 23);
    final endTimeStr = '${endHour.toString().padLeft(2, '0')}:00';

    final availableStaff = StaffAllocationService.getAvailableStaffForSlot(
      date: dateStr,
      startTime: startTimeStr,
      endTime: endTimeStr,
      allStaff: allStaff,
      allocationsOnDate: allocations,
    );

    final selectedStaffIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final shortageNeeded = rec.shortage > 0 ? rec.shortage : 1;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Staff Allocation',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  Text(
                    'Time: $startTimeStr – $endTimeStr • Recommended Staff: ${rec.recommendedStaff} • Needed: $shortageNeeded',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  if (availableStaff.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.cancelledBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.45)),
                      ),
                      child: const Text(
                        'No additional staff members are available for this period. All active staff are currently scheduled or unavailable.',
                        style: TextStyle(fontSize: 12, color: AppTheme.error),
                      ),
                    )
                  else ...[
                    const Text(
                      'Select available staff members to allocate:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableStaff.length,
                        itemBuilder: (context, i) {
                          final s = availableStaff[i];
                          final isChecked = selectedStaffIds.contains(s.id);

                          return CheckboxListTile(
                            value: isChecked,
                            activeColor: AppTheme.primary,
                            title: Text(s.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: Text('${s.role} • ${s.department}',
                                style: const TextStyle(fontSize: 11)),
                            secondary: CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.primary.withValues(alpha: 0.1),
                              child: Text(s.name[0],
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700)),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  selectedStaffIds.add(s.id);
                                } else {
                                  selectedStaffIds.remove(s.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedStaffIds.isEmpty
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(ctx);
                                for (final staffId in selectedStaffIds) {
                                  final staffObj = availableStaff
                                      .firstWhere((s) => s.id == staffId);
                                  final newAlloc = StaffAllocation(
                                    id: '',
                                    restaurantId: widget.restaurantId,
                                    date: dateStr,
                                    startTime: startTimeStr,
                                    endTime: endTimeStr,
                                    staffId: staffObj.id,
                                    staffName: staffObj.name,
                                    staffRole: staffObj.role,
                                    assignedArea: staffObj.department,
                                    shiftType:
                                        rec.isPeakHour ? 'Peak' : 'Normal',
                                    status: 'Scheduled',
                                    notes:
                                        'Auto-allocated to fulfill ${rec.demandLevel} demand shortage',
                                  );
                                  await _service.addAllocation(newAlloc);
                                }
                                nav.pop();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Allocated ${selectedStaffIds.length} staff member${selectedStaffIds.length > 1 ? 's' : ''}. Staffing requirement updated!',
                                    ),
                                  ),
                                );
                                if (mounted) {
                                  setState(() {});
                                }
                              },
                        child: Text(
                            'Confirm Allocation (${selectedStaffIds.length} Selected)'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // TAB 4: PEAK HOURS CONFIGURATION CRUD
  // ===========================================================================

  // ignore: unused_element
  Widget _buildPeakHoursTab() {
    return StreamBuilder<List<PeakHourConfig>>(
      stream: _service.streamPeakHours(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final configs = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add_alarm_rounded,
                color: AppTheme.textPrimary),
            label: const Text('Add Peak Window',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
            onPressed: () => _showPeakHourDialog(),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Configure scheduled peak periods by day of week. The recommendation engine applies these minimums when scheduling shifts.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (configs.isEmpty)
                _buildEmptyState(
                  icon: Icons.alarm_off_rounded,
                  title: 'No Peak Hours Configured',
                  message:
                      'Tap below to define peak hours for your restaurant.',
                )
              else
                ...configs.map((c) => _buildPeakHourCard(c)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeakHourCard(PeakHourConfig config) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.waitingBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: AppTheme.warning, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config.dayOfWeek,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatTimeDisplay(config.startTime)} – ${_formatTimeDisplay(config.endTime)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDemandColor(config.demandLevel)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  config.demandLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getDemandColor(config.demandLevel),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Min Staff: ${config.minStaff}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Recommended: ${config.recommendedStaff}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.cardBorder),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.textSecondary),
                onPressed: () => _showPeakHourDialog(config: config),
                tooltip: 'Edit Peak Hour',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppTheme.error),
                onPressed: () => _confirmDeletePeakHour(config),
                tooltip: 'Delete Peak Hour',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPeakHourDialog({PeakHourConfig? config}) async {
    String day = config?.dayOfWeek ?? 'Monday';
    TimeOfDay startTime = config != null
        ? TimeOfDay(
            hour: int.tryParse(config.startTime.split(':')[0]) ?? 18,
            minute: int.tryParse(config.startTime.split(':')[1]) ?? 0)
        : const TimeOfDay(hour: 18, minute: 0);

    TimeOfDay endTime = config != null
        ? TimeOfDay(
            hour: int.tryParse(config.endTime.split(':')[0]) ?? 21,
            minute: int.tryParse(config.endTime.split(':')[1]) ?? 0)
        : const TimeOfDay(hour: 21, minute: 0);

    String demandLevel = config?.demandLevel ?? 'High';
    String status = config?.status ?? 'Enabled';
    final minStaffCtrl =
        TextEditingController(text: '${config?.minStaff ?? 6}');
    final recStaffCtrl =
        TextEditingController(text: '${config?.recommendedStaff ?? 8}');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                    config == null
                        ? Icons.add_alarm_rounded
                        : Icons.edit_note_rounded,
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(config == null ? 'Add Peak Period' : 'Edit Peak Period',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: day,
                      decoration:
                          const InputDecoration(labelText: 'Day of the Week *'),
                      items: _daysOfWeek
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => day = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: startTime);
                              if (picked != null) {
                                setDialogState(() => startTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.cardBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('Start: ${startTime.format(context)}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                  context: context, initialTime: endTime);
                              if (picked != null) {
                                setDialogState(() => endTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.cardBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('End: ${endTime.format(context)}',
                                  style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: demandLevel,
                      decoration: const InputDecoration(
                          labelText: 'Expected Demand Level *'),
                      items: _demandLevels
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => demandLevel = val);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Enabled', child: Text('Enabled')),
                        DropdownMenuItem(
                            value: 'Disabled', child: Text('Disabled')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: minStaffCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Min Staff *'),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              final n = int.tryParse(val ?? '');
                              if (n == null || n < 1) return 'Must be >= 1';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: recStaffCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Rec. Staff *'),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              final n = int.tryParse(val ?? '');
                              if (n == null || n < 1) return 'Must be >= 1';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final sTimeStr = _formatTime(startTime);
                  final eTimeStr = _formatTime(endTime);
                  if (StaffAllocationService.timeToMinutes(eTimeStr) <=
                      StaffAllocationService.timeToMinutes(sTimeStr)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('End time must be after start time')),
                    );
                    return;
                  }

                  if (formKey.currentState!.validate()) {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    final minStaff =
                        int.tryParse(minStaffCtrl.text.trim()) ?? 5;
                    final recStaff =
                        int.tryParse(recStaffCtrl.text.trim()) ?? 7;

                    if (config == null) {
                      final newConfig = PeakHourConfig(
                        id: '',
                        restaurantId: widget.restaurantId,
                        dayOfWeek: day,
                        startTime: sTimeStr,
                        endTime: eTimeStr,
                        demandLevel: demandLevel,
                        minStaff: minStaff,
                        recommendedStaff: recStaff,
                        status: status,
                      );
                      await _service.addPeakHourConfig(newConfig);
                    } else {
                      final updated = config.copyWith(
                        dayOfWeek: day,
                        startTime: sTimeStr,
                        endTime: eTimeStr,
                        demandLevel: demandLevel,
                        minStaff: minStaff,
                        recommendedStaff: recStaff,
                        status: status,
                      );
                      await _service.updatePeakHourConfig(updated);
                    }

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(config == null
                              ? 'Peak hour config saved'
                              : 'Peak hour config updated')),
                    );
                  }
                },
                child:
                    Text(config == null ? 'Add Peak Period' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeletePeakHour(PeakHourConfig config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Peak Hour',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Delete peak hour configuration for ${config.dayOfWeek} (${config.startTime} - ${config.endTime})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deletePeakHourConfig(config.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Peak hour configuration deleted')));
      }
    }
  }

  // ===========================================================================
  // TAB 5: ALLOCATION RULES CRUD
  // ===========================================================================

  // ignore: unused_element
  Widget _buildRulesTab() {
    return StreamBuilder<List<StaffAllocationRule>>(
      stream: _service.streamRules(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary));
        }

        final rules = snapshot.data ?? [];
        rules.sort((a, b) => a.minCustomers.compareTo(b.minCustomers));

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add_rounded, color: AppTheme.textPrimary),
            label: const Text('Add Rule Tier',
                style: TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
            onPressed: () => _showRuleDialog(existingRules: rules),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Define demand-to-staff tiers. The recommendation system maps expected guests to these rules to calculate required staff counts.',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (rules.isEmpty)
                _buildEmptyState(
                  icon: Icons.rule_folder_rounded,
                  title: 'No Rules Defined',
                  message: 'Tap below to add staff allocation rules.',
                )
              else
                ...rules.map((r) => _buildRuleCard(r, rules)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleCard(
      StaffAllocationRule rule, List<StaffAllocationRule> allRules) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getDemandColor(rule.demandLevel).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.group_work_rounded,
                color: _getDemandColor(rule.demandLevel), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${rule.minCustomers} – ${rule.maxCustomers >= 900 ? '31+' : rule.maxCustomers} Guests',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDemandColor(rule.demandLevel)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rule.demandLevel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _getDemandColor(rule.demandLevel),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Recommend: ${rule.recommendedStaff} Staff Members',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 18, color: AppTheme.textSecondary),
            onPressed: () =>
                _showRuleDialog(rule: rule, existingRules: allRules),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppTheme.error),
            onPressed: () => _confirmDeleteRule(rule),
          ),
        ],
      ),
    );
  }

  Future<void> _showRuleDialog({
    StaffAllocationRule? rule,
    required List<StaffAllocationRule> existingRules,
  }) async {
    final minCtrl = TextEditingController(text: '${rule?.minCustomers ?? 0}');
    final maxCtrl = TextEditingController(text: '${rule?.maxCustomers ?? 10}');
    final staffCtrl =
        TextEditingController(text: '${rule?.recommendedStaff ?? 4}');
    final minimumStaffCtrl =
        TextEditingController(text: '${rule?.minimumStaff ?? 1}');
    String demand = rule?.demandLevel ?? 'Normal';
    String status = rule?.status ?? 'Active';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                    rule == null
                        ? Icons.add_circle_outline_rounded
                        : Icons.edit_note_rounded,
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                    rule == null
                        ? 'Add Allocation Rule'
                        : 'Edit Allocation Rule',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: minCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Min Guests *'),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              final n = int.tryParse(val ?? '');
                              if (n == null || n < 0) return 'Must be >= 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: maxCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Max Guests *'),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              final n = int.tryParse(val ?? '');
                              if (n == null || n < 1) return 'Must be >= 1';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: demand,
                      decoration:
                          const InputDecoration(labelText: 'Demand Level *'),
                      items: _demandLevels
                          .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => demand = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: staffCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Recommended Staff *'),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              final n = int.tryParse(val ?? '');
                              if (n == null || n < 1) return 'Must be >= 1';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: minimumStaffCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Minimum Staff *'),
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              final n = int.tryParse(val ?? '');
                              if (n == null || n < 0) return 'Must be >= 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: 'Status *'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => status = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final minG = int.tryParse(minCtrl.text.trim()) ?? 0;
                  final maxG = int.tryParse(maxCtrl.text.trim()) ?? 10;
                  final recStaff = int.tryParse(staffCtrl.text.trim()) ?? 4;
                  final minStaff =
                      int.tryParse(minimumStaffCtrl.text.trim()) ?? 1;
                  if (maxG <= minG) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Max customers must be strictly greater than min customers')),
                    );
                    return;
                  }
                  if (minStaff > recStaff) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Recommended staff cannot be lower than minimum staff')),
                    );
                    return;
                  }

                  if (formKey.currentState!.validate()) {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(ctx);
                    final existingWithoutSelf = [
                      ...existingRules.where((r) => r.id != rule?.id),
                      StaffAllocationRule(
                        id: 'pending',
                        restaurantId: widget.restaurantId,
                        minCustomers: minG,
                        maxCustomers: maxG,
                        demandLevel: demand,
                        recommendedStaff: recStaff,
                        minimumStaff: minStaff,
                        status: status,
                      ),
                    ];
                    try {
                      StaffAllocationService.validateRulesDoNotOverlap(
                          existingWithoutSelf);
                    } on ArgumentError catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                      return;
                    }

                    if (rule == null) {
                      final newRule = StaffAllocationRule(
                        id: '',
                        restaurantId: widget.restaurantId,
                        minCustomers: minG,
                        maxCustomers: maxG,
                        demandLevel: demand,
                        recommendedStaff: recStaff,
                        minimumStaff: minStaff,
                        status: status,
                      );
                      await _service.addRule(newRule);
                    } else {
                      final updated = rule.copyWith(
                        minCustomers: minG,
                        maxCustomers: maxG,
                        demandLevel: demand,
                        recommendedStaff: recStaff,
                        minimumStaff: minStaff,
                        status: status,
                      );
                      await _service.updateRule(updated);
                    }

                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              rule == null ? 'Rule added' : 'Rule updated')),
                    );
                  }
                },
                child: Text(rule == null ? 'Add Rule' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteRule(StaffAllocationRule rule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rule',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Delete allocation rule for ${rule.minCustomers}-${rule.maxCustomers} guests (${rule.demandLevel})?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteRule(rule.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rule deleted')));
      }
    }
  }

  // Common Empty State Widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
