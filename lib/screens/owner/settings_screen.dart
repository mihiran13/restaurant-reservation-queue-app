import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme.dart';
import '../../data/firebase_data.dart';
import '../../widgets/app_header.dart';
import '../../widgets/owner_navigation.dart';
import 'owner_login.dart';
import 'operational_reports.dart';
import 'staff_management_screen.dart';

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
  final _ownerNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _capacityController = TextEditingController();

  String _openingTime = '';
  String _closingTime = '';
  bool _notificationEnabled = false;
  bool _autoTableAlerts = false;

  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String? _profileImageUrl;
  String? _coverImageUrl;

  DocumentReference<Map<String, dynamic>>? get _settingsDoc {
    try {
      return FirebaseFirestore.instance
          .collection('settings')
          .doc(widget.restaurantId);
    } catch (_) {
      return null;
    }
  }

  DocumentReference<Map<String, dynamic>>? get _ownerDoc {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;
    return FirebaseFirestore.instance.collection('owners').doc(userId);
  }

  @override
  void initState() {
    super.initState();
    _loadSettingsFromFirestore();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
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
      final ownerSnap = await _ownerDoc?.get();
      final settingsData = docSnap?.data() ?? <String, dynamic>{};
      final ownerData = ownerSnap?.data() ?? <String, dynamic>{};

      if (docSnap != null && docSnap.exists && docSnap.data() != null) {
        final settings =
            RestaurantSettings.fromMap(settingsData, widget.restaurantId);
        final savedOwnerName =
            ownerData['ownerName'] ?? settingsData['ownerName'];
        _ownerNameController.text =
            savedOwnerName is String && savedOwnerName.trim().isNotEmpty
                ? savedOwnerName
                : FirebaseAuth.instance.currentUser?.displayName ??
                    'Restaurant Owner';
        _profileImageUrl =
            ownerData['profileImageUrl'] ?? settingsData['profileImageUrl'];
        _coverImageUrl = settingsData['coverImageUrl'];
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
        final savedOwnerName = ownerData['ownerName'] ?? ownerData['name'];
        _ownerNameController.text =
            savedOwnerName is String && savedOwnerName.trim().isNotEmpty
                ? savedOwnerName
                : FirebaseAuth.instance.currentUser?.displayName ??
                    'Restaurant Owner';
        _profileImageUrl = ownerData['profileImageUrl'];
        _coverImageUrl = settingsData['coverImageUrl'];
        _nameController.text = initial.restaurantName;
        _branchController.text = initial.branchName;
        _capacityController.text = '${initial.maxSeatingCapacity}';
        _openingTime = initial.openingTime;
        _closingTime = initial.closingTime;
        _notificationEnabled = initial.notificationEnabled;
        _autoTableAlerts = initial.autoTableAlerts;
      }
    } catch (e) {
      final initial = RestaurantSettings.initial;
      _nameController.text = initial.restaurantName;
      _branchController.text = initial.branchName;
      _capacityController.text = '${initial.maxSeatingCapacity}';
      _openingTime = initial.openingTime;
      _closingTime = initial.closingTime;
      _notificationEnabled = initial.notificationEnabled;
      _autoTableAlerts = initial.autoTableAlerts;
      _loadError = 'Could not load settings from Firestore: $e';
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
        await docRef.set({
          ...updatedSettings.toMap(),
          'ownerName': _ownerNameController.text.trim(),
          'profileImageUrl': _profileImageUrl,
          'coverImageUrl': _coverImageUrl,
        }, SetOptions(merge: true));
      }
      await _ownerDoc?.set({
        'name': _ownerNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'profileImageUrl': _profileImageUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Restaurant settings updated and saved to Firestore!'),
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

  Future<void> _pickAndUploadImage({required bool cover}) async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (image == null) return;
    setState(() => _isUploadingImage = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'owner';
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${cover ? 'cover' : 'profile'}.jpg';
      final ref = FirebaseStorage.instance.ref('restaurants/$userId/$fileName');
      await ref.putData(await image.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      setState(() {
        if (cover) {
          _coverImageUrl = url;
        } else {
          _profileImageUrl = url;
        }
      });
      await _persistProfileFields(
          {cover ? 'coverImageUrl' : 'profileImageUrl': url});
      _showMessage('Image uploaded and saved.');
    } catch (error) {
      _showMessage('Could not upload image: $error');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _removeImage({required bool cover}) async {
    setState(() {
      if (cover) {
        _coverImageUrl = null;
      } else {
        _profileImageUrl = null;
      }
    });
    try {
      await _persistProfileFields(
          {cover ? 'coverImageUrl' : 'profileImageUrl': null});
      _showMessage('Image removed and saved.');
    } catch (error) {
      _showMessage('Could not remove image: $error');
    }
  }

  Future<void> _persistProfileFields(Map<String, dynamic> fields) async {
    final docRef = _settingsDoc;
    if (docRef == null) throw StateError('Settings database is unavailable.');
    await docRef.set(fields, SetOptions(merge: true));
    final ownerFields = <String, dynamic>{};
    if (fields.containsKey('ownerName')) {
      ownerFields['ownerName'] = fields['ownerName'];
    }
    if (fields.containsKey('profileImageUrl')) {
      ownerFields['profileImageUrl'] = fields['profileImageUrl'];
    }
    if (ownerFields.isNotEmpty) {
      await _ownerDoc?.set(ownerFields, SetOptions(merge: true));
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editOwnerName() async {
    final controller = TextEditingController(text: _ownerNameController.text);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit owner name'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Owner name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(
                  dialogContext, controller.text.trim().isNotEmpty),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      setState(() => _ownerNameController.text = controller.text.trim());
      try {
        await _persistProfileFields({'ownerName': _ownerNameController.text});
        _showMessage('Owner name saved.');
      } catch (error) {
        _showMessage('Could not save owner name: $error');
      }
    }
    controller.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will return to the owner login screen.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OwnerLoginScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _pickTime(bool isOpening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening
          ? const TimeOfDay(hour: 11, minute: 0)
          : const TimeOfDay(hour: 23, minute: 0),
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

  void _navigateMainSection(int index) {
    if (index == 4) return;
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: AppTheme.textSecondary),
                  tooltip: 'Reload Settings',
                  onPressed: _loadSettingsFromFirestore,
                ),
                IconButton(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded, color: AppTheme.primary),
                  tooltip: 'Save Settings',
                  onPressed: _isSaving ? null : _saveSettingsToFirestore,
                ),
              ],
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
                          if (_loadError != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(_loadError!,
                                    style:
                                        const TextStyle(color: AppTheme.error)),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          // Usability Refinement: Logical Group 1 - Restaurant Information
                          _buildSectionTitle('Restaurant Information',
                              Icons.storefront_rounded),
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
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. The Grand Bistro',
                                    prefixIcon: Icon(Icons.restaurant_rounded,
                                        size: 20),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                          ? 'Please enter restaurant name'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                const Text('Branch Location / Identifier',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _branchController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Downtown Central',
                                    prefixIcon: Icon(Icons.location_on_outlined,
                                        size: 20),
                                  ),
                                  validator: (val) =>
                                      (val == null || val.trim().isEmpty)
                                          ? 'Please enter branch location'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                const Text('Total Seating Capacity (Tables)',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _capacityController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '24',
                                    prefixIcon: Icon(Icons.table_bar_outlined,
                                        size: 20),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Enter table capacity';
                                    }
                                    if (int.tryParse(val) == null) {
                                      return 'Must be a valid integer';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Usability Refinement: Logical Group 2 - Operating Hours
                          _buildSectionTitle(
                              'Operating Hours', Icons.access_time_rounded),
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
                                Container(
                                    width: 1,
                                    height: 48,
                                    color: AppTheme.cardBorder),
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
                          _buildSectionTitle('Preferences & Live Queue Alerts',
                              Icons.tune_rounded),
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
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text(
                                    'Alert when queue waiting time exceeds 25 minutes SLA',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _notificationEnabled = val);
                                  },
                                ),
                                const Divider(
                                    height: 1, color: AppTheme.cardBorder),
                                SwitchListTile(
                                  value: _autoTableAlerts,
                                  activeColor: AppTheme.primary,
                                  title: const Text(
                                    'Table Turnover Reminders',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: const Text(
                                    'Notify waitstaff when occupied tables exceed 60m duration',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                  onChanged: (val) {
                                    setState(() => _autoTableAlerts = val);
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                          const SizedBox(height: 20),
                          _buildAboutSection(),
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.privacy_tip_outlined,
                                  color: AppTheme.primary),
                              title: const Text('Privacy'),
                              subtitle: const Text(
                                  'How DinePulse stores owner and restaurant information'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const PrivacyScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text('Sign Out'),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.error),
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
      bottomNavigationBar: OwnerNavigation(
          currentIndex: 4, onItemSelected: _navigateMainSection),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _coverImageUrl == null
                      ? Container(
                          color: AppTheme.surfaceElevated,
                          child: const Icon(Icons.restaurant_rounded,
                              size: 44, color: AppTheme.textMuted))
                      : Image.network(_coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppTheme.surfaceElevated)),
                ),
              ),
              Positioned(
                bottom: 0,
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.surface,
                  child: CircleAvatar(
                    radius: 43,
                    backgroundColor: AppTheme.primaryLight,
                    backgroundImage: _profileImageUrl == null
                        ? null
                        : NetworkImage(_profileImageUrl!),
                    child: _profileImageUrl == null
                        ? const Icon(Icons.person_rounded,
                            size: 42, color: AppTheme.primary)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
            _ownerNameController.text.isEmpty
                ? 'Restaurant Owner'
                : _ownerNameController.text,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        TextButton.icon(
            onPressed: _editOwnerName,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit Profile')),
        if (_isUploadingImage) const LinearProgressIndicator(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
                onPressed: () => _pickAndUploadImage(cover: false),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                label: const Text('Profile photo')),
            TextButton.icon(
                onPressed: () => _pickAndUploadImage(cover: true),
                icon: const Icon(Icons.photo_library_outlined, size: 17),
                label: const Text('Cover photo')),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_profileImageUrl != null)
              TextButton(
                  onPressed: () => _removeImage(cover: false),
                  child: const Text('Remove profile')),
            if (_coverImageUrl != null)
              TextButton(
                  onPressed: () => _removeImage(cover: true),
                  child: const Text('Remove cover')),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.info_outline_rounded, color: AppTheme.primary),
        title: Text('About DinePulse'),
        subtitle: Text(
            'DinePulse helps restaurant owners manage reservations, queues, staff, and operations.\nVersion 1.0.0'),
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
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 16, color: AppTheme.primary),
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

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Privacy')),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'DinePulse stores owner profile information, restaurant settings, and selected image URLs in the configured Firebase project. Images are uploaded to Firebase Storage. This information is used to display and manage the owner portal. Review your Firebase project rules and access settings before production use.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
