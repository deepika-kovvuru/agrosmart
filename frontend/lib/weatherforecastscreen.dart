// weather_screen.dart
import 'package:flutter/material.dart';
import 'translation_provider.dart';
import 'api_service.dart';


class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String _locationName = "Kurnool, Andhra Pradesh";
  String _temp = "28°C";
  String _condition = "Partly Cloudy";
  String _feelsLike = "31°C";
  String _high = "34°";
  String _low = "20°";
  String _humidity = "65%";
  String _wind = "12 km/h";
  String _pressure = "1012 hPa";
  String _uvIndex = "UV 6.5";
  String _sunriseSunset = "06:05 AM / 06:45 PM";
  String _rainProbabilityDetail = "40% — 0mm";
  String _lastUpdated = "Updated just now";
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadLiveWeatherData();
  }

  Future<void> _loadLiveWeatherData() async {
    setState(() => _isRefreshing = true);
    try {
      final data = await ApiService.getCombinedAlerts(latitude: 15.8281, longitude: 78.0373);
      if (data != null && data['weather'] != null) {
        final w = data['weather'];
        final loc = data['location'];
        if (mounted) {
          setState(() {
            if (loc != null) {
              _locationName = loc['display_name'] ?? "${loc['district']}, ${loc['state']}";
            }
            _temp = "${w['temperature']}°C";
            _condition = w['condition'] ?? "Partly Cloudy";
            _feelsLike = "${w['feels_like']}°C";
            _high = "${w['high']}°";
            _low = "${w['low']}°";
            _humidity = "${w['humidity']}%";
            _wind = "${w['wind_speed']} km/h";
            _pressure = "${w['pressure']} hPa";
            _uvIndex = "UV ${w['uv_index']}";
            _sunriseSunset = "${w['sunrise'] ?? '06:05 AM'} / ${w['sunset'] ?? '06:45 PM'}";
            _rainProbabilityDetail = "${w['rain_probability'] ?? 40}% — ${w['rainfall'] ?? 0}mm";
            _lastUpdated = "Updated just now";

            if (w['hourly_forecast'] is List) {
              _hourly = (w['hourly_forecast'] as List).map((h) {
                String condStr = h['condition']?.toString() ?? '';
                IconData icon = Icons.cloud_rounded;
                if (condStr.contains('Clear') || condStr.contains('Sunny')) icon = Icons.wb_sunny_rounded;
                if (condStr.contains('Rain') || condStr.contains('Drizzle')) icon = Icons.grain_rounded;
                if (condStr.contains('Thunder')) icon = Icons.thunderstorm_rounded;

                return _HourlyWeather(
                  h['time']?.toString() ?? '12 PM',
                  icon,
                  h['temp']?.toString() ?? '25°',
                  (h['rain_prob'] is num) ? (h['rain_prob'] as num).toInt() : 0,
                );
              }).toList();
            }

            if (w['daily_forecast'] is List) {
              _daily = (w['daily_forecast'] as List).map((d) {
                String condStr = d['condition']?.toString() ?? 'Partly Cloudy';
                String emoji = '🌤️';
                if (condStr.contains('Clear') || condStr.contains('Sunny')) emoji = '☀️';
                if (condStr.contains('Rain') || condStr.contains('Shower')) emoji = '🌧️';
                if (condStr.contains('Heavy Rain')) emoji = '⛈️';

                return _DailyWeather(
                  d['day']?.toString() ?? 'Mon',
                  emoji,
                  d['max_temp']?.toString() ?? '30°',
                  d['min_temp']?.toString() ?? '20°',
                  (d['rain_prob'] is num) ? (d['rain_prob'] as num).toInt() : 10,
                  condStr,
                );
              }).toList();
            }

            _generateFarmingWeatherAlerts(w, _locationName);
          });
        }
      }
    } catch (e) {
      print("Weather load error: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _showLocationSelectorDialog(BuildContext context) {
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
      'Nalgonda, Telangana',
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
                    '📍 Select Your Location',
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
                  hintText: 'Type your village, town, or district...',
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
                    _loadLiveWeatherDataForLocation(val.trim());
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
                    '📍 Use My Exact GPS Location',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _loadLiveWeatherData();
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
                      _loadLiveWeatherDataForLocation(city);
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

  Future<void> _loadLiveWeatherDataForLocation(String locationName) async {
    setState(() => _isRefreshing = true);
    try {
      final data = await ApiService.getCombinedAlerts(
        locationName: locationName,
        crops: ['Rice', 'Cotton', 'Maize', 'Tomato', 'Chilli'],
      );
      if (data != null && data['weather'] != null) {
        final w = data['weather'];
        final loc = data['location'];
        if (mounted) {
          setState(() {
            _locationName = (loc != null && loc['display_name'] != null)
                ? loc['display_name']
                : locationName;
            _temp = "${w['temperature']}°C";
            _condition = w['condition'] ?? "Partly Cloudy";
            _feelsLike = "${w['feels_like']}°C";
            _high = "${w['high']}°";
            _low = "${w['low']}°";
            _humidity = "${w['humidity']}%";
            _wind = "${w['wind_speed']} km/h";
            _pressure = "${w['pressure']} hPa";
            _uvIndex = "UV ${w['uv_index']}";
            _sunriseSunset = "${w['sunrise'] ?? '06:05 AM'} / ${w['sunset'] ?? '06:45 PM'}";
            _rainProbabilityDetail = "${w['rain_probability'] ?? 40}% — ${w['rainfall'] ?? 0}mm";
            _lastUpdated = "Updated just now";

            if (w['hourly_forecast'] is List) {
              _hourly = (w['hourly_forecast'] as List).map((h) {
                String condStr = h['condition']?.toString() ?? '';
                IconData icon = Icons.cloud_rounded;
                if (condStr.contains('Clear') || condStr.contains('Sunny')) icon = Icons.wb_sunny_rounded;
                if (condStr.contains('Rain') || condStr.contains('Drizzle')) icon = Icons.grain_rounded;
                if (condStr.contains('Thunder')) icon = Icons.thunderstorm_rounded;

                return _HourlyWeather(
                  h['time']?.toString() ?? '12 PM',
                  icon,
                  h['temp']?.toString() ?? '25°',
                  (h['rain_prob'] is num) ? (h['rain_prob'] as num).toInt() : 0,
                );
              }).toList();
            }

            if (w['daily_forecast'] is List) {
              _daily = (w['daily_forecast'] as List).map((d) {
                String condStr = d['condition']?.toString() ?? 'Partly Cloudy';
                String emoji = '🌤️';
                if (condStr.contains('Clear') || condStr.contains('Sunny')) emoji = '☀️';
                if (condStr.contains('Rain') || condStr.contains('Shower')) emoji = '🌧️';
                if (condStr.contains('Heavy Rain')) emoji = '⛈️';

                return _DailyWeather(
                  d['day']?.toString() ?? 'Mon',
                  emoji,
                  d['max_temp']?.toString() ?? '30°',
                  d['min_temp']?.toString() ?? '20°',
                  (d['rain_prob'] is num) ? (d['rain_prob'] as num).toInt() : 10,
                  condStr,
                );
              }).toList();
            }

            _generateFarmingWeatherAlerts(w, _locationName);
          });
        }
      }
    } catch (e) {
      print("Error updating location: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  List<_HourlyWeather> _hourly = const [
    _HourlyWeather('6 AM', Icons.wb_sunny_rounded, '24°', 0),
    _HourlyWeather('9 AM', Icons.wb_sunny_rounded, '27°', 0),
    _HourlyWeather('12 PM', Icons.cloud_rounded, '31°', 10),
    _HourlyWeather('3 PM', Icons.thunderstorm_rounded, '29°', 80),
    _HourlyWeather('6 PM', Icons.grain_rounded, '26°', 60),
    _HourlyWeather('9 PM', Icons.cloud_rounded, '23°', 20),
  ];

  List<_DailyWeather> _daily = const [
    _DailyWeather('Thu', '🌤️', '32°', '22°', 10, 'Partly cloudy'),
    _DailyWeather('Fri', '⛈️', '28°', '20°', 85, 'Heavy rain likely'),
    _DailyWeather('Sat', '🌧️', '26°', '19°', 70, 'Moderate rain'),
    _DailyWeather('Sun', '⛅', '30°', '21°', 25, 'Mostly cloudy'),
    _DailyWeather('Mon', '☀️', '34°', '23°', 5, 'Clear & sunny'),
    _DailyWeather('Tue', '🌤️', '33°', '22°', 15, 'Partly cloudy'),
    _DailyWeather('Wed', '☀️', '35°', '24°', 5, 'Clear sky'),
  ];

  List<_FarmingAlert> _farmingAlerts = [
    const _FarmingAlert(
      '🌧️',
      'Rain Alert',
      'Heavy rainfall (40-60mm) expected Friday. Drain paddy fields to prevent waterlogging.',
      Color(0xFF1565C0),
    ),
    const _FarmingAlert(
      '🌡️',
      'Heat Advisory',
      'Temperatures above 34°C on Mon-Wed. Irrigate crops in the early morning.',
      Color(0xFFE65100),
    ),
    const _FarmingAlert(
      '💨',
      'Wind Warning',
      'Strong winds 25-35 km/h Thursday afternoon. Avoid spraying pesticides.',
      Color(0xFF4A148C),
    ),
  ];

  void _generateFarmingWeatherAlerts(Map<String, dynamic> w, String locName) {
    List<_FarmingAlert> alerts = [];
    double temp = (w['temperature'] is num) ? (w['temperature'] as num).toDouble() : 28.0;
    double wind = (w['wind_speed'] is num) ? (w['wind_speed'] as num).toDouble() : 12.0;
    int humidity = (w['humidity'] is num) ? (w['humidity'] as num).toInt() : 60;
    int rainProb = (w['rain_probability'] is num) ? (w['rain_probability'] as num).toInt() : 20;
    double rainfall = (w['rainfall'] is num) ? (w['rainfall'] as num).toDouble() : 0.0;
    String cond = w['condition']?.toString() ?? 'Partly Cloudy';

    if (rainProb >= 50 || rainfall > 2.0 || cond.toLowerCase().contains('rain') || cond.toLowerCase().contains('drizzle')) {
      alerts.add(_FarmingAlert(
        '🌧️',
        'Rain & Moisture Alert',
        'High rain chance ($rainProb%) and rainfall ($rainfall mm) in $locName. Postpone pesticide sprays & ensure drainage.',
        const Color(0xFF1565C0),
      ));
    } else {
      alerts.add(_FarmingAlert(
        '💧',
        'Irrigation Advisory',
        'Low rainfall chance ($rainProb%) in $locName. Maintain adequate soil moisture for active growing crops.',
        const Color(0xFF0284C7),
      ));
    }

    if (temp >= 32.0) {
      alerts.add(_FarmingAlert(
        '🌡️',
        'High Temperature Advisory',
        'Current temperature is $temp°C in $locName. Irrigate early in the morning or late evening to reduce crop heat stress.',
        const Color(0xFFE65100),
      ));
    } else if (temp <= 18.0) {
      alerts.add(_FarmingAlert(
        '❄️',
        'Cool Weather Advisory',
        'Cool temperatures ($temp°C) in $locName. Protect sensitive nursery beds and seedling crops.',
        const Color(0xFF0D9488),
      ));
    }

    if (wind >= 20.0) {
      alerts.add(_FarmingAlert(
        '💨',
        'High Wind Warning',
        'Wind speed $wind km/h in $locName. Avoid foliar spray applications to prevent chemical drift.',
        const Color(0xFF4A148C),
      ));
    } else {
      alerts.add(_FarmingAlert(
        '🍃',
        'Favorable Spraying Window',
        'Moderate wind speed ($wind km/h) in $locName. Favorable conditions for scheduled field inspection and spray tasks.',
        const Color(0xFF2D6A4F),
      ));
    }

    if (humidity >= 75) {
      alerts.add(_FarmingAlert(
        '🍄',
        'High Humidity Disease Risk',
        'Relative humidity is $humidity% in $locName. Favorable conditions for fungal leaf blast and rot. Inspect leaves.',
        const Color(0xFFD97706),
      ));
    }

    _farmingAlerts = alerts;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppState.languageIndexNotifier,
      builder: (context, langIdx, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildMainWeatherCard(context)),
              SliverToBoxAdapter(child: _buildHourlyForecast()),
              SliverToBoxAdapter(child: _buildWeatherDetails()),
              SliverToBoxAdapter(child: _build7DayForecast()),
              SliverToBoxAdapter(child: _buildFarmingAlerts()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainWeatherCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 16, 24, 36),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B2A), Color(0xFF1565C0), Color(0xFF1E88E5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // AppBar row
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Weather Forecast'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadLiveWeatherData,
                child: _isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Location
          GestureDetector(
            onTap: () => _showLocationSelectorDialog(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _locationName.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Big temperature
          Text(
            _temp,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w200,
              color: Colors.white,
              height: 1,
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _condition.tr,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            'Feels like $_feelsLike  ·  H: $_high  L: $_low'.tr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
              fontFamily: 'Poppins',
            ),
          ),

          const SizedBox(height: 28),

          // Stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WeatherStatColumn(Icons.water_drop_rounded, _humidity, 'Humidity'),
                const _VerticalDivider(),
                _WeatherStatColumn(Icons.air_rounded, _wind, 'Wind'),
                const _VerticalDivider(),
                _WeatherStatColumn(Icons.compress_rounded, _pressure, 'Pressure'),
                const _VerticalDivider(),
                _WeatherStatColumn(Icons.wb_sunny_rounded, _uvIndex, 'UV Index'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Forecast".tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _hourly
                  .map((h) => _HourlyCard(item: h))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _DetailCard(
              title: 'Sunrise / Sunset',
              value: _sunriseSunset,
              icon: Icons.wb_twilight_rounded,
              color: const Color(0xFFF4A261),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DetailCard(
              title: 'Rain Probability',
              value: _rainProbabilityDetail,
              icon: Icons.umbrella_rounded,
              color: const Color(0xFF4CC9F0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _build7DayForecast() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-Day Forecast'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          ..._daily.map((d) => _DailyRow(item: d)),
        ],
      ),
    );
  }

  Widget _buildFarmingAlerts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Farming Weather Alerts'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          ..._farmingAlerts.map((a) => _FarmingAlertCard(alert: a)),
        ],
      ),
    );
  }
}

class _WeatherStatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _WeatherStatColumn(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(
          value.tr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          label.tr,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.white24);
  }
}

class _HourlyCard extends StatelessWidget {
  final _HourlyWeather item;
  const _HourlyCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            item.time.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Icon(item.icon, color: Colors.white, size: 22),
          const SizedBox(height: 6),
          Text(
            item.temp.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          if (item.rain > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${item.rain}%',
              style: const TextStyle(
                color: Color(0xFF90CAF9),
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final _DailyWeather item;
  const _DailyRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              item.day.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.description.tr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          if (item.rain > 0)
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.rain}%',
                style: const TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 10,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            item.low.tr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
          const Text(' — ',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
          Text(
            item.high.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _DetailCard(
      {required this.title,
        required this.value,
        required this.icon,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title.tr,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmingAlertCard extends StatelessWidget {
  final _FarmingAlert alert;
  const _FarmingAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: alert.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: alert.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(alert.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message.tr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                    height: 1.5,
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
}

class _HourlyWeather {
  final String time, temp;
  final IconData icon;
  final int rain;
  const _HourlyWeather(this.time, this.icon, this.temp, this.rain);
}

class _DailyWeather {
  final String day, emoji, high, low, description;
  final int rain;
  const _DailyWeather(
      this.day, this.emoji, this.high, this.low, this.rain, this.description);
}

class _FarmingAlert {
  final String emoji, title, message;
  final Color color;
  const _FarmingAlert(this.emoji, this.title, this.message, this.color);
}
