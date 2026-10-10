import 'package:flutter/material.dart';

import '../../data/staff_data.dart';
import '../../services/staff_allocation_service.dart';
import '../../theme.dart';
import '../../widgets/owner_navigation.dart';
import 'operational_reports.dart';
import 'settings_screen.dart';
import 'staff_allocation_screen.dart';

class StaffManagementScreen extends StatefulWidget {
  final String restaurantId;

  const StaffManagementScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final StaffAllocationService _service = StaffAllocationService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffMember> _filterStaff(List<StaffMember> staff) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return staff;
    return staff.where((member) {
      return member.name.toLowerCase().contains(query) ||
          member.role.toLowerCase().contains(query) ||
          member.id.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showStaffForm({StaffMember? staff}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: staff?.name ?? '');
    final phoneController = TextEditingController(text: staff?.phone ?? '');
    final emailController = TextEditingController(text: staff?.email ?? '');
    final roleController = TextEditingController(text: staff?.role ?? 'Waiter');
    final departmentController =
        TextEditingController(text: staff?.department ?? 'Dining Hall');
    final fromController =
        TextEditingController(text: staff?.availableFrom ?? '08:00');
    final toController =
        TextEditingController(text: staff?.availableTo ?? '17:00');
    var status = staff?.status ?? 'Active';

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title:
                Text(staff == null ? 'Add Staff Member' : 'Edit Staff Member'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(nameController, 'Name', required: true),
                    _field(phoneController, 'Phone', required: true),
                    _field(emailController, 'Email'),
                    _field(roleController, 'Role', required: true),
                    _field(departmentController, 'Department', required: true),
                    Row(
                      children: [
                        Expanded(
                            child: _field(fromController, 'Available from',
                                required: true)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _field(toController, 'Available to',
                                required: true)),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration:
                          const InputDecoration(labelText: 'Employment status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'Inactive', child: Text('Inactive')),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => status = value ?? status),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final from = _parseTime(fromController.text);
                  final to = _parseTime(toController.text);
                  if (from == null || to == null || to <= from) {
                    _showMessage(
                        'Use valid times and make sure the end is after the start.');
                    return;
                  }

                  final updated = StaffMember(
                    id: staff?.id ?? '',
                    restaurantId: widget.restaurantId,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    role: roleController.text.trim(),
                    department: departmentController.text.trim(),
                    status: status,
                    availableHours:
                        '${fromController.text.trim()} - ${toController.text.trim()}',
                    availableFrom: fromController.text.trim(),
                    availableTo: toController.text.trim(),
                    createdAt: staff?.createdAt,
                  );

                  try {
                    if (staff == null) {
                      await _service.addStaffMember(updated);
                    } else {
                      await _service.updateStaffMember(updated);
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    _showMessage(staff == null
                        ? 'Staff member added.'
                        : 'Staff member updated.');
                  } catch (error) {
                    _showMessage('Could not save staff member: $error');
                  }
                },
                child: Text(staff == null ? 'Add' : 'Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      emailController.dispose();
      roleController.dispose();
      departmentController.dispose();
      fromController.dispose();
      toController.dispose();
    }
  }

  Future<void> _deleteStaff(StaffMember staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete staff member?'),
        content: Text('Remove ${staff.name} from staff management?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteStaffMember(staff.id);
      _showMessage('Staff member deleted.');
    } catch (error) {
      _showMessage('Could not delete staff member: $error');
    }
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? '$label is required.'
                : null
            : null,
      ),
    );
  }

  int? _parseTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _navigateMainSection(int index) {
    if (index == 2) return;
    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (index == 3) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              OperationalReportsScreen(restaurantId: widget.restaurantId)));
    } else if (index == 4) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SettingsScreen(restaurantId: widget.restaurantId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            onPressed: _showStaffForm,
            tooltip: 'Add Staff',
            icon: const Icon(Icons.person_add_alt_1_rounded,
                color: AppTheme.primary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accent,
        foregroundColor: AppTheme.textInverse,
        icon: const Icon(Icons.calendar_month_rounded),
        label: const Text('Staff Allocation'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) =>
                  StaffAllocationScreen(restaurantId: widget.restaurantId)),
        ),
      ),
      bottomNavigationBar: OwnerNavigation(
          currentIndex: 2, onItemSelected: _navigateMainSection),
      body: StreamBuilder<List<StaffMember>>(
        stream: _service.streamStaffMembers(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Could not load staff: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final staff = _filterStaff(snapshot.data!);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, role, or staff ID',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              Expanded(
                child: staff.isEmpty
                    ? const Center(child: Text('No staff members found.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: staff.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final member = staff[index];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryLight,
                                foregroundColor: AppTheme.primary,
                                child: Text(member.name.isEmpty
                                    ? '?'
                                    : member.name[0].toUpperCase()),
                              ),
                              title: Text(member.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                  '${member.role}  |  ${member.id}  |  ${member.status}\n${member.phone}${member.email.isEmpty ? '' : '  |  ${member.email}'}'),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _showStaffForm(staff: member);
                                  }
                                  if (action == 'delete') _deleteStaff(member);
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
