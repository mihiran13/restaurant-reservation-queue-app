import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../theme.dart';
import '../../data/firebase_data.dart';
import '../../services/staff_allocation_service.dart';
import '../../widgets/app_header.dart';
import '../../widgets/owner_navigation.dart';
import 'settings_screen.dart';
import 'staff_management_screen.dart';

/// Operational Reports Screen faithful to the Assignment 2 prototype with genuine Firestore CRUD
class OperationalReportsScreen extends StatefulWidget {
  final String restaurantId;

  const OperationalReportsScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<OperationalReportsScreen> createState() =>
      _OperationalReportsScreenState();
}

class _OperationalReportsScreenState extends State<OperationalReportsScreen> {
  String _selectedFilter = 'All';
  final List<String> _reportTypes = [
    'Sales Report',
    'Orders Report',
    'Staff Report',
    'Staff Allocation Report',
    'Inventory Report',
  ];

  final StaffAllocationService _staffService = StaffAllocationService();

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      FirebaseFirestore.instance.collection('reports');

  String _dateString(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<OperationalReport> _generateReport({
    required String type,
    required String title,
    required String date,
    String? createdAt,
  }) async {
    var details = <Map<String, dynamic>>[];
    String summary;

    if (type == 'Staff Report') {
      final staff =
          await _staffService.streamStaffMembers(widget.restaurantId).first;
      details = staff
          .map((member) => {
                'name': member.name,
                'staffId': member.id,
                'role': member.role,
                'status': member.status,
              })
          .toList();
      summary = details.isEmpty
          ? 'No staff records are available.'
          : '${details.length} staff members found.';
    } else if (type == 'Staff Allocation Report') {
      final allocations =
          await _staffService.streamAllocations(widget.restaurantId).first;
      details = allocations
          .where((allocation) => allocation.date == date)
          .map((allocation) => {
                'staffName': allocation.staffName,
                'staffId': allocation.staffId,
                'date': allocation.date,
                'startTime': allocation.startTime,
                'endTime': allocation.endTime,
              })
          .toList();
      summary = details.isEmpty
          ? 'No staff allocations were found for $date.'
          : '${details.length} allocations found for $date.';
    } else if (type == 'Inventory Report') {
      summary =
          'Inventory reporting is unavailable: this project has no inventory collection or inventory model configured.';
    } else {
      summary = type == 'Sales Report'
          ? 'Sales reporting is unavailable: this project has no order or payment collection/model configured.'
          : 'Orders reporting is unavailable: this project has no order collection or order model configured.';
    }

    return OperationalReport(
      id: '',
      restaurantId: widget.restaurantId,
      title: title.trim().isEmpty ? type : title.trim(),
      type: type,
      date: date,
      dateRange: date,
      summary: summary,
      details: details,
      createdAt: createdAt ?? DateTime.now().toIso8601String(),
    );
  }

  Future<void> _refreshReport(OperationalReport report) async {
    try {
      final refreshed = await _generateReport(
        type: report.type,
        title: report.title,
        date: report.dateRange.isEmpty ? report.date : report.dateRange,
        createdAt: report.createdAt,
      );
      await _reportsRef.doc(report.id).update({
        ...refreshed.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      _showMessage('Report refreshed with the latest database data.');
    } catch (error) {
      _showMessage('Could not refresh report: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateMainSection(int index) {
    if (index == 3) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 2) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              StaffManagementScreen(restaurantId: widget.restaurantId)));
    } else if (index == 4) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SettingsScreen(restaurantId: widget.restaurantId)));
    }
  }

  // ==========================================
  // CRUD OPERATION 1: CREATE (Firestore Add)
  // ==========================================
  Future<void> _showCreateReportDialog({String? initialType}) async {
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    String selectedType = initialType ?? _reportTypes.first;
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.post_add_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Create Operational Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Report Title',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sunday Lunch Rush Evaluation',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter a report title'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Report Category',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _reportTypes
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Audit Date',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2027),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.cardBorder),
                          borderRadius: BorderRadius.circular(12),
                          color: AppTheme.textPrimary,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                  fontSize: 14, color: AppTheme.textPrimary),
                            ),
                            const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Operational Summary & Findings',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: summaryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Describe table turn rates, waiting surges, or staffing notes...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter report findings'
                          : null,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop();
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      final newReport = await _generateReport(
                        type: selectedType,
                        title: titleController.text,
                        date: _dateString(selectedDate),
                      );
                      await _reportsRef.add(newReport.toMap());
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Report successfully created and saved to Firestore!'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error creating report: $e'),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CRUD OPERATION 2: UPDATE (Firestore Edit)
  // ==========================================
  Future<void> _showEditReportDialog(OperationalReport report) async {
    final titleController = TextEditingController(text: report.title);
    final summaryController = TextEditingController(text: report.summary);
    String selectedType =
        _reportTypes.contains(report.type) ? report.type : _reportTypes.first;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppTheme.primary),
                SizedBox(width: 8),
                Text(
                  'Edit Operational Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Report Title',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter a report title'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text('Report Category',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _reportTypes
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(fontSize: 14))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Operational Summary & Findings',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: summaryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Please enter report findings'
                          : null,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(ctx).pop();
                    final messenger = ScaffoldMessenger.of(context);

                    try {
                      // Genuine Firestore UPDATE
                      if (report.id.startsWith('seed_')) {
                        // If it's a seed record being edited for the first time, persist it as a real Firestore document
                        await _reportsRef.doc(report.id).set({
                          ...report.toMap(),
                          'title': titleController.text.trim(),
                          'type': selectedType,
                          'summary': summaryController.text.trim(),
                          'updatedAt': DateTime.now().toIso8601String(),
                        });
                      } else {
                        await _reportsRef.doc(report.id).update({
                          'title': titleController.text.trim(),
                          'type': selectedType,
                          'summary': summaryController.text.trim(),
                          'updatedAt': DateTime.now().toIso8601String(),
                        });
                      }

                      messenger.showSnackBar(
                        const SnackBar(
                          content:
                              Text('Report updated successfully in Firestore!'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error updating report: $e'),
                          backgroundColor: AppTheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Update Report'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // CRUD OPERATION 3: DELETE (Firestore Delete)
  // ==========================================
  Future<void> _confirmDeleteReport(OperationalReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Report',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
            'Are you sure you want to permanently delete "${report.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Genuine Firestore DELETE
        await _reportsRef.doc(report.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Report deleted from Firestore.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting report: $e'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _getReportsStream() {
    if (Firebase.apps.isEmpty) {
      return Stream.error(StateError('Firebase is not initialized.'));
    }
    try {
      return _reportsRef
          .where('restaurantId', isEqualTo: widget.restaurantId)
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
          // App Header
          AppHeader(
            title: 'Operational Reports',
            subtitle: 'Audits, Shift Logs & Service Summaries',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: AppTheme.primary, size: 26),
              tooltip: 'New Report',
              onPressed: _showCreateReportDialog,
            ),
          ),

          // Category Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  ..._reportTypes.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(type),
                      )),
                ],
              ),
            ),
          ),

          // ==========================================
          // CRUD OPERATION 4: READ (Firestore Stream)
          // ==========================================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _getReportsStream(),
              builder: (context, snapshot) {
                // Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                // Error State
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_off_rounded,
                              size: 48, color: AppTheme.error),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load Firestore reports',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                List<OperationalReport> reports = docs.map((doc) {
                  return OperationalReport.fromMap(doc.data(), doc.id);
                }).toList();

                final savedTypes = reports.map((report) => report.type).toSet();
                final today = _dateString(DateTime.now());
                reports = [
                  ...reports,
                  ..._reportTypes
                      .where((type) => !savedTypes.contains(type))
                      .map(
                        (type) => OperationalReport(
                          id: '',
                          restaurantId: widget.restaurantId,
                          title: type,
                          type: type,
                          date: today,
                          dateRange: today,
                          summary: 'This report has not been generated yet.',
                          createdAt: '',
                        ),
                      ),
                ];

                // Filter by selected category
                if (_selectedFilter != 'All') {
                  reports =
                      reports.where((r) => r.type == _selectedFilter).toList();
                }

                // Empty State
                if (reports.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBorder.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.description_outlined,
                                size: 40, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Reports Found',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap the "+" button above to log a new operational audit or shift summary.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Reports List
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(report);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.textPrimary,
        elevation: 2,
        onPressed: _showCreateReportDialog,
        tooltip: 'Create Report',
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: OwnerNavigation(
          currentIndex: 3, onItemSelected: _navigateMainSection),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(OperationalReport report) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.surfaceElevated.withValues(alpha: 0.45),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getTypeColor(report.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    report.type,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getTypeColor(report.type),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      report.date,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 4),
                    if (report.id.isNotEmpty)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded,
                            size: 18, color: AppTheme.textSecondary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (action) {
                          if (action == 'view') {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    ReportDetailsScreen(report: report)));
                          } else if (action == 'refresh') {
                            _refreshReport(report);
                          } else if (action == 'edit') {
                            _showEditReportDialog(report);
                          } else if (action == 'delete') {
                            _confirmDeleteReport(report);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined,
                                    size: 18, color: AppTheme.primary),
                                SizedBox(width: 10),
                                Text('View Report',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'refresh',
                            child: Row(
                              children: [
                                Icon(Icons.refresh_rounded,
                                    size: 18, color: AppTheme.accent),
                                SizedBox(width: 10),
                                Text('Refresh Report',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: AppTheme.textPrimary),
                                SizedBox(width: 10),
                                Text('Edit Report',
                                    style: TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    size: 18, color: AppTheme.error),
                                SizedBox(width: 10),
                                Text('Delete Report',
                                    style: TextStyle(
                                        fontSize: 13, color: AppTheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              report.summary,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            if (report.id.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showCreateReportDialog(initialType: report.type),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                  label: const Text('Generate Report'),
                ),
              ),
            if (report.updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Edited recently in Firestore',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textMuted.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => ReportDetailsScreen(report: report)),
                ),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('View Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Orders Report':
        return AppTheme.accentBlue;
      case 'Staff Report':
        return AppTheme.accentGreen;
      case 'Inventory Report':
        return AppTheme.warning;
      case 'Staff Allocation Report':
        return AppTheme.primary;
      case 'Sales Report':
        return AppTheme.accent;
      default:
        return AppTheme.primary;
    }
  }
}

class ReportDetailsScreen extends StatelessWidget {
  final OperationalReport report;

  const ReportDetailsScreen({super.key, required this.report});

  String _value(Object? value) => value == null ? '-' : '$value';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text(report.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(report.type,
              style: const TextStyle(
                  color: AppTheme.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Generated: ${report.createdAt}',
              style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
              'Date range: ${report.dateRange.isEmpty ? report.date : report.dateRange}',
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(report.summary,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, height: 1.4)),
            ),
          ),
          const SizedBox(height: 16),
          if (report.details.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                    'No detailed records are available for this report.',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...report.details.map(
              (detail) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Text(
                                  '${entry.key}: ${_value(entry.value)}',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary)),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
