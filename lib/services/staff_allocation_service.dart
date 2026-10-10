import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/staff_data.dart';

class StaffAllocationService {
  final FirebaseFirestore? _customFirestore;

  StaffAllocationService({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  FirebaseFirestore? get firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // STAFF MEMBERS CRUD
  // ===========================================================================

  Stream<List<StaffMember>> streamStaffMembers(String restaurantId) {
    final fs = firestore;
    if (fs == null) {
      return Stream.error(StateError('Firestore is unavailable.'));
    }
    return fs
        .collection('staff')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StaffMember.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error, stack) => throw error);
  }

  Future<void> addStaffMember(StaffMember staff) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    final docRef = fs.collection('staff').doc();
    await docRef.set(staff.toMap());
  }

  Future<void> updateStaffMember(StaffMember staff) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs.collection('staff').doc(staff.id).update(staff.toMap());
  }

  Future<void> deleteStaffMember(String id) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs.collection('staff').doc(id).delete();
  }

  Future<void> toggleStaffStatus(String id, String newStatus) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs.collection('staff').doc(id).update({'status': newStatus});
  }

  // ===========================================================================
  // STAFF ALLOCATIONS CRUD
  // ===========================================================================

  Stream<List<StaffAllocation>> streamAllocations(String restaurantId,
      {String? date}) {
    final fs = firestore;
    if (fs == null) {
      return Stream.error(StateError('Firestore is unavailable.'));
    }

    Query<Map<String, dynamic>> query = fs
        .collection('staff_allocations')
        .where('restaurantId', isEqualTo: restaurantId);

    if (date != null && date.isNotEmpty) {
      query = query.where('date', isEqualTo: date);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => StaffAllocation.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error, stack) => throw error);
  }

  Future<void> addAllocation(StaffAllocation allocation) async {
    final existing = await getExistingAllocationsForDate(
        allocation.restaurantId, allocation.date);
    final staff = (await streamStaffMembers(allocation.restaurantId).first)
        .firstWhere((member) => member.id == allocation.staffId,
            orElse: () => throw ArgumentError('Staff member not found.'));
    validateAllocation(
      staff: staff,
      existingAllocations: existing,
      date: allocation.date,
      startTime: allocation.startTime,
      endTime: allocation.endTime,
    );

    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    final docRef = fs.collection('staff_allocations').doc();
    await docRef.set(allocation.toMap());
  }

  Future<void> updateAllocation(StaffAllocation allocation) async {
    final existing = await getExistingAllocationsForDate(
        allocation.restaurantId, allocation.date);
    final staff = (await streamStaffMembers(allocation.restaurantId).first)
        .firstWhere((member) => member.id == allocation.staffId,
            orElse: () => throw ArgumentError('Staff member not found.'));
    validateAllocation(
      staff: staff,
      existingAllocations: existing,
      date: allocation.date,
      startTime: allocation.startTime,
      endTime: allocation.endTime,
      allocationId: allocation.id,
    );

    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs
        .collection('staff_allocations')
        .doc(allocation.id)
        .update(allocation.toMap());
  }

  Future<void> deleteAllocation(String id) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs.collection('staff_allocations').doc(id).delete();
  }

  Future<List<StaffAllocation>> getExistingAllocationsForDate(
      String restaurantId, String date) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    try {
      final snap = await fs
          .collection('staff_allocations')
          .where('restaurantId', isEqualTo: restaurantId)
          .where('date', isEqualTo: date)
          .get();

      return snap.docs
          .map((d) => StaffAllocation.fromMap(d.data(), d.id))
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  // ===========================================================================
  // PEAK HOUR CONFIGS CRUD
  // ===========================================================================

  Stream<List<PeakHourConfig>> streamPeakHours(String restaurantId) {
    final fs = firestore;
    if (fs == null) {
      return Stream.error(StateError('Firestore is unavailable.'));
    }

    return fs
        .collection('peak_hour_configs')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PeakHourConfig.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error, stack) => throw error);
  }

  Future<void> addPeakHourConfig(PeakHourConfig config) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    final docRef = fs.collection('peak_hour_configs').doc();
    await docRef.set(config.toMap());
  }

  Future<void> updatePeakHourConfig(PeakHourConfig config) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs
        .collection('peak_hour_configs')
        .doc(config.id)
        .update(config.toMap());
  }

  Future<void> deletePeakHourConfig(String id) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs.collection('peak_hour_configs').doc(id).delete();
  }

  // ===========================================================================
  // ALLOCATION RULES CRUD
  // ===========================================================================

  Stream<List<StaffAllocationRule>> streamRules(String restaurantId) {
    final fs = firestore;
    if (fs == null) {
      return Stream.error(StateError('Firestore is unavailable.'));
    }

    return fs
        .collection('staff_allocation_rules')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StaffAllocationRule.fromMap(doc.data(), doc.id))
          .toList();
    }).handleError((error, stack) => throw error);
  }

  Future<void> addRule(StaffAllocationRule rule) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    final docRef = fs.collection('staff_allocation_rules').doc();
    await docRef.set(rule.toMap());
  }

  Future<void> updateRule(StaffAllocationRule rule) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs
        .collection('staff_allocation_rules')
        .doc(rule.id)
        .update(rule.toMap());
  }

  Future<void> deleteRule(String id) async {
    final fs = firestore;
    if (fs == null) throw StateError('Firestore is unavailable.');
    await fs.collection('staff_allocation_rules').doc(id).delete();
  }

  // ===========================================================================
  // INTELLIGENT RECOMMENDATION & TIME LOGIC
  // ===========================================================================

  /// Convert time string ('HH:mm') to total minutes from 00:00.
  static int timeToMinutes(String time) {
    final clean = time.trim();
    final parts = clean.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  /// Check whether two time intervals overlap.
  static bool isTimeOverlapping(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    final s1 = timeToMinutes(start1);
    final e1 = timeToMinutes(end1);
    final s2 = timeToMinutes(start2);
    final e2 = timeToMinutes(end2);

    if (e1 <= s1 || e2 <= s2) return false;
    return s1 < e2 && s2 < e1;
  }

  /// Check whether a time string ('HH:mm') falls within [start, end].
  static bool isTimeWithin(String time, String start, String end) {
    final t = timeToMinutes(time);
    final s = timeToMinutes(start);
    final e = timeToMinutes(end);
    return t >= s && t < e;
  }

  /// Find overlapping allocation for the staff member on the given date if any.
  static StaffAllocation? checkStaffOverlap({
    required String staffId,
    required String date,
    required String startTime,
    required String endTime,
    required List<StaffAllocation> existingAllocations,
  }) {
    for (final alloc in existingAllocations) {
      if (alloc.staffId == staffId &&
          alloc.date == date &&
          alloc.status != 'Cancelled') {
        if (isTimeOverlapping(
            startTime, endTime, alloc.startTime, alloc.endTime)) {
          return alloc;
        }
      }
    }
    return null;
  }

  /// Get list of staff members who are Active and not allocated to an overlapping shift.
  static List<StaffMember> getAvailableStaffForSlot({
    required String date,
    required String startTime,
    required String endTime,
    required List<StaffMember> allStaff,
    required List<StaffAllocation> allocationsOnDate,
    String? currentStaffId, // exclude if currently editing
  }) {
    return allStaff.where((staff) {
      if (!staff.isActive) return false;
      if (!staff.isAvailableAt(startTime, endTime)) return false;

      final overlap = checkStaffOverlap(
        staffId: staff.id,
        date: date,
        startTime: startTime,
        endTime: endTime,
        existingAllocations: allocationsOnDate
            .where((a) => a.staffId != currentStaffId)
            .toList(),
      );

      return overlap == null;
    }).toList();
  }

  static void validateRulesDoNotOverlap(List<StaffAllocationRule> rules) {
    final activeRules = rules.where((rule) => rule.isActive).toList()
      ..sort((a, b) => a.minCustomers.compareTo(b.minCustomers));

    for (var i = 1; i < activeRules.length; i++) {
      final previous = activeRules[i - 1];
      final current = activeRules[i];
      if (current.minCustomers <= previous.maxCustomers) {
        throw ArgumentError(
          'Customer ranges cannot overlap: ${previous.minCustomers}-${previous.maxCustomers} and ${current.minCustomers}-${current.maxCustomers}',
        );
      }
    }
  }

  static void validateAllocation({
    required StaffMember staff,
    required List<StaffAllocation> existingAllocations,
    required String date,
    required String startTime,
    required String endTime,
    String? allocationId,
  }) {
    if (!staff.isActive) {
      throw ArgumentError('Staff member is inactive and cannot be allocated.');
    }
    if (!staff.isAvailableAt(startTime, endTime)) {
      throw ArgumentError('Staff member is unavailable during this time.');
    }
    if (timeToMinutes(endTime) <= timeToMinutes(startTime)) {
      throw ArgumentError('End time must be after start time.');
    }

    final overlap = checkStaffOverlap(
      staffId: staff.id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      existingAllocations: existingAllocations
          .where((allocation) => allocation.id != allocationId)
          .toList(),
    );
    if (overlap != null) {
      throw ArgumentError(
        'Staff member is already allocated during this time.',
      );
    }
  }

  /// Return day name from DateTime, e.g. 'Monday', 'Saturday'
  static String getDayOfWeekName(DateTime dt) {
    switch (dt.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Everyday';
    }
  }

  /// Find peak hour config matching the date & time slot.
  static PeakHourConfig? findPeakHourMatch({
    required DateTime date,
    required String time,
    required List<PeakHourConfig> peakConfigs,
  }) {
    final day = getDayOfWeekName(date);
    for (final config in peakConfigs) {
      if (!config.isEnabled) continue;
      if ((config.dayOfWeek == day || config.dayOfWeek == 'Everyday') &&
          isTimeWithin(time, config.startTime, config.endTime)) {
        return config;
      }
    }
    return null;
  }

  /// Find matching allocation rule for a customer count.
  static StaffAllocationRule findMatchingRule({
    required int customerCount,
    required List<StaffAllocationRule> rules,
  }) {
    validateRulesDoNotOverlap(rules);

    if (rules.isEmpty) {
      throw StateError('No staff allocation rules are configured.');
    }

    final activeRules = rules.where((rule) => rule.isActive).toList();
    for (final r in activeRules) {
      if (customerCount >= r.minCustomers && customerCount <= r.maxCustomers) {
        return r;
      }
    }

    final orderedRules = [...activeRules]
      ..sort((a, b) => a.minCustomers.compareTo(b.minCustomers));
    return orderedRules.isEmpty ? rules.first : orderedRules.last;
  }

  /// Count how many staff members are currently allocated for the given time on date.
  static int countAllocatedStaffForTime({
    required String date,
    required String time,
    required List<StaffAllocation> allocations,
  }) {
    return allocations.where((a) {
      return a.date == date &&
          a.status != 'Cancelled' &&
          isTimeWithin(time, a.startTime, a.endTime);
    }).length;
  }

  /// Read reservation guests and currently waiting queue records from Firestore.
  static Future<Map<String, int>> fetchReservationQueueDemand({
    required FirebaseFirestore? firestore,
    required String restaurantId,
    required String date,
    required String time,
  }) async {
    if (firestore == null) throw StateError('Firestore is unavailable.');
    final snapRes = await firestore
        .collection('reservations')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('date', isEqualTo: date)
        .where('time', isEqualTo: time)
        .get();

    final snapQueue = await firestore
        .collection('queues')
        .where('restaurantId', isEqualTo: restaurantId)
        .where('status', isEqualTo: 'Waiting')
        .get();

    final reservationGuests = snapRes.docs.fold<int>(0, (total, doc) {
      final guests = doc.data()['guests'];
      return total + (guests is num && guests > 0 ? guests.toInt() : 0);
    });
    return {
      'reservations': reservationGuests,
      'queue': snapQueue.docs.length,
    };
  }

  /// Complete intelligent recommendation calculation combining:
  /// 1. Expected Customers (Reservations + Queue)
  /// 2. Demand Level
  /// 3. Allocation Rule
  /// 4. Peak Hour check & override
  /// 5. Current Allocation count
  /// 6. Staff Shortage / Surplus computation
  static RecommendationResult calculateRecommendation({
    required DateTime date,
    required String time,
    required int reservations,
    required int queue,
    required List<PeakHourConfig> peakConfigs,
    required List<StaffAllocationRule> rules,
    required List<StaffAllocation> allocationsOnDate,
  }) {
    final totalCustomers = reservations + queue;

    // 1. Find matching rule
    final rule = findMatchingRule(
      customerCount: totalCustomers,
      rules: rules,
    );

    // 2. Check Peak Hour configuration
    final peakConfig = findPeakHourMatch(
      date: date,
      time: time,
      peakConfigs: peakConfigs,
    );

    final isPeak = peakConfig != null;

    // Determine final demand level and recommended staff
    String finalDemand = rule.demandLevel;
    int recommended = rule.recommendedStaff;

    if (peakConfig != null) {
      if (peakConfig.recommendedStaff > recommended) {
        recommended = peakConfig.recommendedStaff;
      }
      if (peakConfig.demandLevel == 'Very High' || finalDemand == 'Low') {
        finalDemand = peakConfig.demandLevel;
      }
    }

    // 3. Count currently allocated staff for this time slot
    final dateStr = date.toIso8601String().substring(0, 10);
    final allocated = countAllocatedStaffForTime(
      date: dateStr,
      time: time,
      allocations: allocationsOnDate,
    );

    // 4. Shortage = recommended - allocated
    final shortage = recommended - allocated;

    return RecommendationResult(
      expectedReservations: reservations,
      currentQueue: queue,
      totalExpectedCustomers: totalCustomers,
      demandLevel: finalDemand,
      isPeakHour: isPeak,
      recommendedStaff: recommended,
      allocatedStaff: allocated,
      shortage: shortage,
      matchedPeakConfig: peakConfig,
      matchedRule: rule,
    );
  }
}
