// pest_disease_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:universal_html/html.dart' as html;
import 'app_theme.dart';
import 'api_service.dart';
import 'offline_api_service.dart';
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

  String _currentLocationName = "Kurnool, Andhra Pradesh";
  List<_PestAlert> _activeIssues = [];
  List<_Treatment> _treatments = [];

  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isIdentifying = false;
  Map<String, dynamic>? _diagnosisResult;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      XFile? pickedFile;
      try {
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 85,
        );
      } catch (pickErr) {
        pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 85,
        );
      }

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
          _isIdentifying = true;
          _diagnosisResult = null;
        });

        final result = await OfflineApiService.analyzeImageBytes(bytes, pickedFile.name);

        if (mounted) {
          setState(() {
            _isIdentifying = false;
            if (result['success'] == true) {
              _diagnosisResult = result;
            } else {
              _diagnosisResult = {
                'is_agricultural': false,
                'category': 'unknown',
                'confidence': 0.0,
                'message': result['message'] ?? 'Image analysis failed.'.tr,
              };
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        setState(() {
          _isIdentifying = false;
        });
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
      _imageBytes = null;
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
    _loadLiveGPSLocationForPests();
    _loadTreatments();
  }

  Future<void> _loadLiveGPSLocationForPests() async {
    setState(() => _isLoadingAlerts = true);
    try {
      if (html.window.navigator.geolocation != null) {
        final pos = await html.window.navigator.geolocation.getCurrentPosition(
          enableHighAccuracy: true,
          timeout: const Duration(seconds: 10),
        );
        final double lat = pos.coords?.latitude?.toDouble() ?? 15.8281;
        final double lon = pos.coords?.longitude?.toDouble() ?? 78.0373;
        final resData = await ApiService.getCombinedAlerts(latitude: lat, longitude: lon);
        final pestList = resData['pest_alerts'] ?? [];
        final loc = resData['location'];
        if (mounted) {
          setState(() {
            if (loc != null && loc['display_name'] != null) {
              _currentLocationName = loc['display_name'];
            }
            if (pestList is List && pestList.isNotEmpty) {
              _activeIssues = pestList.map((a) {
                String level = a['risk_level']?.toString() ?? 'HIGH';
                Color pc = const Color(0xFFF4A261);
                if (level == 'CRITICAL' || level == 'VERY HIGH') pc = const Color(0xFFE63946);
                if (level == 'HIGH') pc = const Color(0xFFF4A261);
                if (level == 'MODERATE') pc = const Color(0xFF0284C7);
                if (level == 'LOW') pc = const Color(0xFF2D6A4F);
                
                String name = "${a['name']} (${a['risk_score']}%)";
                String emoji = '🐛';
                if (name.toLowerCase().contains('hopper')) emoji = '🦗';
                if (name.toLowerCase().contains('blast') || name.toLowerCase().contains('rot')) emoji = '🍄';

                String desc = "${a['reason']}\n\n💡 Action: ${a['recommended_action']}";

                return _PestAlert(
                  name,
                  a['crop'] ?? 'Rice',
                  level,
                  desc,
                  level,
                  pc,
                  emoji,
                  'Updated just now',
                );
              }).toList();
            }
            _isLoadingAlerts = false;
          });
        }
      } else {
        _loadPestAlerts();
      }
    } catch (e) {
      print("GPS load error in pests: $e");
      _loadPestAlerts();
    }
  }

  void _loadPestAlerts() async {
    setState(() => _isLoadingAlerts = true);
    final resData = await ApiService.getCombinedAlerts(latitude: 15.8281, longitude: 78.0373);
    final pestList = resData['pest_alerts'] ?? [];
    final loc = resData['location'];
    if (mounted) {
      setState(() {
        if (loc != null && loc['display_name'] != null) {
          _currentLocationName = loc['display_name'];
        }
        if (pestList is List && pestList.isNotEmpty) {
          _activeIssues = pestList.map((a) {
            String level = a['risk_level']?.toString() ?? 'HIGH';
            Color pc = const Color(0xFFF4A261);
            if (level == 'CRITICAL' || level == 'VERY HIGH') pc = const Color(0xFFE63946);
            if (level == 'HIGH') pc = const Color(0xFFF4A261);
            if (level == 'MODERATE') pc = const Color(0xFF0284C7);
            if (level == 'LOW') pc = const Color(0xFF2D6A4F);
            
            String name = "${a['name']} (${a['risk_score']}%)";
            String emoji = '🐛';
            if (name.toLowerCase().contains('hopper')) emoji = '🦗';
            if (name.toLowerCase().contains('blast') || name.toLowerCase().contains('rot')) emoji = '🍄';

            String desc = "${a['reason']}\n\n💡 Action: ${a['recommended_action']}";

            return _PestAlert(
              name,
              a['crop'] ?? 'Rice',
              level,
              desc,
              level,
              pc,
              emoji,
              'Updated just now',
            );
          }).toList();
        } else {
          _activeIssues = const [
            _PestAlert('Brown Planthopper (82%)', 'Rice', 'CRITICAL', 'High humidity and optimal temperature in Kurnool district.\nAction: Spray Imidacloprid 17.8 SL @ 0.5 ml/L.', 'CRITICAL', Color(0xFFE63946), '🦗', 'Just now'),
            _PestAlert('Stem Borer (67%)', 'Rice', 'HIGH', 'Favorable weather for stem borer larvae activity.\nAction: Apply Chlorantraniliprole 0.4% GR @ 4 kg/acre.', 'HIGH', Color(0xFFF4A261), '🐛', 'Just now'),
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
        List<_Treatment> list = [];
        if (res.isNotEmpty) {
          list = res.map((t) {
            String type = t['type'] ?? 'Chemical';
            Color color = const Color(0xFFE63946);
            if (type.toLowerCase().contains('fungi')) {
              color = const Color(0xFF9B59B6);
            } else if (type.toLowerCase().contains('bio') || type.toLowerCase().contains('organic')) {
              color = const Color(0xFF2D6A4F);
            }

            String name = t['name'] ?? 'Treatment';
            String desc = t['description'] ?? '';
            
            bool isPriority = false;
            String? targetAlert;
            for (var issue in _activeIssues) {
              if (desc.toLowerCase().contains(issue.category.toLowerCase()) || 
                  issue.description.toLowerCase().contains(name.toLowerCase()) ||
                  name.toLowerCase().contains('neem') || name.toLowerCase().contains('chlorpyrifos') || name.toLowerCase().contains('imidacloprid')) {
                isPriority = true;
                targetAlert = issue.name;
                break;
              }
            }

            return _Treatment(
              name,
              desc,
              type,
              color,
              isPriorityForLocation: isPriority,
              targetAlert: targetAlert,
            );
          }).toList();
        } else {
          list = [
            _Treatment(
              'Imidacloprid 17.8 SL',
              'Apply 0.3ml/L water for sucking pests like whitefly, aphids and thrips in your location.',
              'Chemical',
              const Color(0xFFE63946),
              isPriorityForLocation: true,
              targetAlert: 'Chilli Thrips (92%)',
            ),
            _Treatment(
              'Chlorpyrifos 20 EC',
              'Spray 2ml/L water for FAW control during evening hours for your location.',
              'Chemical',
              const Color(0xFFE63946),
              isPriorityForLocation: true,
              targetAlert: 'Fall Armyworm (90%)',
            ),
            _Treatment(
              'Neem Oil Spray',
              'Eco-friendly 5ml/L water spray weekly for BPH & sucking pest prevention.',
              'Bio-Pesticide',
              const Color(0xFF2D6A4F),
              isPriorityForLocation: true,
              targetAlert: 'Pink Bollworm (88%)',
            ),
            const _Treatment('Trichoderma viride', 'Soil application 2.5kg/acre for root rot and damping off prevention.', 'Bio-Pesticide', Color(0xFF2D6A4F)),
            const _Treatment('Copper Oxychloride', '3g/L water for bacterial and fungal diseases. Spray at first sign.', 'Fungicide', Color(0xFF9B59B6)),
            const _Treatment('Tricyclazole 75 WP', 'Use 0.6g/L water for blast control. 2 sprays 15 days apart.', 'Fungicide', Color(0xFF9B59B6)),
          ];
        }

        list.sort((a, b) => (b.isPriorityForLocation ? 1 : 0).compareTo(a.isPriorityForLocation ? 1 : 0));
        _treatments = list;
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
                GestureDetector(
                  onTap: () => _showOutbreakMapDialog(context),
                  child: Container(
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
                ..._activeIssues.map((p) => _PestAlertCard(
                      item: p,
                      onViewTreatment: () => _showTreatmentDetailModal(context, p),
                    )),
              ],
            ),
          );
  }

  Widget _buildTreatmentsTab() {
    int priorityCount = _treatments.where((t) => t.isPriorityForLocation).length;
    return _isLoadingTreatments
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadTreatments();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF334155)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recommended Treatments for Active Alerts'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              '$priorityCount ' + 'treatments prioritized for active threat alerts in your location'.tr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 11,
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
                      const SizedBox(width: 10),
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
                  _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : (kIsWeb
                          ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                          : Image.file(File(_imageFile!.path), fit: BoxFit.cover)),
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
            if (_diagnosisResult!['is_agricultural'] == false)
              // Non-agricultural warning card (Face, Unknown, etc.)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F1), // soft light red
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFC1C5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFD90429), size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Non-Agricultural Image Detected'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFD90429),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _diagnosisResult!['message'] ?? 'Please upload a crop, leaf, fruit, pest, soil, or farm image.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2B2D42),
                        height: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Detected Category: ${_diagnosisResult!['category'].toString().toUpperCase()} (${(_diagnosisResult!['confidence'] * 100).round()}% confidence)'.tr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              )
            else
              // Context-Specific Agricultural Result Card
              Container(
                padding: const EdgeInsets.all(18),
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
                            color: (_diagnosisResult!['category'] == 'soil' || _diagnosisResult!['category'] == 'farm_field')
                                ? AppTheme.primary.withValues(alpha: 0.1)
                                : (_diagnosisResult!['analysis']['severity'] == 'High' ? const Color(0xFFE63946).withValues(alpha: 0.1) : const Color(0xFFFFB703).withValues(alpha: 0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ((_diagnosisResult!['category'] == 'soil' || _diagnosisResult!['category'] == 'farm_field')
                                ? 'Healthy'.tr
                                : _diagnosisResult!['analysis']['severity']).tr,
                            style: TextStyle(
                              color: (_diagnosisResult!['category'] == 'soil' || _diagnosisResult!['category'] == 'farm_field')
                                  ? AppTheme.primary
                                  : (_diagnosisResult!['analysis']['severity'] == 'High' ? const Color(0xFFE63946) : const Color(0xFFFFB703)),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Render details according to category
                    if (_diagnosisResult!['category'] == 'crop_leaf') ...[
                      Row(
                        children: [
                          Text(
                            _diagnosisResult!['analysis']['condition'].toString().tr,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${(_diagnosisResult!['confidence'] * 100).round()}%)',
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
                        'Crop: ${cropToFriendly(_diagnosisResult!['crop'])}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Visible Symptoms:'.tr,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, fontFamily: 'Poppins'),
                      ),
                      ...(_diagnosisResult!['analysis']['symptoms'] as List<dynamic>).map((sym) => Padding(
                        padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, size: 6, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(sym.toString().tr, style: const TextStyle(fontSize: 12, fontFamily: 'Poppins')),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      _buildTreatmentBox(_diagnosisResult!['analysis']['recommendation']),
                    ]
                    else if (_diagnosisResult!['category'] == 'pest_insect') ...[
                      Row(
                        children: [
                          Text(
                            _diagnosisResult!['analysis']['pest_name'].toString().tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${(_diagnosisResult!['confidence'] * 100).round()}%)',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Affected Crops: ${_diagnosisResult!['analysis']['affected_crops']}'.tr,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Characteristics: ${_diagnosisResult!['analysis']['characteristics']}'.tr,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 16),
                      _buildTreatmentBox(_diagnosisResult!['analysis']['recommendation']),
                    ]
                    else if (_diagnosisResult!['category'] == 'soil') ...[
                      Text(
                        'Soil Classification: ${_diagnosisResult!['analysis']['soil_type']}'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Estimated Condition: ${_diagnosisResult!['analysis']['condition']}'.tr,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1), // warning yellow background
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFFF57F17), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _diagnosisResult!['analysis']['concerns'].toString().tr,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF5D4037), height: 1.4, fontFamily: 'Poppins'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTreatmentBox(_diagnosisResult!['analysis']['recommendation']),
                    ]
                    else if (_diagnosisResult!['category'] == 'farm_field') ...[
                      Text(
                        'Agricultural Field Analysis'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Canopy Coverage: ${_diagnosisResult!['analysis']['crop_coverage']}'.tr,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black87, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Health Observation: ${_diagnosisResult!['analysis']['health_observation']}'.tr,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Weed Presence: ${_diagnosisResult!['analysis']['weed_presence']}'.tr,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54, fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 16),
                      _buildTreatmentBox(_diagnosisResult!['analysis']['recommendation']),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Scan Another Image'.tr,
              isOutlined: true,
              icon: Icons.refresh_rounded,
              onTap: _clearImage,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTreatmentBox(dynamic recData) {
    if (_diagnosisResult != null && _diagnosisResult!['analysis'] is Map) {
      final analysisMap = _diagnosisResult!['analysis'] as Map<String, dynamic>;
      final chem = analysisMap['chemical_treatments'] as List<dynamic>? ?? [];
      final organic = analysisMap['organic_treatments'] as List<dynamic>? ?? [];

      if (chem.isNotEmpty || organic.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chem.isNotEmpty) ...[
              const Text(
                '🧪 Recommended Chemical Treatments:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B), fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 6),
              ...chem.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${t['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A), fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '💧 Dosage: ${t['dosage']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0284C7), fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📋 Instructions: ${t['instructions']}',
                        style: TextStyle(fontSize: 11.5, color: Colors.black.withValues(alpha: 0.7), fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                );
              }),
            ],
            if (organic.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                '🌿 Recommended Organic / Bio-Pesticides:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D6A4F), fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 6),
              ...organic.map((t) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ${t['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1B4332), fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🌱 Dosage: ${t['dosage']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D6A4F), fontFamily: 'Poppins'),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '📋 Instructions: ${t['instructions']}',
                        style: TextStyle(fontSize: 11.5, color: Colors.black.withValues(alpha: 0.7), fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        );
      }
    }

    String recommendationText = recData?.toString() ?? 'Follow recommended agricultural safety guidelines.';
    return Container(
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
                'Recommended Guidelines'.tr,
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
            recommendationText.tr,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF1B5E20),
              height: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  String cropToFriendly(String? crop) {
    if (crop == null) return 'N/A';
    return crop.tr;
  }

  void _showOutbreakMapDialog(BuildContext context) {
    String currentLocName = _currentLocationName;
    final stateDistricts = _getDistrictsForLocation(currentLocName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.map_rounded, color: Color(0xFFEF4444)),
                        SizedBox(width: 10),
                        Text(
                          '🗺️ District Outbreak Heatmap',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _showManualStatePickerDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '📍 Location: $currentLocName',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit_location_alt_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text('CHANGE STATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('📍 Live Outbreak Monitoring', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text('GPS Synced', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              height: 220,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.public_rounded, size: 48, color: Colors.white38),
                                        SizedBox(height: 8),
                                        Text('Regional Pest Risk Map Overlay', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 16, left: 10,
                                    child: _buildMapPin('🎯 YOUR LOCATION ($currentLocName)', const Color(0xFF10B981), isUser: true),
                                  ),
                                  if (stateDistricts.isNotEmpty)
                                    Positioned(top: 65, left: 50, child: _buildMapPin('${stateDistricts[0]['district']?.replaceAll(' District', '')} (${stateDistricts[0]['risk']?.split(' ')[0]})', _getRiskColor(stateDistricts[0]['color']))),
                                  if (stateDistricts.length > 1)
                                    Positioned(top: 105, right: 40, child: _buildMapPin('${stateDistricts[1]['district']?.replaceAll(' District', '')} (${stateDistricts[1]['risk']?.split(' ')[0]})', _getRiskColor(stateDistricts[1]['color']))),
                                  if (stateDistricts.length > 2)
                                    Positioned(bottom: 40, left: 90, child: _buildMapPin('${stateDistricts[2]['district']?.replaceAll(' District', '')} (${stateDistricts[2]['risk']?.split(' ')[0]})', _getRiskColor(stateDistricts[2]['color']))),
                                  if (stateDistricts.length > 3)
                                    Positioned(bottom: 30, right: 30, child: _buildMapPin('${stateDistricts[3]['district']?.replaceAll(' District', '')} (${stateDistricts[3]['risk']?.split(' ')[0]})', _getRiskColor(stateDistricts[3]['color']))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Regional District Threat Index', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      _buildDistrictRiskRow('🎯 YOUR LOCATION ($currentLocName)', '88% - HIGH THREAT', 'Local State Active Pest Threat', Colors.red, isUser: true),
                      ...stateDistricts.map((d) => _buildDistrictRiskRow(
                        d['district']!,
                        d['risk']!,
                        d['pests']!,
                        _getRiskColor(d['color']),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, String>> _getDistrictsForLocation(String loc) {
    String l = loc.toLowerCase();
    if (l.contains('tamil nadu') || l.contains('kanchipuram') || l.contains('chennai') || l.contains('coimbatore') || l.contains('thanjavur')) {
      return [
        {'district': 'Kanchipuram District', 'risk': '85% - HIGH', 'pests': 'Rice Blast & Yellow Stem Borer', 'color': 'red'},
        {'district': 'Thanjavur District', 'risk': '91% - CRITICAL', 'pests': 'Brown Planthopper & Leaf Folder', 'color': 'red'},
        {'district': 'Coimbatore District', 'risk': '78% - HIGH', 'pests': 'Cotton Bollworm & Aphids', 'color': 'orange'},
        {'district': 'Madurai District', 'risk': '68% - MODERATE', 'pests': 'Chilli Gall Midge & Whitefly', 'color': 'amber'},
        {'district': 'Salem District', 'risk': '72% - HIGH', 'pests': 'Tapioca Mealybug & Rot', 'color': 'orange'},
      ];
    }
    if (l.contains('telangana') || l.contains('hyderabad') || l.contains('warangal') || l.contains('nalgonda')) {
      return [
        {'district': 'Hyderabad / Rangareddy', 'risk': '82% - HIGH', 'pests': 'Vegetable Fruit Borer & Thrips', 'color': 'orange'},
        {'district': 'Warangal District', 'risk': '90% - CRITICAL', 'pests': 'Cotton Pink Bollworm & Chilli Wilt', 'color': 'red'},
        {'district': 'Nalgonda District', 'risk': '84% - VERY HIGH', 'pests': 'Paddy Stem Borer & Gall Midge', 'color': 'orange'},
        {'district': 'Nizamabad District', 'risk': '75% - HIGH', 'pests': 'Turmeric Leaf Spot & Maize FAW', 'color': 'orange'},
      ];
    }
    if (l.contains('karnataka') || l.contains('bengaluru') || l.contains('mandya') || l.contains('belagavi') || l.contains('mysuru')) {
      return [
        {'district': 'Bengaluru Rural District', 'risk': '70% - MODERATE', 'pests': 'Tomato Pinworm & Whitefly', 'color': 'amber'},
        {'district': 'Mandya District', 'risk': '88% - VERY HIGH', 'pests': 'Sugarcane Woolly Aphid & Paddy BPH', 'color': 'red'},
        {'district': 'Belagavi District', 'risk': '80% - HIGH', 'pests': 'Soybean Semilooper & Rust', 'color': 'orange'},
        {'district': 'Dharwad District', 'risk': '74% - HIGH', 'pests': 'Cotton Helicoverpa & Wilt', 'color': 'orange'},
      ];
    }
    if (l.contains('kerala') || l.contains('palakkad') || l.contains('wayanad') || l.contains('idukki')) {
      return [
        {'district': 'Palakkad District', 'risk': '86% - VERY HIGH', 'pests': 'Rice Bug & Brown Planthopper', 'color': 'red'},
        {'district': 'Wayanad District', 'risk': '79% - HIGH', 'pests': 'Coffee Berry Borer & Pepper Quick Wilt', 'color': 'orange'},
        {'district': 'Idukki District', 'risk': '72% - HIGH', 'pests': 'Cardamom Thrips & Rhizome Rot', 'color': 'orange'},
      ];
    }
    if (l.contains('maharashtra') || l.contains('pune') || l.contains('nashik') || l.contains('nagpur')) {
      return [
        {'district': 'Nashik District', 'risk': '89% - VERY HIGH', 'pests': 'Grape Downy Mildew & Thrips', 'color': 'red'},
        {'district': 'Pune District', 'risk': '77% - HIGH', 'pests': 'Onion Purple Blotch & Maggot', 'color': 'orange'},
        {'district': 'Nagpur District', 'risk': '85% - HIGH', 'pests': 'Citrus Blackfly & Dieback', 'color': 'red'},
        {'district': 'Ahmednagar District', 'risk': '81% - HIGH', 'pests': 'Sugarcane Pyrilla & White Grub', 'color': 'orange'},
      ];
    }
    if (l.contains('gujarat') || l.contains('rajkot') || l.contains('surat') || l.contains('ahmedabad')) {
      return [
        {'district': 'Rajkot / Saurashtra', 'risk': '87% - VERY HIGH', 'pests': 'Groundnut Stem Rot & Cotton Aphid', 'color': 'red'},
        {'district': 'Anand District', 'risk': '75% - HIGH', 'pests': 'Tobacco Caterpillar & Damping Off', 'color': 'orange'},
        {'district': 'Surat District', 'risk': '70% - MODERATE', 'pests': 'Sugarcane Top Borer', 'color': 'amber'},
      ];
    }
    if (l.contains('punjab') || l.contains('ludhiana') || l.contains('bhatinda') || l.contains('amritsar')) {
      return [
        {'district': 'Ludhiana District', 'risk': '88% - VERY HIGH', 'pests': 'Wheat Yellow Rust & Paddy Borer', 'color': 'red'},
        {'district': 'Bhatinda District', 'risk': '92% - CRITICAL', 'pests': 'Cotton Whitefly & Pink Bollworm', 'color': 'red'},
      ];
    }
    if (l.contains('haryana') || l.contains('karnal') || l.contains('hisar') || l.contains('gurugram')) {
      return [
        {'district': 'Karnal District', 'risk': '84% - VERY HIGH', 'pests': 'Paddy Bacterial Leaf Blight & Rust', 'color': 'orange'},
        {'district': 'Hisar District', 'risk': '80% - HIGH', 'pests': 'Mustard Aphid & Cotton Bollworm', 'color': 'orange'},
      ];
    }
    if (l.contains('uttar pradesh') || l.contains('lucknow') || l.contains('varanasi') || l.contains('kanpur')) {
      return [
        {'district': 'Varanasi District', 'risk': '82% - HIGH', 'pests': 'Paddy False Smut & Maize FAW', 'color': 'orange'},
        {'district': 'Lakhimpur Kheri', 'risk': '89% - VERY HIGH', 'pests': 'Sugarcane Red Rot & Early Borer', 'color': 'red'},
      ];
    }
    if (l.contains('west bengal') || l.contains('kolkata') || l.contains('burdwan') || l.contains('hooghly')) {
      return [
        {'district': 'Burdwan District', 'risk': '90% - CRITICAL', 'pests': 'Paddy Brown Planthopper & Sheath Blight', 'color': 'red'},
        {'district': 'Hooghly District', 'risk': '78% - HIGH', 'pests': 'Potato Late Blight & Jute Stem Rot', 'color': 'orange'},
      ];
    }
    if (l.contains('bihar') || l.contains('patna') || l.contains('muzaffarpur')) {
      return [
        {'district': 'Muzaffarpur District', 'risk': '83% - HIGH', 'pests': 'Litchi Fruit Borer & Maize FAW', 'color': 'orange'},
      ];
    }
    if (l.contains('odisha') || l.contains('bhubaneswar') || l.contains('cuttack')) {
      return [
        {'district': 'Cuttack District', 'risk': '85% - HIGH', 'pests': 'Paddy Gall Midge & Swarming Caterpillar', 'color': 'red'},
      ];
    }
    if (l.contains('rajasthan') || l.contains('jaipur') || l.contains('jodhpur') || l.contains('ganganagar')) {
      return [
        {'district': 'Sri Ganganagar District', 'risk': '86% - VERY HIGH', 'pests': 'Cotton Whitefly & Mustard Aphid', 'color': 'red'},
      ];
    }
    if (l.contains('madhya pradesh') || l.contains('bhopal') || l.contains('indore') || l.contains('ujjain')) {
      return [
        {'district': 'Ujjain / Malwa District', 'risk': '84% - VERY HIGH', 'pests': 'Soybean Girdle Beetle & Pod Borer', 'color': 'orange'},
      ];
    }
    if (l.contains('himachal') || l.contains('shimla') || l.contains('manali') || l.contains('dharamshala')) {
      return [
        {'district': 'Shimla District', 'risk': '78% - HIGH', 'pests': 'Apple Scab & Canker', 'color': 'orange'},
      ];
    }

    return [
      {'district': 'Kurnool District', 'risk': '92% - CRITICAL', 'pests': 'Chilli Thrips & Fall Armyworm', 'color': 'red'},
      {'district': 'Guntur District', 'risk': '88% - VERY HIGH', 'pests': 'Pink Bollworm & Aphids', 'color': 'orange'},
      {'district': 'Anantapur District', 'risk': '76% - HIGH', 'pests': 'Groundnut Tikka Leaf Spot', 'color': 'orange'},
      {'district': 'Vijayawada District', 'risk': '65% - MODERATE', 'pests': 'Stem Borer & Leaf Blast', 'color': 'amber'},
    ];
  }

  Color _getRiskColor(String? colorStr) {
    if (colorStr == 'red') return Colors.red;
    if (colorStr == 'orange') return Colors.orange;
    if (colorStr == 'amber') return Colors.amber;
    return Colors.green;
  }

  void _showManualStatePickerDialog(BuildContext parentContext) {
    TextEditingController controller = TextEditingController();
    List<String> statesList = [
      'Andhra Pradesh', 'Tamil Nadu', 'Telangana', 'Karnataka', 'Kerala',
      'Maharashtra', 'Gujarat', 'Punjab', 'Haryana', 'Uttar Pradesh',
      'West Bengal', 'Bihar', 'Rajasthan', 'Madhya Pradesh', 'Odisha',
      'Himachal Pradesh', 'Assam', 'Chhattisgarh', 'Jharkhand', 'Uttarakhand'
    ];

    showDialog(
      context: parentContext,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Select State / Enter Location'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter State or District Name:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. Maharashtra, Punjab, Karnataka...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Or Select Indian State:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: statesList.map((st) {
                    bool isSel = _currentLocationName.toLowerCase().contains(st.toLowerCase());
                    return InkWell(
                      onTap: () {
                        Navigator.pop(dialogCtx);
                        _applyManualStateSelection(st);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFF10B981) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? const Color(0xFF10B981) : Colors.white24),
                        ),
                        child: Text(
                          st,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _loadLiveGPSLocationForPests();
              },
              child: const Text('📍 Auto GPS', style: TextStyle(color: Color(0xFF10B981))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  String entered = controller.text.trim();
                  Navigator.pop(dialogCtx);
                  _applyManualStateSelection(entered);
                }
              },
              child: const Text('Apply Location', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _applyManualStateSelection(String stateOrLoc) {
    setState(() {
      _currentLocationName = stateOrLoc;
      _isLoadingAlerts = false;
    });
    _showOutbreakMapDialog(context);
  }

  Widget _buildMapPin(String label, Color color, {bool isUser = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: isUser ? Border.all(color: Colors.white, width: 1.5) : null,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUser ? Icons.my_location_rounded : Icons.location_on_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDistrictRiskRow(String district, String risk, String pests, Color color, {bool isUser = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? const Color(0xFF10B981).withOpacity(0.12) : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUser ? const Color(0xFF10B981) : Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(district, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isUser ? 13.5 : 13)),
                Text(pests, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color),
            ),
            child: Text(risk, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _showTreatmentDetailModal(BuildContext context, _PestAlert item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '💡 ${item.name} Treatment Protocol',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: item.priorityColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: item.priorityColor),
                        ),
                        child: Row(
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 32)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Target Crop: ${item.category} | Severity: ${item.priority}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('🧪 Recommended Chemical Treatment', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          item.description,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('🌿 Organic & Bio-pesticide Control', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Spray 5% Neem Seed Kernel Extract (NSKE) @ 50ml/L water.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            SizedBox(height: 6),
                            Text('• Install Yellow/Blue Sticky Traps @ 10 traps/acre for adult monitoring.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            SizedBox(height: 6),
                            Text('• Deploy Pheromone Traps @ 5 traps/acre for early detection.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('🛡️ Preventive Cultural Measures', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Text(
                          '1. Avoid excessive nitrogenous fertilizer applications.\n2. Maintain clean bunds and remove weed hosts.\n3. Ensure adequate water drainage after heavy rains.',
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PestAlertCard extends StatelessWidget {
  final _PestAlert item;
  final VoidCallback? onViewTreatment;
  const _PestAlertCard({required this.item, this.onViewTreatment});

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
                    GestureDetector(
                      onTap: onViewTreatment,
                      child: Container(
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
        color: treatment.isPriorityForLocation ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: treatment.isPriorityForLocation ? const Color(0xFF16A34A) : Colors.transparent,
          width: treatment.isPriorityForLocation ? 1.5 : 0,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (treatment.isPriorityForLocation) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '🎯 HIGH PRIORITY FOR YOUR AREA (${treatment.targetAlert ?? 'Active Alert'})',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
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
  final bool isPriorityForLocation;
  final String? targetAlert;

  const _Treatment(
    this.name,
    this.description,
    this.type,
    this.color, {
    this.isPriorityForLocation = false,
    this.targetAlert,
  });
}
