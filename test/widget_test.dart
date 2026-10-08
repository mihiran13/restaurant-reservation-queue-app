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
import 'package:restaurant_app/data/firebase_data.dart';

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
}
