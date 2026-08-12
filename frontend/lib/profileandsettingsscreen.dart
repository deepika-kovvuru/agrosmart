import 'app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'api_service.dart';
import 'local_storage.dart';
import 'user_session.dart';
import 'translation_provider.dart';

// ─────────────────────────────────────────
// PROFILE & SETTINGS SCREEN
// ─────────────────────────────────────────

class ProfileSettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileSettingsScreen({super.key, this.onBack});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _notifications = true;
  bool _weatherAlerts = true;
  bool _marketUpdates = false;
  bool _darkMode = AppState.isDark;
  bool _locationServices = true;
  int _selectedLanguageIndex = AppState.langIndex;
  Map<String, dynamic>? _farmData;

  final List<String> _languages = AppState.languages;

  User? get user => UserSession.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchFarmData();
  }

  void _fetchFarmData() async {
    if (user != null) {
      final res = await ApiService.getFarmDetails(user!.id);
      if (res['success'] == true && mounted) {
        setState(() {
          _farmData = res['data'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(child: _buildProfileCard()),
          SliverToBoxAdapter(child: _buildFarmStats()),
          SliverToBoxAdapter(child: _buildSectionHeader('Account')),
          SliverToBoxAdapter(child: _buildAccountSection()),
          SliverToBoxAdapter(child: _buildSectionHeader('Notifications')),
          SliverToBoxAdapter(child: _buildNotificationsSection()),
          SliverToBoxAdapter(child: _buildSectionHeader('Preferences')),
          SliverToBoxAdapter(child: _buildPreferencesSection()),
          SliverToBoxAdapter(child: _buildLogoutButton()),
          SliverToBoxAdapter(child: _buildAppVersion()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── SLIVER HEADER ──
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 60,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: const Color(0xFF1B4332),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        'Profile & Settings'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PersonalInformationScreen()),
            );
            if (updated == true) {
              setState(() {});
            }
          },
          child: Text(
            'Edit'.tr,
            style: const TextStyle(
              color: Color(0xFF95D5B2),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  // ── PROFILE CARD ──
  Widget _buildProfileCard() {
    final crops = _farmData != null ? _farmData!['primary_crops'] : null;
    return Container(
      color: const Color(0xFF1B4332),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                      ),
                      border: Border.all(
                          color: const Color(0xFF95D5B2), width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        user != null && user!.name.isNotEmpty
                            ? user!.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                            : 'F',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B788),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF1B4332), width: 2),
                      ),
                      child: Icon(Icons.check,
                          color: Colors.white, size: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Farmer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            color: Color(0xFF95D5B2), size: 13),
                        const SizedBox(width: 3),
                        Text(
                          user?.state ?? 'No State Provided',
                          style: TextStyle(
                            color: Color(0xFF95D5B2),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B788).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        crops != null && crops.toString().isNotEmpty
                            ? '🌾 ' + crops.toString().tr + ' ' + 'Farmer'.tr
                            : '🌾 ' + 'Smart Farmer'.tr,
                        style: const TextStyle(
                          color: Color(0xFF95D5B2),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ── FARM STATS ──
  Widget _buildFarmStats() {
    final landArea = _farmData != null ? _farmData!['land_area']?.toString() : '12.5';
    return Container(
      color: const Color(0xFF1B4332),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Row(
          children: [
            _statTile('🌾', landArea ?? '12.5', 'Acres'.tr),
            _statDivider(),
            _statTile('📅', '8', 'Seasons'.tr),
            _statDivider(),
            _statTile('📊', '94%', 'Avg Yield'.tr),
            _statDivider(),
            _statTile('⭐', '4.8', 'Rating'.tr),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String emoji, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 36,
      color: const Color(0xFFDDE5DB),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: items
              .asMap()
              .entries
              .map((e) => Column(
            children: [
              e.value,
              if (e.key < items.length - 1)
                Divider(
                  height: 1,
                  indent: 58,
                  endIndent: 0,
                  color: Colors.grey.shade100,
                ),
            ],
          ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return _buildSettingsGroup([
      _buildSettingsTile(
        icon: Icons.person_outline_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2D6A4F),
        title: 'Personal Information'.tr,
        subtitle: 'Name, phone, state'.tr,
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PersonalInformationScreen()),
          );
          if (updated == true) {
            setState(() {});
          }
        },
      ),
      _buildSettingsTile(
        icon: Icons.agriculture_rounded,
        iconBg: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFE07B39),
        title: 'Farm Details'.tr,
        subtitle: 'Land, crop types, region'.tr,
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FarmDetailsScreen()),
          );
          if (updated == true) {
            _fetchFarmData();
          }
        },
      ),
    ]);
  }

  Widget _buildNotificationsSection() {
    return _buildSettingsGroup([
      _buildToggleTile(
        icon: Icons.notifications_none_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2D6A4F),
        title: 'Push Notifications'.tr,
        subtitle: 'Receive app alerts'.tr,
        value: _notifications,
        onChanged: (v) => setState(() => _notifications = v),
      ),
      _buildToggleTile(
        icon: Icons.cloud_outlined,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1976D2),
        title: 'Weather Alerts'.tr,
        value: _weatherAlerts,
        onChanged: (v) => setState(() => _weatherAlerts = v),
      ),
      _buildToggleTile(
        icon: Icons.trending_up_rounded,
        iconBg: const Color(0xFFFFF8E1),
        iconColor: const Color(0xFFE07B39),
        title: 'Market Updates'.tr,
        value: _marketUpdates,
        onChanged: (v) => setState(() => _marketUpdates = v),
      ),
    ]);
  }

  Widget _buildPreferencesSection() {
    return _buildSettingsGroup([
      _buildLanguageTile(),
      _buildToggleTile(
        icon: Icons.dark_mode_outlined,
        iconBg: const Color(0xFFECEFF1),
        iconColor: const Color(0xFF37474F),
        title: AppState.translate('dark_mode'),
        value: _darkMode,
        onChanged: (v) {
          setState(() => _darkMode = v);
          AppState.toggleDarkMode(v);
        },
      ),
      _buildToggleTile(
        icon: Icons.location_on_outlined,
        iconBg: const Color(0xFFFFEBEE),
        iconColor: const Color(0xFFC62828),
        title: 'Location Services'.tr,
        value: _locationServices,
        onChanged: (v) => setState(() => _locationServices = v),
      ),
    ]);
  }


  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2E1A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) ...[
            Text(
              trailing,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2E1A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
      )
          : null,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: const Color(0xFF2D6A4F),
      ),
    );
  }

  Widget _buildLanguageTile() {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.translate_rounded,
            color: Color(0xFF00897B), size: 20),
      ),
      title: Text(
        AppState.translate('language'),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A2E1A),
        ),
      ),
      trailing: GestureDetector(
        onTap: () => _showLanguageSheet(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _languages[_selectedLanguageIndex],
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF2D6A4F),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF2D6A4F)),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Language'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: _languages.asMap().entries.map((e) {
                    final selected = _selectedLanguageIndex == e.key;
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedLanguageIndex = e.key);
                        AppState.setLanguage(e.key);
                        Navigator.pop(ctx);
                      },
                      title: Text(
                        e.value,
                        style: TextStyle(
                          fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF2D6A4F)
                              : const Color(0xFF1A2E1A),
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_circle_rounded,
                          color: Color(0xFF2D6A4F))
                          : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCDD2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFE53935), size: 20),
              SizedBox(width: 10),
              Text(
                'Log Out'.tr,
                style: const TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Log Out?'.tr,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'You will need to sign in again to access your farm data.'.tr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel'.tr,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (user != null) {
                await ApiService.logout(user!.email);
              }
              // Clear local cached session so offline login is invalidated
              await LocalStorage.clearSession();
              UserSession.currentUser = null;
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Log Out'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersion() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Center(
        child: Column(
          children: [
            Text(
              '🌿 Agrosmart',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF52796F),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Version 2.4.1 · Build 241'.tr,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// RELEVANT DETAIL SCREENS (STATEFUL & DYNAMIC)
// ─────────────────────────────────────────

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _stateCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = UserSession.currentUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _stateCtrl = TextEditingController(text: user?.state ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final user = UserSession.currentUser;
    if (user == null) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final res = await ApiService.updateProfile(
        userId: user.id,
        name: _nameCtrl.text,
        phone: _phoneCtrl.text,
        state: _stateCtrl.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'.tr),
              backgroundColor: const Color(0xFF2D6A4F),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((res['error'] ?? 'Failed to update profile').toString().tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Information'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildInfoField('Full Name'.tr, _nameCtrl),
            _buildInfoField('Phone Number'.tr, _phoneCtrl),
            _buildInfoField('State'.tr, _stateCtrl),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email Address'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      filled: true,
                      fillColor: Color(0xFFEEEEEE),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Update Information'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            validator: (v) => v!.isEmpty ? 'This field is required'.tr : null,
          ),
        ],
      ),
    );
  }
}

class FarmDetailsScreen extends StatefulWidget {
  const FarmDetailsScreen({super.key});

  @override
  State<FarmDetailsScreen> createState() => _FarmDetailsScreenState();
}

class _FarmDetailsScreenState extends State<FarmDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final _landCtrl = TextEditingController();
  final _cropsCtrl = TextEditingController();
  final _soilCtrl = TextEditingController();
  final _irrigationCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFarmDetails();
  }

  @override
  void dispose() {
    _landCtrl.dispose();
    _cropsCtrl.dispose();
    _soilCtrl.dispose();
    _irrigationCtrl.dispose();
    _regionCtrl.dispose();
    super.dispose();
  }

  void _loadFarmDetails() async {
    final user = UserSession.currentUser;
    if (user == null) return;
    final res = await ApiService.getFarmDetails(user.id);
    if (res['success'] == true && mounted) {
      final data = res['data'];
      _landCtrl.text = data['land_area']?.toString() ?? '';
      _cropsCtrl.text = data['primary_crops'] ?? '';
      _soilCtrl.text = data['soil_type'] ?? '';
      _irrigationCtrl.text = data['irrigation'] ?? '';
      _regionCtrl.text = data['region'] ?? '';
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _saveFarmDetails() async {
    final user = UserSession.currentUser;
    if (user == null) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final double? area = double.tryParse(_landCtrl.text);
      final res = await ApiService.updateFarmDetails(
        userId: user.id,
        landArea: area,
        primaryCrops: _cropsCtrl.text,
        soilType: _soilCtrl.text,
        irrigation: _irrigationCtrl.text,
        region: _regionCtrl.text,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Farm details saved successfully!'.tr),
              backgroundColor: const Color(0xFF2D6A4F),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text((res['error'] ?? 'Failed to update farm details').toString().tr),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farm Details'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildField('Total Land Area (Acres)'.tr, _landCtrl, isNumeric: true),
            _buildField('Primary Crops (e.g. Wheat, Paddy)'.tr, _cropsCtrl),
            _buildField('Soil Type (e.g. Clayey, Loamy)'.tr, _soilCtrl),
            _buildField('Irrigation Source (e.g. Tube Well)'.tr, _irrigationCtrl),
            _buildField('Region'.tr, _regionCtrl),
            const SizedBox(height: 30),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _saveFarmDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save Farm Details'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map_outlined),
              label: Text('View Farm Map'.tr),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2D6A4F),
                side: const BorderSide(color: Color(0xFF2D6A4F)),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            validator: (v) => v!.isEmpty ? 'This field is required'.tr : null,
          ),
        ],
      ),
    );
  }
}

class BankPaymentsScreen extends StatelessWidget {
  const BankPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bank & Payments'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Linked Bank Account'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.account_balance, color: Colors.blue),
            title: Text('State Bank of India'.tr),
            subtitle: const Text('XXXX XXXX 4290'),
            trailing: Text('Primary'.tr, style: const TextStyle(color: Colors.green)),
          ),
          const Divider(),
          const SizedBox(height: 20),
          Text('Recent Payouts'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          _buildTransaction('Crop Sale - Wheat'.tr, '₹42,500', '12 Aug 2025'.tr),
          _buildTransaction('Govt Subsidy'.tr, '₹5,000', '05 Aug 2025'.tr),
        ],
      ),
    );
  }

  Widget _buildTransaction(String title, String amount, String date) {
    return ListTile(
      title: Text(title.tr),
      subtitle: Text(date.tr),
      trailing: Text(amount.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _twoFactor = true;
  bool _faceId = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.password),
            title: Text('Change Login Password'.tr),
            trailing: const Icon(Icons.chevron_right),
          ),
          SwitchListTile(
            title: Text('Two-Factor Authentication'.tr),
            subtitle: Text('Secure your account with SMS codes'.tr),
            value: _twoFactor,
            onChanged: (v) => setState(() => _twoFactor = v),
          ),
          SwitchListTile(
            title: Text('Biometric Login'.tr),
            subtitle: Text('Use Face ID or Fingerprint'.tr),
            value: _faceId,
            onChanged: (v) => setState(() => _faceId = v),
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: Text('Trusted Devices'.tr),
            subtitle: Text('2 devices active'.tr),
            trailing: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class UnitsMeasurementsScreen extends StatelessWidget {
  const UnitsMeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Units & Measurements'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildUnitTile('Land Area'.tr, 'Acres'.tr, ['Acres'.tr, 'Hectares'.tr, 'Bigha'.tr]),
          _buildUnitTile('Weight'.tr, 'Quintals'.tr, ['Quintals'.tr, 'KG'.tr, 'Tonnes'.tr]),
          _buildUnitTile('Temperature'.tr, 'Celsius (°C)'.tr, ['Celsius (°C)'.tr, 'Fahrenheit (°F)'.tr]),
        ],
      ),
    );
  }

  Widget _buildUnitTile(String title, String current, List<String> options) {
    return ListTile(
      title: Text(title.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Current'.tr + ': ' + current.tr),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show selection dialog
      },
    );
  }
}

class HelpFAQScreen extends StatelessWidget {
  const HelpFAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help & FAQ'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FAQItem('How to check market prices?'.tr, 'Go to the Market tab from the bottom navigation bar to see live prices.'.tr),
          _FAQItem('How to update farm details?'.tr, 'In Profile > Account > Farm Details, you can edit your land information.'.tr),
          _FAQItem('Is Agrosmart free?'.tr, 'Agrosmart offers a free version and a Pro version with premium features.'.tr),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question, answer;
  const _FAQItem(this.question, this.answer);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(question.tr, style: const TextStyle(fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(answer.tr),
        ),
      ],
    );
  }
}

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Support'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic_rounded, size: 80, color: const Color(0xFF2D6A4F)),
            const SizedBox(height: 24),
            Text('How can we help you?'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            _buildContactButton(Icons.chat_rounded, 'Chat with an Expert'.tr),
            _buildContactButton(Icons.call_rounded, 'Call Support (Toll-Free)'.tr),
            _buildContactButton(Icons.email_rounded, 'Email us'.tr),
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(label.tr),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D6A4F),
          side: const BorderSide(color: Color(0xFF2D6A4F)),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'.tr),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          ('Your privacy is important to us. Agrosmart collects data only to improve your farming experience. '
          'We do not sell your personal information to third parties...\n\n'
          '1. Data Collection\nWe collect location data for hyper-local weather reports.\n\n'
          '2. Data Usage\nFarm data helps us provide accurate crop advisories.\n\n'
          '3. Security\nWe use industry-standard encryption to protect your account.').tr,
          style: const TextStyle(fontSize: 14, height: 1.6),
        ),
      ),
    );
  }
}
