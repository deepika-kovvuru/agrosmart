// pest_disease_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'app_theme.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'translation_provider.dart';

class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() => _PestDiseaseScreenState();
}

class _PestDiseaseScreenState extends State<PestDiseaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingAlerts = true;
  bool _isLoadingTreatments = true;

  List<_PestAlert> _activeIssues = [];
  List<_Treatment> _treatments = [];

  XFile? _imageFile;
  bool _isIdentifying = false;
  Map<String, dynamic>? _diagnosisResult;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
          _isIdentifying = true;
          _diagnosisResult = null;
        });

        // Simulate AI analysis delay
        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _isIdentifying = false;
          
          final hash = pickedFile.path.hashCode.abs();
          final choice = hash % 4;
          
          if (choice == 0) {
            _diagnosisResult = {
              'pest_name': 'Fall Armyworm'.tr,
              'confidence': '${85 + (hash % 11)}%',
              'description': 'The Fall Armyworm (Spodoptera frugiperda) is an insect pest that feeds on maize, rice, sorghum, sugarcane, and other crops. It causes severe damage to leaves and cobs.'.tr,
              'treatment': 'Spray Chlorpyrifos 20% EC at 2ml/L of water. Alternatively, apply Neem oil (1500 ppm) at 5ml/L for organic prevention.'.tr,
              'severity': 'High'.tr,
              'severityColor': const Color(0xFFE63946),
            };
          } else if (choice == 1) {
            _diagnosisResult = {
              'pest_name': 'Bacterial Leaf Blight'.tr,
              'confidence': '${88 + (hash % 8)}%',
              'description': 'Bacterial Leaf Blight (caused by Xanthomonas oryzae) produces linear yellowing and drying of leaves starting from the tips, common in warm, humid weather.'.tr,
              'treatment': 'Spray Streptocycline @ 0.1g/L combined with Copper Oxychloride @ 2g/L. Keep water levels low in the field for 3 days.'.tr,
              'severity': 'High'.tr,
              'severityColor': const Color(0xFFE63946),
            };
          } else if (choice == 2) {
            _diagnosisResult = {
              'pest_name': 'Whitefly Infestation'.tr,
              'confidence': '${90 + (hash % 7)}%',
              'description': 'Whiteflies suck sap from the undersides of leaves, causing leaf curling, yellowing, and secreting honeydew which attracts sooty mold.'.tr,
              'treatment': 'Spray Acetamiprid 20% SP @ 0.2g/L or use yellow sticky traps (10 per acre). Avoid excessive nitrogen fertilizers.'.tr,
              'severity': 'Medium'.tr,
              'severityColor': const Color(0xFFFFB703),
            };
          } else {
            _diagnosisResult = {
              'pest_name': 'Early Blight'.tr,
              'confidence': '${86 + (hash % 10)}%',
              'description': 'Early Blight (caused by Alternaria solani) shows as brown concentric rings ("target board" pattern) on older leaves first, leading to defoliation.'.tr,
              'treatment': 'Spray Chlorothalonil 75% WP @ 2g/L or Mancozeb @ 2.5g/L. Water at the base of the plant to prevent leaf splash.'.tr,
              'severity': 'Medium'.tr,
              'severityColor': const Color(0xFFFFB703),
            };
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to access camera or gallery.'.tr),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageFile = null;
      _isIdentifying = false;
      _diagnosisResult = null;
    });
  }

  User? get user => UserSession.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    _loadPestAlerts();
    _loadTreatments();
  }

  void _loadPestAlerts() async {
    setState(() => _isLoadingAlerts = true);
    // Fetch live pest alerts (optionally filtered by user's state/region)
    final res = await ApiService.getPestAlerts(region: user?.state);
    if (mounted) {
      setState(() {
        if (res.isNotEmpty) {
          _activeIssues = res.map((a) {
            String p = a['severity']?.toString() ?? 'Medium';
            Color pc = const Color(0xFFF4A261);
            if (p == 'High') pc = const Color(0xFFE63946);
            if (p == 'Low') pc = const Color(0xFF2D6A4F);
            
            String name = a['pest_name'] ?? 'Pest Alert';
            String emoji = '🐛';
            if (name.toLowerCase().contains('hopper')) emoji = '🦗';
            if (name.toLowerCase().contains('blast') || name.toLowerCase().contains('rot')) emoji = '🍄';

            return _PestAlert(
              name,
              a['crop'] ?? 'Maize',
              'Crop Alert',
              a['description'] ?? '',
              p,
              pc,
              emoji,
              a['reported_at'] ?? 'Today',
            );
          }).toList();
        } else {
          // fallback mock issues
          _activeIssues = const [
            _PestAlert('Fall Armyworm', 'FAW', 'Insect Pest', 'Your district has an active outbreak. 15+ farmers reported damage.', 'High', Color(0xFFE63946), '🪱', '2h ago'),
            _PestAlert('Rice Blast', 'Rice Blast', 'Fungal Disease', 'Humid conditions favor rice blast. Check leaf nodes for gray lesions.', 'Medium', Color(0xFFF4A261), '🍄', '1d ago'),
            _PestAlert('Brown Plant Hopper', 'BPH', 'Insect Pest', 'Hopperburn symptoms noticed nearby. Monitor crop base carefully.', 'Low', Color(0xFF2D6A4F), '🦗', '3d ago'),
          ];
        }
        _isLoadingAlerts = false;
      });
    }
  }

  void _loadTreatments() async {
    setState(() => _isLoadingTreatments = true);
    final res = await ApiService.getTreatments();
    if (mounted) {
      setState(() {
        if (res.isNotEmpty) {
          _treatments = res.map((t) {
            String type = t['type'] ?? 'Chemical';
            Color color = const Color(0xFFE63946);
            if (type.toLowerCase().contains('fungi')) {
              color = const Color(0xFF9B59B6);
            } else if (type.toLowerCase().contains('bio') || type.toLowerCase().contains('organic')) {
              color = const Color(0xFF2D6A4F);
            }

            return _Treatment(
              t['name'] ?? 'Treatment',
              t['description'] ?? '',
              type,
              color,
            );
          }).toList();
        } else {
          // fallback mock treatments
          _treatments = const [
            _Treatment('Chlorpyrifos 20 EC', 'Spray 2ml/L water for FAW control. Apply during evening.', 'Chemical', Color(0xFFE63946)),
            _Treatment('Tricyclazole 75 WP', 'Use 0.6g/L water for blast control. 2 sprays 15 days apart.', 'Fungicide', Color(0xFF9B59B6)),
            _Treatment('Neem Oil Spray', 'Eco-friendly option: 5ml/L water, spray weekly for BPH.', 'Bio-Pesticide', Color(0xFF2D6A4F)),
          ];
        }
        _isLoadingTreatments = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(context),
          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.error,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.error,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Active Alerts'.tr),
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_activeIssues.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(text: 'Treatments'.tr),
                Tab(text: 'Identify'.tr),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlertsTab(),
                _buildTreatmentsTab(),
                _buildIdentifyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7B0000), Color(0xFFB71C1C), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'Pest & Disease'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_activeIssues.length} ' + 'Alerts'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Risk level card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'District Risk Level'.tr + ': ' + (_activeIssues.any((element) => element.priority == "High") ? "HIGH".tr : "MEDIUM".tr),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '${user?.state ?? "Kurnool"} ' + 'district · As of today'.tr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'View Map'.tr,
                    style: const TextStyle(
                      color: Color(0xFFB71C1C),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab() {
    return _isLoadingAlerts
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadPestAlerts();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Text('🛡️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prevention Strategy'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              'Field scouting recommended twice a week during this period.'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Active Issues in Your Area'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                ..._activeIssues.map((p) => _PestAlertCard(item: p)),
              ],
            ),
          );
  }

  Widget _buildTreatmentsTab() {
    return _isLoadingTreatments
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadTreatments();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Organic / Chemical toggle (UI placeholder)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'All Treatments'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._treatments.map((t) => _TreatmentCard(treatment: t)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Always wear protective gear when handling pesticides. Follow label instructions.'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Poppins',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildIdentifyTab() {
    if (_imageFile == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Take a Photo'.tr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Capture the affected leaf, stem, or pest\nfor instant AI identification'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      fontFamily: 'Poppins',
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Open Camera'.tr,
              icon: Icons.camera_alt_rounded,
              onTap: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Upload from Gallery'.tr,
              isOutlined: true,
              icon: Icons.photo_library_rounded,
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or search manually'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search pest or disease name...'.tr,
                  prefixIcon:
                  const Icon(Icons.search_rounded, color: AppTheme.primary, size: 20),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Image Preview Container
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 220,
              width: double.infinity,
              color: Colors.black12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  kIsWeb
                      ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                      : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                  if (_isIdentifying)
                    Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI is analyzing image...'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Diagnostic result card
          if (!_isIdentifying && _diagnosisResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.psychology_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'AI Diagnosis Result'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _diagnosisResult!['severityColor'].withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _diagnosisResult!['severity'],
                          style: TextStyle(
                            color: _diagnosisResult!['severityColor'],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Text(
                        _diagnosisResult!['pest_name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${_diagnosisResult!['confidence']})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _diagnosisResult!['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.healing_rounded, color: Color(0xFF2E7D32), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Recommended Treatment'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _diagnosisResult!['treatment'],
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF1B5E20),
                            height: 1.5,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Scan Another Photo'.tr,
              isOutlined: true,
              icon: Icons.refresh_rounded,
              onTap: _clearImage,
            ),
          ],
        ],
      ),
    );
  }
}

class _PestAlertCard extends StatelessWidget {
  final _PestAlert item;
  const _PestAlertCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(item.emoji, style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name.tr,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: item.priorityColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.priority.tr,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.priorityColor,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.category.tr,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      item.time.tr,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: item.priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'View Treatment'.tr + ' →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.priorityColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  final _Treatment treatment;
  const _TreatmentCard({required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: treatment.color, width: 3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  treatment.name.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: treatment.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  treatment.type.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: treatment.color,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            treatment.description.tr,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _PestAlert {
  final String name, code, category, description, priority, emoji, time;
  final Color priorityColor;
  const _PestAlert(this.name, this.code, this.category, this.description,
      this.priority, this.priorityColor, this.emoji, this.time);
}

class _Treatment {
  final String name, description, type;
  final Color color;
  const _Treatment(this.name, this.description, this.type, this.color);
}
