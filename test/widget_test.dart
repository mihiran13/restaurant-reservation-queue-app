import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:restaurant_app/widgets/app_header.dart';
import 'package:restaurant_app/widgets/kpi_card.dart';
import 'package:restaurant_app/widgets/chart_card.dart';
import 'package:restaurant_app/widgets/analytics_filter.dart';
import 'package:restaurant_app/screens/owner/owner_login.dart';
import 'package:restaurant_app/screens/owner/owner_dashboard.dart';
import 'package:restaurant_app/screens/owner/peak_hours.dart';
import 'package:restaurant_app/screens/owner/customer_turnover.dart';
import 'package:restaurant_app/screens/owner/walk_away.dart';
import 'package:restaurant_app/screens/owner/waiting_time.dart';
import 'package:restaurant_app/screens/owner/no_show.dart';
import 'package:restaurant_app/screens/owner/operational_reports.dart';
import 'package:restaurant_app/screens/owner/settings_screen.dart';
import 'package:restaurant_app/screens/owner/staff_allocation_screen.dart';
import 'package:restaurant_app/data/firebase_data.dart';
import 'package:restaurant_app/data/staff_data.dart';
import 'package:restaurant_app/services/staff_allocation_service.dart';

void main() {
  testWidgets('AppHeader renders title and subtitle properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppHeader(
            title: 'Owner Dashboard',
            subtitle: 'Overview & Service Status',
          ),
        ),
      ),
    );

    expect(find.text('Owner Dashboard'), findsOneWidget);
    expect(find.text('Overview & Service Status'), findsOneWidget);
  });

  testWidgets('KpiCard renders metric values and icons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KpiCard(
            title: 'Total Guests',
            value: '142',
            icon: Icons.people_outline_rounded,
            trendText: '+12%',
          ),
        ),
      ),
    );

    expect(find.text('Total Guests'), findsOneWidget);
    expect(find.text('142'), findsOneWidget);
    expect(find.text('+12%'), findsOneWidget);
  });

  testWidgets('ChartCard and AnalyticsFilter render properly', (WidgetTester tester) async {
    String selected = 'Today';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AnalyticsFilter(
                selectedOption: selected,
                onSelected: (val) => selected = val,
              ),
              const ChartCard(
                title: 'Test Bar Chart',
                data: [
                  ChartDataPoint(label: '1 PM', value: 20, displayValue: '20'),
                  ChartDataPoint(label: '2 PM', value: 40, displayValue: '40'),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Test Bar Chart'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('OwnerLoginScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OwnerLoginScreen()));
    expect(find.text('Restaurant Portal'), findsOneWidget);
    expect(find.text('Sign In as Owner'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });

  testWidgets('OwnerDashboardScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OwnerDashboardScreen()));
    expect(find.text('Owner Dashboard'), findsOneWidget);
    expect(find.text('Key Performance Indicators'), findsOneWidget);
    expect(find.text('Total Guests'), findsOneWidget);
  });

  testWidgets('PeakHoursScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PeakHoursScreen()));
    expect(find.text('Peak Hours'), findsOneWidget);
    expect(find.text('Peak Time Window'), findsOneWidget);
  });

  testWidgets('CustomerTurnoverScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerTurnoverScreen()));
    expect(find.text('Customer Turnover'), findsOneWidget);
    expect(find.text('Avg Daily Turnover'), findsOneWidget);
  });

  testWidgets('WalkAwayScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WalkAwayScreen()));
    expect(find.text('Walk-Away Metrics'), findsOneWidget);
    expect(find.text('Walk-Away Rate'), findsOneWidget);
  });

  testWidgets('WaitingTimeScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WaitingTimeScreen()));
    expect(find.text('Average Waiting Time'), findsOneWidget);
    expect(find.text('Current Avg Wait'), findsOneWidget);
  });

  testWidgets('NoShowScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: NoShowScreen()));
    expect(find.text('No-Show Rate'), findsNWidgets(2));
    expect(find.text('Unfulfilled Bookings'), findsOneWidget);
  });

  testWidgets('OperationalReportsScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OperationalReportsScreen()));
    expect(find.text('Operational Reports'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });

  testWidgets('SettingsScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    expect(find.text('Control Center'), findsOneWidget);
    expect(find.text('Restaurant Information'), findsOneWidget);
  });

  testWidgets('OperationalReport and Settings data structures serialize properly', (WidgetTester tester) async {
    final report = OperationalReport(
      id: 'rep_1',
      restaurantId: 'rest_1',
      title: 'Shift Audit',
      type: 'Daily Shift',
      date: '2026-10-07',
      summary: 'Smooth service with 3.8 turns',
      createdAt: '2026-10-07T12:00:00Z',
    );
    final map = report.toMap();
    expect(map['title'], 'Shift Audit');
    expect(map['type'], 'Daily Shift');

    final settings = RestaurantSettings.initial;
    final settingsMap = settings.toMap();
    expect(settingsMap['restaurantName'], 'The Grand Bistro');
    expect(settingsMap['openingTime'], '11:00 AM');
  });

  testWidgets('StaffAllocationScreen renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: StaffAllocationScreen()));
    expect(find.text('Staff Allocation'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Allocations'), findsOneWidget);
    expect(find.text('Peak Hours'), findsOneWidget);
    expect(find.text('Rules'), findsOneWidget);
  });

  // =========================================================================
  // STAFF ALLOCATION & SCHEDULING TESTS
  // =========================================================================

  test('StaffMember and StaffAllocation data models serialize and deserialize properly', () {
    final staff = StaffMember(
      id: 'staff_test_01',
      restaurantId: 'bistro_01',
      name: 'Elena Rostova',
      phone: '+1 555-1234',
      email: 'elena@test.com',
      role: 'Manager',
      department: 'Front Desk',
      status: 'Active',
      availableHours: '08:00 - 18:00',
      maxDailyHours: 9,
    );

    final staffMap = staff.toMap();
    expect(staffMap['name'], 'Elena Rostova');
    expect(staffMap['role'], 'Manager');
    expect(staff.isActive, isTrue);

    final staffRecreated = StaffMember.fromMap(staffMap, 'staff_test_01');
    expect(staffRecreated.name, 'Elena Rostova');
    expect(staffRecreated.maxDailyHours, 9);

    final alloc = StaffAllocation(
      id: 'alloc_01',
      restaurantId: 'bistro_01',
      date: '2026-10-10',
      startTime: '18:00',
      endTime: '22:00',
      staffId: 'staff_test_01',
      staffName: 'Elena Rostova',
      staffRole: 'Manager',
      assignedArea: 'Floor',
      shiftType: 'Peak',
      status: 'Scheduled',
    );

    final allocMap = alloc.toMap();
    expect(allocMap['date'], '2026-10-10');
    expect(allocMap['shiftType'], 'Peak');
    final allocRecreated = StaffAllocation.fromMap(allocMap, 'alloc_01');
    expect(allocRecreated.staffName, 'Elena Rostova');
  });

  test('PeakHourConfig and StaffAllocationRule data models serialize properly', () {
    final peak = PeakHourConfig(
      id: 'peak_01',
      restaurantId: 'bistro_01',
      dayOfWeek: 'Saturday',
      startTime: '18:00',
      endTime: '22:00',
      demandLevel: 'Very High',
      minStaff: 8,
      recommendedStaff: 10,
    );
    final peakMap = peak.toMap();
    expect(peakMap['dayOfWeek'], 'Saturday');
    expect(peakMap['recommendedStaff'], 10);

    final rule = StaffAllocationRule(
      id: 'rule_01',
      restaurantId: 'bistro_01',
      minCustomers: 16,
      maxCustomers: 30,
      demandLevel: 'High',
      recommendedStaff: 6,
    );
    final ruleMap = rule.toMap();
    expect(ruleMap['demandLevel'], 'High');
    expect(ruleMap['recommendedStaff'], 6);
  });

  test('StaffAllocationService.isTimeOverlapping accurately detects shift overlaps', () {
    // Overlapping intervals
    expect(StaffAllocationService.isTimeOverlapping('18:00', '22:00', '19:00', '23:00'), isTrue);
    expect(StaffAllocationService.isTimeOverlapping('10:00', '16:00', '11:00', '13:00'), isTrue);
    expect(StaffAllocationService.isTimeOverlapping('14:00', '20:00', '12:00', '16:00'), isTrue);

    // Non-overlapping intervals
    expect(StaffAllocationService.isTimeOverlapping('10:00', '14:00', '15:00', '18:00'), isFalse);
    expect(StaffAllocationService.isTimeOverlapping('18:00', '22:00', '08:00', '12:00'), isFalse);

    // Contiguous (touching boundaries without overlap)
    expect(StaffAllocationService.isTimeOverlapping('10:00', '14:00', '14:00', '18:00'), isFalse);
  });

  test('StaffAllocationService.checkStaffOverlap detects conflicting shift for same staff', () {
    final allocations = [
      const StaffAllocation(
        id: 'alloc_01',
        restaurantId: 'bistro_01',
        date: '2026-10-10',
        startTime: '10:00',
        endTime: '16:00',
        staffId: 'staff_01',
        staffName: 'Elena Rostova',
        staffRole: 'Manager',
        assignedArea: 'Floor',
        status: 'Scheduled',
      ),
      const StaffAllocation(
        id: 'alloc_02',
        restaurantId: 'bistro_01',
        date: '2026-10-10',
        startTime: '18:00',
        endTime: '22:00',
        staffId: 'staff_01',
        staffName: 'Elena Rostova',
        staffRole: 'Manager',
        assignedArea: 'Floor',
        status: 'Cancelled', // Cancelled shifts do NOT conflict
      ),
    ];

    // Conflict: 12:00 - 18:00 overlaps with 10:00 - 16:00
    final conflict = StaffAllocationService.checkStaffOverlap(
      staffId: 'staff_01',
      date: '2026-10-10',
      startTime: '12:00',
      endTime: '18:00',
      existingAllocations: allocations,
    );
    expect(conflict, isNotNull);
    expect(conflict!.id, 'alloc_01');

    // No conflict: Evening shift 18:00 - 22:00 because alloc_02 is Cancelled
    final noConflict = StaffAllocationService.checkStaffOverlap(
      staffId: 'staff_01',
      date: '2026-10-10',
      startTime: '18:00',
      endTime: '22:00',
      existingAllocations: allocations,
    );
    expect(noConflict, isNull);

    // Different staff ID has no conflict
    final diffStaff = StaffAllocationService.checkStaffOverlap(
      staffId: 'staff_99',
      date: '2026-10-10',
      startTime: '10:00',
      endTime: '16:00',
      existingAllocations: allocations,
    );
    expect(diffStaff, isNull);
  });

  test('StaffAllocationService filters available vs inactive, booked, and unavailable staff', () {
    final staffList = [
      const StaffMember(
        id: 'staff_01',
        restaurantId: 'bistro_01',
        name: 'Elena',
        phone: '123',
        email: 'e@t.com',
        role: 'Manager',
        department: 'Floor',
        status: 'Active',
        availableFrom: '08:00',
        availableTo: '18:00',
      ),
      const StaffMember(
        id: 'staff_02',
        restaurantId: 'bistro_01',
        name: 'Noah',
        phone: '456',
        email: 'n@t.com',
        role: 'Waiter',
        department: 'Dining',
        status: 'Inactive',
        availableFrom: '10:00',
        availableTo: '22:00',
      ),
      const StaffMember(
        id: 'staff_03',
        restaurantId: 'bistro_01',
        name: 'Pia',
        phone: '789',
        email: 'p@t.com',
        role: 'Host',
        department: 'Front Desk',
        status: 'Active',
        availableFrom: '12:00',
        availableTo: '16:00',
      ),
    ];

    final allocations = [
      const StaffAllocation(
        id: 'alloc_01',
        restaurantId: 'bistro_01',
        date: '2026-10-10',
        startTime: '10:00',
        endTime: '16:00',
        staffId: 'staff_01',
        staffName: 'Elena',
        staffRole: 'Manager',
        assignedArea: 'Floor',
      ),
    ];

    final available = StaffAllocationService.getAvailableStaffForSlot(
      date: '2026-10-10',
      startTime: '12:00',
      endTime: '15:00',
      allStaff: staffList,
      allocationsOnDate: allocations,
    );
    expect(available.map((s) => s.id), ['staff_03']);

    final availableEvening = StaffAllocationService.getAvailableStaffForSlot(
      date: '2026-10-10',
      startTime: '18:00',
      endTime: '22:00',
      allStaff: staffList,
      allocationsOnDate: allocations,
    );
    expect(availableEvening, isEmpty);
  });

  test('StaffAllocationService validates overlapping rule ranges and peak adjustment', () {
    const rules = [
      StaffAllocationRule(
        id: 'rule_1',
        restaurantId: 'bistro_01',
        minCustomers: 0,
        maxCustomers: 5,
        demandLevel: 'Low',
        recommendedStaff: 2,
      ),
      StaffAllocationRule(
        id: 'rule_2',
        restaurantId: 'bistro_01',
        minCustomers: 5,
        maxCustomers: 15,
        demandLevel: 'Normal',
        recommendedStaff: 4,
      ),
    ];

    expect(
      () => StaffAllocationService.validateRulesDoNotOverlap(rules),
      throwsA(isA<ArgumentError>()),
    );

    final peak = PeakHourConfig(
      id: 'peak_01',
      restaurantId: 'bistro_01',
      dayOfWeek: 'Saturday',
      startTime: '18:00',
      endTime: '22:00',
      demandLevel: 'High',
      minStaff: 6,
      recommendedStaff: 8,
      status: 'Enabled',
    );
    final recommendation = StaffAllocationService.calculateRecommendation(
      date: DateTime(2026, 10, 10),
      time: '19:00',
      reservations: 22,
      queue: 5,
      peakConfigs: [peak],
      rules: const [
        StaffAllocationRule(
          id: 'rule_3',
          restaurantId: 'bistro_01',
          minCustomers: 16,
          maxCustomers: 30,
          demandLevel: 'High',
          recommendedStaff: 6,
        ),
      ],
      allocationsOnDate: const [],
    );

    expect(recommendation.demandLevel, 'High');
    expect(recommendation.recommendedStaff, 8);
    expect(recommendation.shortage, 8);
  });

  test('StaffAllocationService demand rule matching and recommendation calculation', () {
    final rules = StaffAllocationService.defaultRules('bistro_01');
    final peaks = StaffAllocationService.defaultPeakHours('bistro_01');

    // Rule match verification
    expect(StaffAllocationService.findMatchingRule(customerCount: 3, rules: rules).recommendedStaff, 2);
    expect(StaffAllocationService.findMatchingRule(customerCount: 12, rules: rules).recommendedStaff, 4);
    expect(StaffAllocationService.findMatchingRule(customerCount: 25, rules: rules).recommendedStaff, 6);
    expect(StaffAllocationService.findMatchingRule(customerCount: 45, rules: rules).recommendedStaff, 8);

    // Scenario: Saturday 7:00 PM (19:00), 22 reservations + 5 queue = 27 customers
    // Saturday peak config has recommended 10 staff
    // Currently allocated: 4 staff -> shortage should be 6
    final allocations = [
      const StaffAllocation(
        id: 'a1',
        restaurantId: 'b1',
        date: '2026-10-10',
        startTime: '17:00',
        endTime: '22:00',
        staffId: 's1',
        staffName: 'A',
        staffRole: 'Waiter',
        assignedArea: 'Dining',
      ),
      const StaffAllocation(
        id: 'a2',
        restaurantId: 'b1',
        date: '2026-10-10',
        startTime: '17:00',
        endTime: '22:00',
        staffId: 's2',
        staffName: 'B',
        staffRole: 'Waiter',
        assignedArea: 'Dining',
      ),
      const StaffAllocation(
        id: 'a3',
        restaurantId: 'b1',
        date: '2026-10-10',
        startTime: '17:00',
        endTime: '22:00',
        staffId: 's3',
        staffName: 'C',
        staffRole: 'Cook',
        assignedArea: 'Kitchen',
      ),
      const StaffAllocation(
        id: 'a4',
        restaurantId: 'b1',
        date: '2026-10-10',
        startTime: '17:00',
        endTime: '22:00',
        staffId: 's4',
        staffName: 'D',
        staffRole: 'Cashier',
        assignedArea: 'Counter',
      ),
    ];

    final saturdayDate = DateTime(2026, 10, 10); // 2026-10-10 is Saturday
    final rec = StaffAllocationService.calculateRecommendation(
      date: saturdayDate,
      time: '19:00',
      reservations: 22,
      queue: 5,
      peakConfigs: peaks,
      rules: rules,
      allocationsOnDate: allocations,
    );

    expect(rec.totalExpectedCustomers, 27);
    expect(rec.isPeakHour, isTrue);
    expect(rec.recommendedStaff, 10);
    expect(rec.allocatedStaff, 4);
    expect(rec.shortage, 6);
    expect(rec.hasShortage, isTrue);
    expect(rec.isSatisfied, isFalse);
  });
}
