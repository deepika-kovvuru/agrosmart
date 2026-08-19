// home_screen.dart
import 'package:flutter/material.dart';
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
      final data = await ApiService.getCombinedAlerts(
        locationName: locationName,
        latitude: 15.8281,
        longitude: 78.0373,
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
              TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your village, town, or city name...',
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

  void _loadData() async {
    setState(() => _isLoading = true);

    // Fetch live pest alerts (or cached)
    final alertResult = await OfflineApiService.getPestAlerts();
    final liveAlerts = alertResult['data'];
    final fromCache = alertResult['fromCache'] == true;
    if (mounted) {
      setState(() {
        if (liveAlerts != null && liveAlerts is List && liveAlerts.isNotEmpty) {
          _alerts = (liveAlerts as List).map((a) {
            String sev = a['severity']?.toString().toLowerCase() ?? 'warning';
            String type = 'warning';
            if (sev == 'high') type = 'error';
            if (sev == 'low') type = 'success';
            return _AlertItem(
              '🐛',
              '${a['pest_name']} alert in ${a['region']} for ${a['crop']} crop. severity: ${a['severity']}',
              type,
              a['reported_at'] ?? 'Today',
            );
          }).toList();
        } else {
          _alerts = const [
            _AlertItem('🌧️', 'Heavy rain expected tomorrow. Cover your crops.', 'warning', '2h ago'),
            _AlertItem('🐛', 'Fall Armyworm alert in your district — act now!', 'error', '5h ago'),
            _AlertItem('💹', 'Paddy prices up ₹40/qtl in Kurnool mandi.', 'success', 'Today'),
          ];
        }
      });
    }

    // Fetch live market prices (or cached)
    final priceResult = await OfflineApiService.getMarketPrices();
    final prices = priceResult['data'];
    if (mounted) {
      setState(() {
        if (prices != null && prices is List && prices.isNotEmpty) {
          _marketPrices = (prices as List).take(4).map((p) {
            return {
              'name': '${p['commodity']}',
              'price': '₹${p['price'].toString().split('.')[0]}',
              'change': '${(p['change'] ?? 0) >= 0 ? '+' : ''}₹${(p['change'] ?? 0).toString().split('.')[0]}',
              'isUp': p['is_up'] == true,
            };
          }).toList();
        } else {
          _marketPrices = [
            {'name': '🌾 Paddy', 'price': '₹2,180', 'change': '+₹40', 'isUp': true},
            {'name': '🌽 Maize', 'price': '₹1,820', 'change': '-₹15', 'isUp': false},
            {'name': '🥜 Groundnut', 'price': '₹5,640', 'change': '+₹80', 'isUp': true},
            {'name': '🫘 Soybean', 'price': '₹4,120', 'change': '+₹25', 'isUp': true},
          ];
        }
        _isLoading = false;
      });
    }
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
              child: Row(
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
                  Text(
                    user?.state != null ? '${user!.state}'.tr : 'Location Unknown'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontFamily: 'Poppins',
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
                      child: Icon(Icons.person_rounded,
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
                child: Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.7), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search crops, diseases, tips...'.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
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
