// Lightweight data models, Firestore integration, and persistence helpers for Owner Module.
// Covers OwnerProfile, RestaurantSettings, OperationalReport, DashboardSummary, and AnalyticsRecord.
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerProfile {
  final String id;
  final String name;
  final String email;
  final String restaurantId;
  final String restaurantName;
  final String branch;

  const OwnerProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.restaurantId,
    required this.restaurantName,
    required this.branch,
  });

  factory OwnerProfile.fromMap(Map<String, dynamic> data, String id) {
    return OwnerProfile(
      id: id,
      name: data['name'] ?? 'Restaurant Owner',
      email: data['email'] ?? '',
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      restaurantName: data['restaurantName'] ?? 'The Grand Bistro',
      branch: data['branch'] ?? 'Main Branch',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'branch': branch,
    };
  }
}

class DashboardSummary {
  final int totalGuestsToday;
  final String avgWaitTime;
  final double turnoverRate;
  final int activeTables;
  final int totalTables;
  final String restaurantStatus;

  const DashboardSummary({
    required this.totalGuestsToday,
    required this.avgWaitTime,
    required this.turnoverRate,
    required this.activeTables,
    required this.totalTables,
    required this.restaurantStatus,
  });

  static const DashboardSummary initial = DashboardSummary(
    totalGuestsToday: 142,
    avgWaitTime: '18 min',
    turnoverRate: 3.4,
    activeTables: 18,
    totalTables: 24,
    restaurantStatus: 'Open • Peak Service',
  );

  factory DashboardSummary.fromMap(Map<String, dynamic> data) {
    return DashboardSummary(
      totalGuestsToday: data['totalGuestsToday'] ?? 142,
      avgWaitTime: data['avgWaitTime'] ?? '18 min',
      turnoverRate: (data['turnoverRate'] is num) ? (data['turnoverRate'] as num).toDouble() : 3.4,
      activeTables: data['activeTables'] ?? 18,
      totalTables: data['totalTables'] ?? 24,
      restaurantStatus: data['restaurantStatus'] ?? 'Open • Peak Service',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalGuestsToday': totalGuestsToday,
      'avgWaitTime': avgWaitTime,
      'turnoverRate': turnoverRate,
      'activeTables': activeTables,
      'totalTables': totalTables,
      'restaurantStatus': restaurantStatus,
    };
  }
}

/// Generic Analytics Record structure:
/// analytics/{recordId} -> { restaurantId, date, type, period, value, secondaryValue, label, displayValue }
class AnalyticsRecord {
  final String id;
  final String restaurantId;
  final String date;
  final String type; // 'peak_hours', 'turnover', 'walk_away', 'waiting_time', 'no_show'
  final String period; // 'Today', 'This Week', 'This Month'
  final String label;
  final double value;
  final String? displayValue;
  final double? secondaryValue;

  const AnalyticsRecord({
    required this.id,
    required this.restaurantId,
    required this.date,
    required this.type,
    this.period = 'Today',
    required this.label,
    required this.value,
    this.displayValue,
    this.secondaryValue,
  });

  factory AnalyticsRecord.fromMap(Map<String, dynamic> data, String id) {
    return AnalyticsRecord(
      id: id,
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      date: data['date'] ?? '',
      type: data['type'] ?? '',
      period: data['period'] ?? 'Today',
      label: data['label'] ?? '',
      value: (data['value'] is num) ? (data['value'] as num).toDouble() : 0.0,
      displayValue: data['displayValue'],
      secondaryValue: (data['secondaryValue'] is num) ? (data['secondaryValue'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'date': date,
      'type': type,
      'period': period,
      'label': label,
      'value': value,
      'displayValue': displayValue,
      'secondaryValue': secondaryValue,
    };
  }
}

/// Operational Report model with Firestore CRUD support.
/// Collection: reports/{reportId}
class OperationalReport {
  final String id;
  final String restaurantId;
  final String title;
  final String type; // e.g. 'Daily Shift', 'Weekly Summary', 'Turnover Audit', 'Waitlist Review'
  final String date;
  final String summary;
  final String createdAt;
  final String? updatedAt;

  const OperationalReport({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.type,
    required this.date,
    required this.summary,
    required this.createdAt,
    this.updatedAt,
  });

  factory OperationalReport.fromMap(Map<String, dynamic> data, String id) {
    return OperationalReport(
      id: id,
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      title: data['title'] ?? 'Untitled Report',
      type: data['type'] ?? 'Daily Shift',
      date: data['date'] ?? '',
      summary: data['summary'] ?? '',
      createdAt: data['createdAt'] ?? '',
      updatedAt: data['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'title': title,
      'type': type,
      'date': date,
      'summary': summary,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  OperationalReport copyWith({
    String? title,
    String? type,
    String? date,
    String? summary,
    String? updatedAt,
  }) {
    return OperationalReport(
      id: id,
      restaurantId: restaurantId,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      summary: summary ?? this.summary,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Restaurant Settings & Control Center model with Firestore persistence.
/// Collection: settings/{restaurantId}
class RestaurantSettings {
  final String restaurantId;
  final String restaurantName;
  final String branchName;
  final String openingTime;
  final String closingTime;
  final int maxSeatingCapacity;
  final bool notificationEnabled;
  final bool autoTableAlerts;

  const RestaurantSettings({
    required this.restaurantId,
    required this.restaurantName,
    required this.branchName,
    required this.openingTime,
    required this.closingTime,
    required this.maxSeatingCapacity,
    required this.notificationEnabled,
    required this.autoTableAlerts,
  });

  factory RestaurantSettings.fromMap(Map<String, dynamic> data, String restaurantId) {
    return RestaurantSettings(
      restaurantId: restaurantId,
      restaurantName: data['restaurantName'] ?? 'The Grand Bistro',
      branchName: data['branchName'] ?? 'Main City Branch',
      openingTime: data['openingTime'] ?? '11:00 AM',
      closingTime: data['closingTime'] ?? '11:00 PM',
      maxSeatingCapacity: data['maxSeatingCapacity'] ?? 24,
      notificationEnabled: data['notificationEnabled'] ?? true,
      autoTableAlerts: data['autoTableAlerts'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'branchName': branchName,
      'openingTime': openingTime,
      'closingTime': closingTime,
      'maxSeatingCapacity': maxSeatingCapacity,
      'notificationEnabled': notificationEnabled,
      'autoTableAlerts': autoTableAlerts,
    };
  }

  static const RestaurantSettings initial = RestaurantSettings(
    restaurantId: 'default_bistro_01',
    restaurantName: 'The Grand Bistro',
    branchName: 'Main City Branch',
    openingTime: '11:00 AM',
    closingTime: '11:00 PM',
    maxSeatingCapacity: 24,
    notificationEnabled: true,
    autoTableAlerts: true,
  );
}

/// Helper service for fetching Firestore analytics with local fallbacks.
/// Keeps code viva-friendly and minimal, avoiding bulky repository patterns.
class FirebaseDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch or Stream analytics records for a specific type and period
  static Stream<List<AnalyticsRecord>> streamAnalytics({
    required String restaurantId,
    required String type,
    required String period,
  }) {
    return _firestore
        .collection('analytics')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('type', isEqualTo: type)
        .where('period', isEqualTo: period)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AnalyticsRecord.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Ensure Owner document exists in owners/{ownerId}
  static Future<void> ensureOwnerProfile({
    required String ownerId,
    required String email,
    String? displayName,
  }) async {
    try {
      final docRef = _firestore.collection('owners').doc(ownerId);
      final docSnap = await docRef.get();
      if (!docSnap.exists) {
        await docRef.set({
          'name': displayName ?? 'Restaurant Owner',
          'email': email,
          'restaurantId': 'default_bistro_01',
          'restaurantName': 'The Grand Bistro',
          'branch': 'Main Branch',
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Graceful local handling
    }
  }
}
