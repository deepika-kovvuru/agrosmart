import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'offline_api_service.dart';
import 'translation_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _agreed = true;
  bool _isLoading = false;
  String _selectedState = 'Andhra Pradesh';
  String _selectedDistrict = 'Kurnool';

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  final List<String> _states = [
    'Andhra Pradesh',
    'Telangana',
    'Tamil Nadu',
    'Karnataka',
    'Maharashtra',
    'Punjab',
    'Haryana',
    'Rajasthan',
    'Gujarat',
    'Kerala',
    'Uttar Pradesh',
    'Madhya Pradesh',
    'Bihar',
    'West Bengal',
    'Odisha',
    'Assam',
    'Chhattisgarh',
    'Jharkhand',
  ];

  final Map<String, List<String>> _districtsByState = {
    'Andhra Pradesh': [
      'Kurnool', 'Guntur', 'Krishna', 'Anantapur', 'Visakhapatnam', 
      'Chittoor', 'Kadapa', 'Nellore', 'Tirupati', 'Prakasam', 
      'Vizianagaram', 'Srikakulam', 'East Godavari', 'West Godavari', 'Eluru', 'Nandyal'
    ],
    'Telangana': [
      'Hyderabad', 'Warangal', 'Nalgonda', 'Nizamabad', 'Karimnagar', 
      'Khammam', 'Mahabubnagar', 'Medak', 'Adilabad', 'Rangareddy', 'Suryapet'
    ],
    'Tamil Nadu': [
      'Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Thanjavur', 
      'Kanchipuram', 'Tiruchirappalli', 'Erode', 'Vellore', 'Tirunelveli'
    ],
    'Karnataka': [
      'Bengaluru Rural', 'Mandya', 'Belagavi', 'Dharwad', 'Mysuru', 
      'Hassan', 'Tumakuru', 'Shivamogga', 'Kalaburagi', 'Ballari'
    ],
    'Maharashtra': [
      'Pune', 'Nashik', 'Nagpur', 'Ahmednagar', 'Solapur', 
      'Kolhapur', 'Satara', 'Aurangabad', 'Amravati', 'Latur'
    ],
    'Punjab': [
      'Ludhiana', 'Amritsar', 'Bhatinda', 'Jalandhar', 'Patiala', 'Sangrur'
    ],
    'Haryana': [
      'Karnal', 'Hisar', 'Gurugram', 'Ambala', 'Rohtak', 'Sonipat'
    ],
    'Rajasthan': [
      'Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer', 'Bikaner', 'Ganganagar'
    ],
    'Gujarat': [
      'Rajkot', 'Anand', 'Surat', 'Ahmedabad', 'Vadodara', 'Junagadh', 'Mehsana'
    ],
    'Kerala': [
      'Palakkad', 'Wayanad', 'Idukki', 'Kottayam', 'Thrissur', 'Alappuzha'
    ],
    'Uttar Pradesh': [
      'Varanasi', 'Lucknow', 'Kanpur', 'Agra', 'Prayagraj', 'Gorakhpur', 'Meerut'
    ],
    'Madhya Pradesh': [
      'Indore', 'Bhopal', 'Ujjain', 'Gwalior', 'Jabalpur', 'Hoshangabad'
    ],
    'Bihar': [
      'Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga', 'Rohtas'
    ],
    'West Bengal': [
      'Kolkata', 'Burdwan', 'Hooghly', 'Nadia', 'Murshidabad', 'North 24 Parganas'
    ],
    'Odisha': [
      'Bhubaneswar', 'Cuttack', 'Ganjam', 'Balasore', 'Sambalpur', 'Bargarh'
    ],
  };

  List<String> _getDistrictsForState(String state) {
    return _districtsByState[state] ?? ['Default District'];
  }

  @override
  void initState() {
    super.initState();
    _selectedDistrict = _getDistrictsForState(_selectedState).first;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isLoading = true);

    final result = await OfflineApiService.signup(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passCtrl.text,
      confirmPassword: _confirmCtrl.text,
      state: _selectedState,
      district: _selectedDistrict,
    );

    if (mounted) {
      if (result['success'] == true) {
        final loginResult = await OfflineApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
        if (mounted) {
          setState(() => _isLoading = false);
          if (loginResult['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration and login successful!'.tr),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Account created! Please sign in.'.tr),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pushReplacementNamed(context, '/login');
          }
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['error'] ?? 'Registration failed').toString().tr),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 20, 24, 28),
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Create Account'.tr,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Join thousands of smart farmers today'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _buildLabel('Full Name'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _nameCtrl,
                          hint: 'Ravi Kumar',
                          prefix: Icons.person_rounded,
                          validator: (v) =>
                          v!.isEmpty ? 'Name is required'.tr : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Mobile Number'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _phoneCtrl,
                          hint: '+91 9876543210',
                          prefix: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                          v!.length < 10 ? 'Enter valid number'.tr : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Email Address'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _emailCtrl,
                          hint: 'ravi@example.com',
                          prefix: Icons.email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => !v!.contains('@')
                              ? 'Enter valid email'.tr
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('State'),
                        const SizedBox(height: 8),
                        _buildStateDropdown(),
                        const SizedBox(height: 16),
                        _buildLabel('District'),
                        const SizedBox(height: 8),
                        _buildDistrictDropdown(),
                        const SizedBox(height: 16),
                        _buildLabel('Password'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _passCtrl,
                          hint: 'Min. 8 characters',
                          prefix: Icons.lock_rounded,
                          isPassword: true,
                          passwordVisible: _passwordVisible,
                          onTogglePassword: () => setState(
                                  () => _passwordVisible = !_passwordVisible),
                          validator: (v) =>
                          v!.length < 8 ? 'Min 8 characters'.tr : null,
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Confirm Password'),
                        const SizedBox(height: 8),
                        _buildField(
                          controller: _confirmCtrl,
                          hint: 'Re-enter password',
                          prefix: Icons.lock_outline_rounded,
                          isPassword: true,
                          passwordVisible: _confirmVisible,
                          onTogglePassword: () => setState(
                                  () => _confirmVisible = !_confirmVisible),
                          validator: (v) => v != _passCtrl.text
                              ? 'Passwords do not match'.tr
                              : null,
                        ),

                        const SizedBox(height: 20),

                        const SizedBox(height: 10),

                         AppButton(
                          label: 'Create Account'.tr,
                          isLoading: _isLoading,
                          onTap: _register,
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?  '.tr,
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'Poppins',
                                  fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushReplacementNamed(context, '/login'),
                              child: Text(
                                'Sign In'.tr,
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.tr,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData prefix,
    bool isPassword = false,
    bool? passwordVisible,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !(passwordVisible ?? false),
      keyboardType: keyboardType,
      validator: validator,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
      decoration: InputDecoration(
        hintText: hint.tr,
        prefixIcon: Icon(prefix, color: AppTheme.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (passwordVisible ?? false)
                ? Icons.visibility_rounded
                : Icons.visibility_off_rounded,
            color: AppTheme.textLight,
            size: 20,
          ),
          onPressed: onTogglePassword,
        )
            : null,
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _states.contains(_selectedState) ? _selectedState : _states.first,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          items: _states
              .map((s) => DropdownMenuItem(value: s, child: Text(s.tr)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedState = v;
                final dists = _getDistrictsForState(v);
                _selectedDistrict = dists.first;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    final districts = _getDistrictsForState(_selectedState);
    final currentDist = districts.contains(_selectedDistrict) ? _selectedDistrict : districts.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentDist,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
          items: districts
              .map((d) => DropdownMenuItem(value: d, child: Text(d.tr)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedDistrict = v);
            }
          },
        ),
      ),
    );
  }
}
