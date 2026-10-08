import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme.dart';
import '../../data/firebase_data.dart';
import '../../widgets/app_header.dart';

/// Settings & Control Center Screen faithful to Assignment 2 prototype
/// Enhanced based on Milestone 02 usability feedback (logical visual grouping)
/// Supports genuine Firestore READ and UPDATE operations.
class SettingsScreen extends StatefulWidget {
  final String restaurantId;

  const SettingsScreen({
    super.key,
    this.restaurantId = 'default_bistro_01',
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _capacityController = TextEditingController();

  String _openingTime = '11:00 AM';
  String _closingTime = '11:00 PM';
  bool _notificationEnabled = true;
  bool _autoTableAlerts = true;

  bool _isLoading = true;
  bool _isSaving = false;

  DocumentReference<Map<String, dynamic>>? get _settingsDoc {
    try {
      return FirebaseFirestore.instance.collection('settings').doc(widget.restaurantId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirestore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // ==========================================
  // SETTINGS OPERATION 1: READ from Firestore
  // ==========================================
  Future<void> _loadSettingsFromFirestore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final docRef = _settingsDoc;
      final docSnap = docRef != null ? await docRef.get() : null;

      if (docSnap != null && docSnap.exists && docSnap.data() != null) {
        final settings = RestaurantSettings.fromMap(docSnap.data()!, widget.restaurantId);
        _nameController.text = settings.restaurantName;
        _branchController.text = settings.branchName;
        _capacityController.text = '${settings.maxSeatingCapacity}';
        _openingTime = settings.openingTime;
        _closingTime = settings.closingTime;
        _notificationEnabled = settings.notificationEnabled;
        _autoTableAlerts = settings.autoTableAlerts;
      } else {
        // First-time fallback / seed defaults
        final initial = RestaurantSettings.initial;
        _nameController.text = initial.restaurantName;
        _branchController.text = initial.branchName;
        _capacityController.text = '${initial.maxSeatingCapacity}';
        _openingTime = initial.openingTime;
        _closingTime = initial.closingTime;
        _notificationEnabled = initial.notificationEnabled;
        _autoTableAlerts = initial.autoTableAlerts;
      }
    } catch (e) {
      // In case of offline/network, use sensible defaults
      final initial = RestaurantSettings.initial;
      _nameController.text = initial.restaurantName;
      _branchController.text = initial.branchName;
      _capacityController.text = '${initial.maxSeatingCapacity}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // SETTINGS OPERATION 2: UPDATE (Save to Firestore)
  // ==========================================
  Future<void> _saveSettingsToFirestore() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedSettings = RestaurantSettings(
        restaurantId: widget.restaurantId,
        restaurantName: _nameController.text.trim(),
        branchName: _branchController.text.trim(),
        openingTime: _openingTime,
        closingTime: _closingTime,
        maxSeatingCapacity: int.tryParse(_capacityController.text.trim()) ?? 24,
        notificationEnabled: _notificationEnabled,
        autoTableAlerts: _autoTableAlerts,
      );

      // Persist to Firestore document: settings/{restaurantId}
      final docRef = _settingsDoc;
      if (docRef != null) {
        await docRef.set(updatedSettings.toMap(), SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant settings updated and saved to Firestore!'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update settings in Firestore: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? const TimeOfDay(hour: 11, minute: 0) : const TimeOfDay(hour: 23, minute: 0),
    );

    if (picked != null && mounted) {
      final formatted = picked.format(context);
      setState(() {
        if (isOpening) {
          _openingTime = formatted;
        } else {
          _closingTime = formatted;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          AppHeader(
            title: 'Control Center',
            subtitle: 'Restaurant Profile & Operational Settings',
            showBackButton: true,
            trailing: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
              tooltip: 'Reload Settings',
              onPressed: _loadSettingsFromFirestore,
            ),
          ),

          // Main Form Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Usability Refinement: Logical Group 1 - Restaurant Information
                          _buildSectionTitle('Restaurant Information', Icons.storefront_rounded),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Restaurant Name',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. The Grand Bistro',
                                    prefixIcon: Icon(Icons.restaurant_rounded, size: 20),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty) ? 'Please enter restaurant name' : null,
                                ),
                                const SizedBox(height: 16),
                                const Text('Branch Location / Identifier',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _branchController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Downtown Central',
                                    prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty) ? 'Please enter branch location' : null,
                                ),
                                const SizedBox(height: 16),
                                const Text('Total Seating Capacity (Tables)',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '24',
                                    prefixIcon: Icon(Icons.table_bar_outlined, size: 20),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Enter table capacity';
                                    if (int.tryParse(val) == null) return 'Must be a valid integer';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Usability Refinement: Logical Group 2 - Operating Hours
                          _buildSectionTitle('Operating Hours', Icons.access_time_rounded),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildTimePickerTile(
                                    label: 'Daily Opening',
                                    time: _openingTime,
                                    onTap: () => _pickTime(true),
                                  ),
                                ),
                                Container(width: 1, height: 48, color: AppTheme.cardBorder),
                                Expanded(
                                  child: _buildTimePickerTile(
                                    label: 'Daily Closing',
                                    time: _closingTime,
                                    onTap: () => _pickTime(false),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Usability Refinement: Logical Group 3 - Notifications & Queue Preferences
                          _buildSectionTitle('Preferences & Live Queue Alerts', Icons.tune_rounded),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  value: _notificationEnabled,
                                  activeColor: AppTheme.primary,
                                  title: const Text(
                                    'Peak Surge Notifications',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text(
                                    'Alert when queue waiting time exceeds 25 minutes SLA',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _notificationEnabled = val);
                                  },
                                ),
                                const Divider(height: 1, color: AppTheme.cardBorder),
                                SwitchListTile(
                                  value: _autoTableAlerts,
                                  activeColor: AppTheme.primary,
                                  title: const Text(
                                    'Table Turnover Reminders',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text(
                                    'Notify waitstaff when occupied tables exceed 60m duration',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _autoTableAlerts = val);
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Save Settings Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveSettingsToFirestore,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save_rounded, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save Settings to Firestore',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
