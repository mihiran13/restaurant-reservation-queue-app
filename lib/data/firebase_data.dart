// Lightweight data models, Firestore integration, and persistence helpers for Owner Module.
// Covers OwnerProfile, RestaurantSettings, OperationalReport, DashboardSummary, and AnalyticsRecord.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      branch: data['branch'] ?? '',
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
  final int? totalGuestsToday;
  final String? avgWaitTime;
  final double? turnoverRate;
  final int? activeTables;
  final int? totalTables;
  final String? restaurantStatus;

  const DashboardSummary({
    required this.totalGuestsToday,
    required this.avgWaitTime,
    required this.turnoverRate,
    required this.activeTables,
    required this.totalTables,
    required this.restaurantStatus,
  });

  static const DashboardSummary initial = DashboardSummary(
    totalGuestsToday: null,
    avgWaitTime: null,
    turnoverRate: null,
    activeTables: null,
    totalTables: null,
    restaurantStatus: null,
  );

  factory DashboardSummary.fromMap(Map<String, dynamic> data) {
    return DashboardSummary(
      totalGuestsToday: data['totalGuestsToday'] is num
          ? (data['totalGuestsToday'] as num).toInt()
          : null,
      avgWaitTime: data['avgWaitTime']?.toString(),
      turnoverRate: data['turnoverRate'] is num
          ? (data['turnoverRate'] as num).toDouble()
          : null,
      activeTables: data['activeTables'] is num
          ? (data['activeTables'] as num).toInt()
          : null,
      totalTables: data['totalTables'] is num
          ? (data['totalTables'] as num).toInt()
          : null,
      restaurantStatus: data['restaurantStatus']?.toString(),
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
  final String
      type; // 'peak_hours', 'turnover', 'walk_away', 'waiting_time', 'no_show'
  final String period; // 'Today', 'This Week', 'This Month'
  final String label;
  final double? value;
  final String? displayValue;
  final double? secondaryValue;

  const AnalyticsRecord({
    required this.id,
    required this.restaurantId,
    required this.date,
    required this.type,
    required this.period,
    required this.label,
    required this.value,
    this.displayValue,
    this.secondaryValue,
  });

  factory AnalyticsRecord.fromMap(Map<String, dynamic> data, String id) {
    return AnalyticsRecord(
      id: id,
      restaurantId: data['restaurantId']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      period: data['period']?.toString() ?? '',
      label: data['label']?.toString() ?? '',
      value: data['value'] is num && (data['value'] as num).toDouble().isFinite
          ? (data['value'] as num).toDouble()
          : null,
      displayValue: data['displayValue']?.toString(),
      secondaryValue: data['secondaryValue'] is num &&
              (data['secondaryValue'] as num).toDouble().isFinite
          ? (data['secondaryValue'] as num).toDouble()
          : null,
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

class AnalyticsMetrics {
  static int? totalGuestsFromTodayPeakBuckets(
    Iterable<AnalyticsRecord> records,
  ) {
    final buckets = records.where(
      (record) => record.type == 'peak_hours' && record.period == 'Today',
    );
    final labels = <String>{};
    var total = 0;
    var foundBucket = false;

    for (final bucket in buckets) {
      final label = bucket.label.trim();
      final value = bucket.value;
      if (label.isEmpty ||
          !labels.add(label) ||
          value == null ||
          !value.isFinite ||
          value < 0 ||
          value != value.truncateToDouble()) {
        return null;
      }
      total += value.toInt();
      foundBucket = true;
    }

    return foundBucket ? total : null;
  }
}

/// Operational Report model with Firestore CRUD support.
/// Collection: reports/{reportId}
class OperationalReport {
  final String id;
  final String restaurantId;
  final String title;
  final String
      type; // e.g. 'Daily Shift', 'Weekly Summary', 'Turnover Audit', 'Waitlist Review'
  final String date;
  final String summary;
  final String createdAt;
  final String? updatedAt;
  final String dateRange;
  final List<Map<String, dynamic>> details;

  const OperationalReport({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.type,
    required this.date,
    required this.summary,
    required this.createdAt,
    this.updatedAt,
    this.dateRange = '',
    this.details = const [],
  });

  factory OperationalReport.fromMap(Map<String, dynamic> data, String id) {
    return OperationalReport(
      id: id,
      restaurantId: data['restaurantId']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      date: data['date']?.toString() ?? '',
      summary: data['summary']?.toString() ?? '',
      createdAt: data['createdAt']?.toString() ?? '',
      updatedAt: data['updatedAt']?.toString(),
      dateRange:
          data['dateRange']?.toString() ?? data['date']?.toString() ?? '',
      details: data['details'] is List
          ? (data['details'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : const [],
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
      'dateRange': dateRange,
      'details': details,
    };
  }

  OperationalReport copyWith({
    String? title,
    String? type,
    String? date,
    String? summary,
    String? updatedAt,
    String? dateRange,
    List<Map<String, dynamic>>? details,
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
      dateRange: dateRange ?? this.dateRange,
      details: details ?? this.details,
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

  factory RestaurantSettings.fromMap(
      Map<String, dynamic> data, String restaurantId) {
    return RestaurantSettings(
      restaurantId: restaurantId,
      restaurantName: data['restaurantName'] ?? '',
      branchName: data['branchName'] ?? '',
      openingTime: data['openingTime']?.toString() ?? '',
      closingTime: data['closingTime']?.toString() ?? '',
      maxSeatingCapacity: data['maxSeatingCapacity'] is num
          ? (data['maxSeatingCapacity'] as num).toInt()
          : 0,
      notificationEnabled: data['notificationEnabled'] == true,
      autoTableAlerts: data['autoTableAlerts'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
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
    restaurantName: '',
    branchName: '',
    openingTime: '',
    closingTime: '',
    maxSeatingCapacity: 0,
    notificationEnabled: false,
    autoTableAlerts: false,
  );
}

/// Helper service for Firestore analytics and owner-profile persistence.
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != ownerId) {
      throw StateError('The authenticated owner does not match this profile.');
    }
    final token = await user.getIdTokenResult();
    final restaurantId = token.claims?['restaurantId']?.toString();
    if (restaurantId == null || restaurantId.isEmpty) {
      throw StateError(
          'This account has no restaurant access configured. Contact the Firebase administrator.');
    }

    final docRef = _firestore.collection('owners').doc(ownerId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      if (docSnap.data()?['restaurantId'] != restaurantId) {
        throw StateError(
            'Owner profile restaurant does not match the authenticated account.');
      }
    } else {
      await docRef.set({
        'name': displayName ?? '',
        'email': email,
        'restaurantId': restaurantId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
