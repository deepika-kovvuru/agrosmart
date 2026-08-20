// home_screen.dart
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'app_theme.dart';
import 'cropadvisoryscreen.dart';
import 'weatherforecastscreen.dart';
import 'marketpricescreen.dart';
import 'profileandsettingsscreen.dart';
import 'farmingtipsandnewsscreen.dart';
import 'pestanddisesasemanagementscreen.dart';
import 'user_session.dart';
import 'offline_api_service.dart';
import 'api_service.dart';
import 'connectivity_service.dart';
import 'local_storage.dart';
import 'translation_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  List<_AlertItem> _alerts = [];
  List<Map<String, dynamic>> _marketPrices = [];

  String _homeLocationName = "Kurnool, Andhra Pradesh";
  String _homeTemp = "28°C";
  String _homeCondition = "Partly Cloudy";
  String _homeHumidity = "68%";
  String _homeWind = "12km/h";
  bool _isWeatherLoading = false;

  final List<_QuickAction> _quickActions = const [
    _QuickAction('Crop\nAdvisory', Icons.agriculture_rounded, Color(0xFF2D6A4F), '/crop_advisory'),
    _QuickAction('Weather\nForecast', Icons.cloud_rounded, Color(0xFF4CC9F0), '/weather'),
    _QuickAction('Pest &\nDisease', Icons.bug_report_rounded, Color(0xFFE63946), '/pest'),
    _QuickAction('Market\nPrices', Icons.trending_up_rounded, Color(0xFFF4A261), '/market'),
    _QuickAction('Farming\nTips', Icons.menu_book_rounded, Color(0xFF9B59B6), '/tips'),
    _QuickAction('My\nProfile', Icons.person_rounded, Color(0xFF1ABC9C), '/profile'),
  ];

  User? get user => UserSession.currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadLiveHomeWeather();
  }

  Future<void> _loadLiveHomeWeather({String? locationName}) async {
    setState(() => _isWeatherLoading = true);
    try {
      double lat = 15.8281;
      double lon = 78.0373;

      if (locationName == null) {
        try {
          if (html.window.navigator.geolocation != null) {
            final pos = await html.window.navigator.geolocation.getCurrentPosition(
              enableHighAccuracy: true,
              timeout: const Duration(seconds: 8),
            );
            lat = pos.coords?.latitude?.toDouble() ?? 15.8281;
            lon = pos.coords?.longitude?.toDouble() ?? 78.0373;
          }
        } catch (geoErr) {
          print("GPS auto-detect fallback: $geoErr");
        }
      }

      final data = await ApiService.getCombinedAlerts(
        locationName: locationName,
        latitude: lat,
        longitude: lon,
      );
      if (data != null && data['weather'] != null) {
        final w = data['weather'];
        final loc = data['location'];
        if (mounted) {
          setState(() {
            if (loc != null && loc['display_name'] != null) {
              _homeLocationName = loc['display_name'];
            } else if (locationName != null) {
              _homeLocationName = locationName;
            }
            _homeTemp = "${w['temperature']}°C";
            _homeCondition = w['condition'] ?? "Partly Cloudy";
            _homeHumidity = "${w['humidity']}%";
            _homeWind = "${w['wind_speed']}km/h";
          });
        }
      }
    } catch (e) {
      print("Home weather load error: $e");
    } finally {
      if (mounted) setState(() => _isWeatherLoading = false);
    }
  }

  void _showHomeLocationDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController();
    final List<String> popularCities = [
      'Kurnool, Andhra Pradesh',
      'Anantapur, Andhra Pradesh',
      'Guntur, Andhra Pradesh',
      'Vijayawada, Andhra Pradesh',
      'Tirupati, Andhra Pradesh',
      'Visakhapatnam, Andhra Pradesh',
      'Hyderabad, Telangana',
      'Warangal, Telangana',
      'Ooty, Tamil Nadu',
      'Bengaluru, Karnataka',
      'Chennai, Tamil Nadu',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📍 Change My Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type state, district, or village...',
                        hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          Navigator.pop(ctx);
                          _loadLiveHomeWeather(locationName: val.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (searchController.text.trim().isNotEmpty) {
                        Navigator.pop(ctx);
                        _loadLiveHomeWeather(locationName: searchController.text.trim());
                      }
                    },
                    child: const Text('Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6A4F),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.my_location_rounded, color: Colors.white),
                  label: const Text(
                    '📍 Detect My Exact GPS Location',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadLiveHomeWeather();
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Popular Farming Districts',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: popularCities.map((city) {
                  return ActionChip(
                    backgroundColor: Colors.white.withOpacity(0.14),
                    label: Text(city.split(',')[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _loadLiveHomeWeather(locationName: city);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGlobalSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _GlobalSearchWidget(
          onNavigate: (index, target) {
            Navigator.pop(ctx);
            setState(() {
              _selectedIndex = index;
            });
          },
        );
      },
    );
  }

  void _updateLocationSpecificAlertsAndPrices() {
    String loc = _homeLocationName;
    String districtName = loc.split(',')[0].trim();
    if (districtName.isEmpty) districtName = 'Your Location';
    String stateName = loc.contains(',') ? loc.split(',').last.trim() : loc.trim();
    String l = loc.toLowerCase();

    List<_AlertItem> locAlerts = [];
    if (l.contains('tamil nadu') || l.contains('kanchipuram') || l.contains('thanjavur') || l.contains('chennai') || l.contains('coimbatore')) {
      locAlerts = [
        _AlertItem('🐛', 'Yellow Stem Borer alert in $districtName ($stateName) for Paddy crop. Severity: High', 'error', 'Just now'),
        _AlertItem('🍄', 'Rice Blast fungal advisory in $districtName region. High moisture level.', 'warning', '2h ago'),
        _AlertItem('🐛', 'Cotton Aphids & Thrips alert in $districtName farming zone.', 'warning', '4h ago'),
      ];
    } else if (l.contains('telangana') || l.contains('hyderabad') || l.contains('warangal') || l.contains('nalgonda')) {
      locAlerts = [
        _AlertItem('🐛', 'Pink Bollworm critical alert in $districtName ($stateName) for Cotton crop.', 'error', 'Just now'),
        _AlertItem('🌽', 'Fall Armyworm (FAW) alert in $districtName for Maize crop.', 'error', '3h ago'),
        _AlertItem('🦗', 'Brown Planthopper (BPH) alert in $districtName for Paddy.', 'warning', '5h ago'),
      ];
    } else if (l.contains('karnataka') || l.contains('bengaluru') || l.contains('mandya') || l.contains('belagavi') || l.contains('shimoga')) {
      locAlerts = [
        _AlertItem('🐛', 'Sugarcane Woolly Aphid alert in $districtName ($stateName) district.', 'warning', 'Just now'),
        _AlertItem('🍅', 'Tomato Pinworm & Whitefly risk in $districtName vegetable area.', 'error', '1h ago'),
        _AlertItem('🦗', 'Paddy Brown Planthopper advisory in $districtName mandi zone.', 'warning', '4h ago'),
      ];
    } else if (l.contains('maharashtra') || l.contains('nashik') || l.contains('pune') || l.contains('nagpur')) {
      locAlerts = [
        _AlertItem('🍇', 'Grape Downy Mildew advisory in $districtName ($stateName) vineyard region.', 'error', 'Just now'),
        _AlertItem('🧅', 'Onion Purple Blotch risk in $districtName district.', 'warning', '3h ago'),
        _AlertItem('🍊', 'Citrus Blackfly alert in $districtName orchards.', 'warning', '5h ago'),
      ];
    } else if (l.contains('punjab') || l.contains('haryana') || l.contains('ludhiana') || l.contains('karnal') || l.contains('hisar')) {
      locAlerts = [
        _AlertItem('🌾', 'Wheat Yellow Rust disease warning in $districtName ($stateName) region.', 'error', 'Just now'),
        _AlertItem('🐛', 'Paddy Stem Borer alert in $districtName mandi zone.', 'warning', '2h ago'),
        _AlertItem('☁️', 'Cotton Whitefly advisory in $districtName district.', 'warning', '4h ago'),
      ];
    } else if (l.contains('rajasthan') || l.contains('jaipur') || l.contains('jodhpur') || l.contains('kota')) {
      locAlerts = [
        _AlertItem('🦗', 'Locust & Whitefly alert in $districtName ($stateName) mustard fields.', 'error', 'Just now'),
        _AlertItem('🌱', 'Bajra Powdery Mildew risk in $districtName zone.', 'warning', '2h ago'),
        _AlertItem('💧', 'Moisture stress & Heat wave warning for $districtName.', 'warning', '4h ago'),
      ];
    } else if (l.contains('bihar') || l.contains('patna') || l.contains('muzaffarpur') || l.contains('gaya')) {
      locAlerts = [
        _AlertItem('🌾', 'False Smut alert in $districtName ($stateName) for Paddy crop.', 'error', 'Just now'),
        _AlertItem('🌽', 'Maize Stem Borer advisory in $districtName region.', 'warning', '2h ago'),
        _AlertItem('🥔', 'Late Blight warning in $districtName Potato farming belts.', 'error', '5h ago'),
      ];
    } else if (l.contains('west bengal') || l.contains('kolkata') || l.contains('hooghly') || l.contains('bardhaman')) {
      locAlerts = [
        _AlertItem('🌾', 'Paddy Sheath Blight alert in $districtName ($stateName) district.', 'error', 'Just now'),
        _AlertItem('🥔', 'Potato Late Blight alert in $districtName region.', 'warning', '3h ago'),
        _AlertItem('🦟', 'Jute Yellow Mite advisory in $districtName farming zone.', 'warning', '5h ago'),
      ];
    } else {
      locAlerts = [
        _AlertItem('🐛', 'Whitefly & Thrips alert in $districtName ($stateName) for Cotton crop. Severity: Medium', 'warning', 'Just now'),
        _AlertItem('🐛', 'Fall Armyworm alert in $districtName ($stateName) for Maize crop. Severity: High', 'error', '2h ago'),
        _AlertItem('🦗', 'Brown Planthopper alert in $districtName ($stateName) for Paddy crop. Severity: High', 'error', '4h ago'),
      ];
    }

    List<Map<String, dynamic>> locPrices = [];
    if (l.contains('tamil nadu') || l.contains('kanchipuram') || l.contains('thanjavur') || l.contains('chennai') || l.contains('coimbatore')) {
      locPrices = [
        {'name': '🌾 Paddy (Samba)', 'price': '₹2,280', 'change': '+₹45', 'isUp': true},
        {'name': '🌶️ Chilli (Teja)', 'price': '₹18,400', 'change': '+₹150', 'isUp': true},
        {'name': '🍌 Banana (Grand Naine)', 'price': '₹1,850', 'change': '+₹30', 'isUp': true},
        {'name': '🥥 Coconut (Dry)', 'price': '₹12,500', 'change': '-₹20', 'isUp': false},
      ];
    } else if (l.contains('telangana') || l.contains('hyderabad') || l.contains('warangal') || l.contains('nalgonda')) {
      locPrices = [
        {'name': '🌾 Paddy (BPT)', 'price': '₹2,200', 'change': '+₹35', 'isUp': true},
        {'name': '☁️ Cotton (Kapas)', 'price': '₹7,250', 'change': '+₹90', 'isUp': true},
        {'name': '🌽 Maize', 'price': '₹1,950', 'change': '-₹15', 'isUp': false},
        {'name': '🫘 Red Gram (Toor)', 'price': '₹7,800', 'change': '+₹110', 'isUp': true},
      ];
    } else if (l.contains('punjab') || l.contains('haryana') || l.contains('ludhiana') || l.contains('karnal') || l.contains('hisar')) {
      locPrices = [
        {'name': '🌾 Wheat (Sharbati)', 'price': '₹2,350', 'change': '+₹50', 'isUp': true},
        {'name': '🌾 Paddy (Basmati)', 'price': '₹3,850', 'change': '+₹120', 'isUp': true},
        {'name': '🫘 Mustard', 'price': '₹5,450', 'change': '-₹40', 'isUp': false},
        {'name': '🌽 Maize', 'price': '₹1,900', 'change': '+₹20', 'isUp': true},
      ];
    } else if (l.contains('maharashtra') || l.contains('nashik') || l.contains('pune') || l.contains('nagpur')) {
      locPrices = [
        {'name': '🍇 Grapes (Thompson)', 'price': '₹4,800', 'change': '+₹140', 'isUp': true},
        {'name': '🧅 Onion (Red)', 'price': '₹2,150', 'change': '-₹60', 'isUp': false},
        {'name': '🍊 Orange (Nagpur)', 'price': '₹3,400', 'change': '+₹75', 'isUp': true},
        {'name': '🫘 Soybean', 'price': '₹4,250', 'change': '+₹30', 'isUp': true},
      ];
    } else {
      locPrices = [
        {'name': '🌾 Paddy (Sona Masoori)', 'price': '₹2,250', 'change': '+₹40', 'isUp': true},
        {'name': '🌶️ Chilli (Guntur Red)', 'price': '₹19,200', 'change': '+₹220', 'isUp': true},
        {'name': '🥜 Groundnut (Kurnool)', 'price': '₹5,850', 'change': '+₹85', 'isUp': true},
        {'name': '☁️ Cotton (Kapas)', 'price': '₹7,100', 'change': '-₹35', 'isUp': false},
      ];
    }

    if (mounted) {
      setState(() {
        _alerts = locAlerts;
        _marketPrices = locPrices;
        _isLoading = false;
      });
    }
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    _updateLocationSpecificAlertsAndPrices();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppState.languageIndexNotifier,
      builder: (context, langIdx, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: ConnectivityService.instance.isOnline,
          builder: (context, isOnline, _) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              body: Stack(
                children: [
                  IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildHome(),
                      CropAdvisoryScreen(),
                      WeatherScreen(),
                      MarketScreen(),
                      ProfileSettingsScreen(),
                    ],
                  ),
                  // Online/Offline badge
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    right: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? Colors.green.withValues(alpha: 0.85)
                            : Colors.orange.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isOnline ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        isOnline ? '🟢 Online' : '🟠 Offline',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildBottomNav(),
            );
          },
        );
      },
    );
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: () async {
        _loadData();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: _buildWeatherCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Access'.tr,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: _quickActions.length,
                    itemBuilder: (_, i) => _buildActionTile(_quickActions[i]),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildAIInsight(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Alerts'.tr,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedIndex = 1); // Go to advisory/pest
                        },
                        child: Text(
                          'View all'.tr,
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showHomeLocationDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Threat alerts tuned to: '.tr + _homeLocationName.tr,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit_location_alt_rounded, size: 14, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => Padding(
                      padding: EdgeInsets.fromLTRB(20, i == 0 ? 8 : 0, 20, 12),
                      child: _buildAlertCard(_alerts[i]),
                    ),
                    childCount: _alerts.length,
                  ),
                ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: _buildMarketSnapshot(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppState.translate('welcome') + ' 🌅',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.name ?? 'Farmer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showHomeLocationDialog(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, color: Colors.white.withValues(alpha: 0.9), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _homeLocationName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 4),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 26),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          GestureDetector(
            onTap: () => _showGlobalSearchModal(context),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded,
                      color: Colors.white.withValues(alpha: 0.9), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search crops, diseases, tips...'.tr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: GestureDetector(
        onTap: () => _showHomeLocationDialog(context),
        child: AppCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _homeTemp,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        height: 1,
                      ),
                    ),
                    Text(
                      _homeCondition.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$_homeLocationName · Today'.tr,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  const Icon(Icons.cloud_rounded, color: Colors.white, size: 52),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _WeatherStat(Icons.water_drop_rounded, _homeHumidity),
                      const SizedBox(width: 10),
                      _WeatherStat(Icons.air_rounded, _homeWind),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return GestureDetector(
      onTap: () {
        if (action.route == '/crop_advisory') {
          setState(() => _selectedIndex = 1);
        } else if (action.route == '/weather') {
          setState(() => _selectedIndex = 2);
        } else if (action.route == '/market') {
          setState(() => _selectedIndex = 3);
        } else if (action.route == '/profile') {
          setState(() => _selectedIndex = 4);
        } else if (action.route == '/pest') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PestDiseaseScreen()),
          );
        } else if (action.route == '/tips') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FarmingTipsNewsScreen()),
          );
        } else {
          Navigator.pushNamed(context, action.route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label.contains('Advisory')
                  ? AppState.translate('advisory')
                  : action.label.contains('Weather')
                      ? AppState.translate('weather')
                      : action.label.contains('Pest')
                          ? AppState.translate('pest_alert')
                          : action.label.contains('Market')
                              ? AppState.translate('market')
                              : action.label.contains('Tips')
                                  ? AppState.translate('tips_news')
                                  : action.label.contains('Profile')
                                      ? AppState.translate('profile')
                                      : action.label.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                height: 1.3,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsight() {
    return AppCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✨ ' + 'AI Insight'.tr,
                        style: TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Ideal time to apply Urea fertilizer this week — soil moisture is optimal.'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'View Full Advisory'.tr + ' →',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('🌿', style: TextStyle(fontSize: 52)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(_AlertItem alert) {
    final colors = {
      'warning': const Color(0xFFFFF3CD),
      'error': const Color(0xFFFFEBEE),
      'success': const Color(0xFFE8F5E9),
    };
    final borderColors = {
      'warning': const Color(0xFFFFB300),
      'error': AppTheme.error,
      'success': AppTheme.success,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors[alert.type],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColors[alert.type]!.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Text(alert.emoji, style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message.tr,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.4,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            alert.time.tr,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textLight,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketSnapshot() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Market Prices Today'.tr,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 3),
              child: Text(
                'View all'.tr,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: _marketPrices.map((c) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Text(() {
                      final String displayName = c['name'] ?? '';
                      if (displayName.contains(' ')) {
                        final parts = displayName.split(' ');
                        final emoji = parts[0];
                        final name = parts.sublist(1).join(' ');
                        return '$emoji ${name.tr}';
                      }
                      return displayName.tr;
                    }(),
                        style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      c['price'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c['isUp']
                            ? AppTheme.success.withValues(alpha: 0.1)
                            : AppTheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        c['change'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c['isUp'] ? AppTheme.success : AppTheme.error,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.agriculture_rounded, Icons.agriculture_outlined, 'Advisory'),
      (Icons.cloud_rounded, Icons.cloud_outlined, 'Weather'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Market'),
      (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];

    return Container(
      height: 72 + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: List.generate(items.length, (i) {
            final isSelected = i == _selectedIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        isSelected ? items[i].$1 : items[i].$2,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textLight,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      items[i].$3.tr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textLight,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WeatherStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _WeatherStat(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QuickAction(this.label, this.icon, this.color, this.route);
}

class _AlertItem {
  final String emoji;
  final String message;
  final String type;
  final String time;
  const _AlertItem(this.emoji, this.message, this.type, this.time);
}

class _GlobalSearchWidget extends StatefulWidget {
  final Function(int index, String? target) onNavigate;
  const _GlobalSearchWidget({required this.onNavigate});

  @override
  State<_GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<_GlobalSearchWidget> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  final List<Map<String, dynamic>> _allItems = const [
    {'title': 'Chilli Thrips (Risk: 92%)', 'category': '🐛 Pests & Diseases', 'tab': 0, 'desc': 'Critical threat in Andhra Pradesh & Tamil Nadu. High temp & low humidity trigger.'},
    {'title': 'Fall Armyworm (FAW)', 'category': '🐛 Pests & Diseases', 'tab': 0, 'desc': 'Maize and Paddy pest. Spray Chlorpyrifos 20 EC or Neem Extract.'},
    {'title': 'Brown Planthopper (BPH)', 'category': '🐛 Pests & Diseases', 'tab': 0, 'desc': 'Sucking pest in rice crop. Spray Imidacloprid 17.8 SL @ 0.5ml/L.'},
    {'title': 'Rice Blast Disease', 'category': '🍄 Diseases', 'tab': 0, 'desc': 'Fungal blast in paddy. Spray Tricyclazole 75 WP @ 0.6g/L.'},
    {'title': 'Rice (Paddy) Cultivation', 'category': '🌾 Crops', 'tab': 1, 'desc': 'Complete advisory: Nursery, transplantation, fertilizer & water management.'},
    {'title': 'Chilli Crop Management', 'category': '🌾 Crops', 'tab': 1, 'desc': 'Best practices for chilli flowering, thrips protection, and yield boosting.'},
    {'title': 'Cotton Crop Care', 'category': '🌾 Crops', 'tab': 1, 'desc': 'Pink bollworm monitoring, sticky trap installation, and picking guidelines.'},
    {'title': 'Imidacloprid 17.8 SL', 'category': '🧪 Treatments', 'tab': 0, 'desc': 'Chemical spray for sucking pests, whitefly, thrips & aphids.'},
    {'title': 'Neem Oil 5% NSKE', 'category': '🌿 Bio-Pesticide', 'tab': 0, 'desc': 'Eco-friendly organic spray for BPH, caterpillars & sucking pests.'},
    {'title': 'Chlorpyrifos 20 EC', 'category': '🧪 Treatments', 'tab': 0, 'desc': 'Insecticide spray for Fall Armyworm and stem borer control.'},
    {'title': 'Live Open-Meteo Weather Forecast', 'category': '⛅ Weather', 'tab': 2, 'desc': 'Hourly rain probability, 7-day daily forecast & farming weather alerts.'},
    {'title': 'Market Mandi Prices (Paddy ₹2,180)', 'category': '📈 Market Prices', 'tab': 3, 'desc': 'Real-time APMC mandi prices for paddy, cotton, maize, groundnut.'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _allItems
        : _allItems.where((item) =>
            item['title'].toString().toLowerCase().contains(_query.toLowerCase()) ||
            item['category'].toString().toLowerCase().contains(_query.toLowerCase()) ||
            item['desc'].toString().toLowerCase().contains(_query.toLowerCase())).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF10B981), size: 24),
                const SizedBox(width: 10),
                const Text(
                  '🔍 Intelligence Search',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _queryController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search crops, thrips, FAW, weather, prices...',
                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70),
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
            const SizedBox(height: 14),
            Text(
              _query.isEmpty ? '🔥 Popular Agricultural Searches:' : 'Found ${filtered.length} Matching Results:',
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final item = filtered[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: Text(
                              item['category'],
                              style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item['desc'],
                          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                      onTap: () {
                        widget.onNavigate(item['tab'], item['title']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
