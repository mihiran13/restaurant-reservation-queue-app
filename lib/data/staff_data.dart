// Models for Staff Management and Staff Allocation Feature
// Supports StaffMember, StaffAllocation, PeakHourConfig, StaffAllocationRule, and ReservationDemandInfo.

class StaffMember {
  final String id;
  final String restaurantId;
  final String name;
  final String phone;
  final String email;
  final String role; // Manager, Waiter, Cashier, Kitchen Staff, Host, Cleaner, Other
  final String department; // Dining Hall, Kitchen, Front Desk, Counter, Bar, Sanitation
  final String status; // 'Active', 'Inactive'
  final String availableHours; // e.g. '08:00 - 16:00', 'Morning Shift', 'All Day'
  final String availableFrom; // HH:mm, 24-hour time
  final String availableTo; // HH:mm, 24-hour time
  final int maxDailyHours; // e.g. 8
  final DateTime? createdAt;

  const StaffMember({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.department,
    this.status = 'Active',
    this.availableHours = '08:00 - 17:00',
    this.availableFrom = '08:00',
    this.availableTo = '17:00',
    this.maxDailyHours = 8,
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool isAvailableAt(String startTime, String endTime) {
    final startMinutes = _timeToMinutes(startTime);
    final endMinutes = _timeToMinutes(endTime);
    final earliestMinutes = _timeToMinutes(availableFrom);
    final latestMinutes = _timeToMinutes(availableTo);
    return startMinutes >= earliestMinutes && endMinutes <= latestMinutes;
  }

  static int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  factory StaffMember.fromMap(Map<String, dynamic> data, String id) {
    return StaffMember(
      id: id,
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Waiter',
      department: data['department'] ?? 'Dining Hall',
      status: data['status'] ?? 'Active',
      availableHours: data['availableHours'] ?? '08:00 - 17:00',
      availableFrom: data['availableFrom'] ?? _extractTimeFromHours(data['availableHours']) ?? '08:00',
      availableTo: data['availableTo'] ?? _extractTimeToHours(data['availableHours']) ?? '17:00',
      maxDailyHours: (data['maxDailyHours'] is num) ? (data['maxDailyHours'] as num).toInt() : 8,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) : null,
    );
  }

  static String? _extractTimeFromHours(Object? availableHours) {
    if (availableHours is! String) return null;
    final match = RegExp(r'^(\d{1,2}:\d{2})').firstMatch(availableHours);
    return match?.group(1);
  }

  static String? _extractTimeToHours(Object? availableHours) {
    if (availableHours is! String) return null;
    final match = RegExp(r'-(\s*\d{1,2}:\d{2})').firstMatch(availableHours);
    return match?.group(1)?.trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'department': department,
      'status': status,
      'availableHours': availableHours,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
      'maxDailyHours': maxDailyHours,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  StaffMember copyWith({
    String? name,
    String? phone,
    String? email,
    String? role,
    String? department,
    String? status,
    String? availableHours,
    String? availableFrom,
    String? availableTo,
    int? maxDailyHours,
  }) {
    return StaffMember(
      id: id,
      restaurantId: restaurantId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      department: department ?? this.department,
      status: status ?? this.status,
      availableHours: availableHours ?? this.availableHours,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      maxDailyHours: maxDailyHours ?? this.maxDailyHours,
      createdAt: createdAt,
    );
  }
}

class StaffAllocation {
  final String id;
  final String restaurantId;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm (24-hour format)
  final String endTime; // HH:mm (24-hour format)
  final String staffId;
  final String staffName;
  final String staffRole;
  final String assignedArea;
  final String shiftType; // 'Normal', 'Peak', 'Low Demand'
  final String status; // 'Scheduled', 'Active', 'Completed', 'Cancelled'
  final String notes;
  final DateTime? createdAt;

  const StaffAllocation({
    required this.id,
    required this.restaurantId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.staffId,
    required this.staffName,
    required this.staffRole,
    required this.assignedArea,
    this.shiftType = 'Normal',
    this.status = 'Scheduled',
    this.notes = '',
    this.createdAt,
  });

  factory StaffAllocation.fromMap(Map<String, dynamic> data, String id) {
    return StaffAllocation(
      id: id,
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      date: data['date'] ?? '',
      startTime: data['startTime'] ?? '09:00',
      endTime: data['endTime'] ?? '17:00',
      staffId: data['staffId'] ?? '',
      staffName: data['staffName'] ?? '',
      staffRole: data['staffRole'] ?? 'Staff',
      assignedArea: data['assignedArea'] ?? 'Dining Area',
      shiftType: data['shiftType'] ?? 'Normal',
      status: data['status'] ?? 'Scheduled',
      notes: data['notes'] ?? '',
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'staffId': staffId,
      'staffName': staffName,
      'staffRole': staffRole,
      'assignedArea': assignedArea,
      'shiftType': shiftType,
      'status': status,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  StaffAllocation copyWith({
    String? date,
    String? startTime,
    String? endTime,
    String? staffId,
    String? staffName,
    String? staffRole,
    String? assignedArea,
    String? shiftType,
    String? status,
    String? notes,
  }) {
    return StaffAllocation(
      id: id,
      restaurantId: restaurantId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      staffId: staffId ?? this.staffId,
      staffName: staffName ?? this.staffName,
      staffRole: staffRole ?? this.staffRole,
      assignedArea: assignedArea ?? this.assignedArea,
      shiftType: shiftType ?? this.shiftType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}

class PeakHourConfig {
  final String id;
  final String restaurantId;
  final String dayOfWeek; // 'Monday', 'Tuesday', ..., 'Sunday', or 'Everyday'
  final String startTime; // HH:mm (24-hour format)
  final String endTime; // HH:mm (24-hour format)
  final String demandLevel; // 'Low', 'Normal', 'High', 'Very High'
  final int minStaff;
  final int recommendedStaff;
  final String status; // 'Enabled', 'Disabled'

  const PeakHourConfig({
    required this.id,
    required this.restaurantId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.demandLevel,
    required this.minStaff,
    required this.recommendedStaff,
    this.status = 'Enabled',
  });

  bool get isEnabled => status.toLowerCase() == 'enabled';

  factory PeakHourConfig.fromMap(Map<String, dynamic> data, String id) {
    return PeakHourConfig(
      id: id,
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      dayOfWeek: data['dayOfWeek'] ?? 'Monday',
      startTime: data['startTime'] ?? '18:00',
      endTime: data['endTime'] ?? '21:00',
      demandLevel: data['demandLevel'] ?? 'High',
      minStaff: (data['minStaff'] is num) ? (data['minStaff'] as num).toInt() : 5,
      recommendedStaff: (data['recommendedStaff'] is num) ? (data['recommendedStaff'] as num).toInt() : 7,
      status: data['status'] ?? 'Enabled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'demandLevel': demandLevel,
      'minStaff': minStaff,
      'recommendedStaff': recommendedStaff,
      'status': status,
    };
  }

  PeakHourConfig copyWith({
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? demandLevel,
    int? minStaff,
    int? recommendedStaff,
    String? status,
  }) {
    return PeakHourConfig(
      id: id,
      restaurantId: restaurantId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      demandLevel: demandLevel ?? this.demandLevel,
      minStaff: minStaff ?? this.minStaff,
      recommendedStaff: recommendedStaff ?? this.recommendedStaff,
      status: status ?? this.status,
    );
  }
}

class StaffAllocationRule {
  final String id;
  final String restaurantId;
  final int minCustomers;
  final int maxCustomers;
  final String demandLevel; // 'Low', 'Normal', 'High', 'Very High'
  final int recommendedStaff;
  final int minimumStaff;
  final String status; // 'Active', 'Inactive'

  const StaffAllocationRule({
    required this.id,
    required this.restaurantId,
    required this.minCustomers,
    required this.maxCustomers,
    required this.demandLevel,
    required this.recommendedStaff,
    this.minimumStaff = 1,
    this.status = 'Active',
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory StaffAllocationRule.fromMap(Map<String, dynamic> data, String id) {
    return StaffAllocationRule(
      id: id,
      restaurantId: data['restaurantId'] ?? 'default_bistro_01',
      minCustomers: (data['minCustomers'] is num) ? (data['minCustomers'] as num).toInt() : 0,
      maxCustomers: (data['maxCustomers'] is num) ? (data['maxCustomers'] as num).toInt() : 10,
      demandLevel: data['demandLevel'] ?? 'Normal',
      recommendedStaff: (data['recommendedStaff'] is num) ? (data['recommendedStaff'] as num).toInt() : 4,
      minimumStaff: (data['minimumStaff'] is num) ? (data['minimumStaff'] as num).toInt() : 1,
      status: data['status'] ?? 'Active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'minCustomers': minCustomers,
      'maxCustomers': maxCustomers,
      'demandLevel': demandLevel,
      'recommendedStaff': recommendedStaff,
      'minimumStaff': minimumStaff,
      'status': status,
    };
  }

  StaffAllocationRule copyWith({
    int? minCustomers,
    int? maxCustomers,
    String? demandLevel,
    int? recommendedStaff,
    int? minimumStaff,
    String? status,
  }) {
    return StaffAllocationRule(
      id: id,
      restaurantId: restaurantId,
      minCustomers: minCustomers ?? this.minCustomers,
      maxCustomers: maxCustomers ?? this.maxCustomers,
      demandLevel: demandLevel ?? this.demandLevel,
      recommendedStaff: recommendedStaff ?? this.recommendedStaff,
      minimumStaff: minimumStaff ?? this.minimumStaff,
      status: status ?? this.status,
    );
  }
}

class RecommendationResult {
  final int expectedReservations;
  final int currentQueue;
  final int totalExpectedCustomers;
  final String demandLevel; // 'Low', 'Normal', 'High', 'Very High'
  final bool isPeakHour;
  final int recommendedStaff;
  final int allocatedStaff;
  final int shortage; // positive if shortage, 0 or negative if satisfied/surplus
  final PeakHourConfig? matchedPeakConfig;
  final StaffAllocationRule? matchedRule;

  const RecommendationResult({
    required this.expectedReservations,
    required this.currentQueue,
    required this.totalExpectedCustomers,
    required this.demandLevel,
    required this.isPeakHour,
    required this.recommendedStaff,
    required this.allocatedStaff,
    required this.shortage,
    this.matchedPeakConfig,
    this.matchedRule,
  });

  bool get hasShortage => shortage > 0;
  bool get isSatisfied => shortage <= 0;
}
