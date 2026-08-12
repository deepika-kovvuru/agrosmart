// weather_screen.dart
import 'package:flutter/material.dart';
import 'translation_provider.dart';


class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final List<_HourlyWeather> _hourly = const [
    _HourlyWeather('6 AM', Icons.wb_sunny_rounded, '24°', 0),
    _HourlyWeather('9 AM', Icons.wb_sunny_rounded, '27°', 0),
    _HourlyWeather('12 PM', Icons.cloud_rounded, '31°', 10),
    _HourlyWeather('3 PM', Icons.thunderstorm_rounded, '29°', 80),
    _HourlyWeather('6 PM', Icons.grain_rounded, '26°', 60),
    _HourlyWeather('9 PM', Icons.cloud_rounded, '23°', 20),
  ];

  final List<_DailyWeather> _daily = const [
    _DailyWeather('Thu', '🌤️', '32°', '22°', 10, 'Partly cloudy'),
    _DailyWeather('Fri', '⛈️', '28°', '20°', 85, 'Heavy rain likely'),
    _DailyWeather('Sat', '🌧️', '26°', '19°', 70, 'Moderate rain'),
    _DailyWeather('Sun', '⛅', '30°', '21°', 25, 'Mostly cloudy'),
    _DailyWeather('Mon', '☀️', '34°', '23°', 5, 'Clear & sunny'),
    _DailyWeather('Tue', '🌤️', '33°', '22°', 15, 'Partly cloudy'),
    _DailyWeather('Wed', '☀️', '35°', '24°', 5, 'Clear sky'),
  ];

  final List<_FarmingAlert> _farmingAlerts = const [
    _FarmingAlert(
      '🌧️',
      'Rain Alert',
      'Heavy rainfall (40-60mm) expected Friday. Drain paddy fields to prevent waterlogging.',
      Color(0xFF1565C0),
    ),
    _FarmingAlert(
      '🌡️',
      'Heat Advisory',
      'Temperatures above 34°C on Mon-Wed. Irrigate crops in the early morning.',
      Color(0xFFE65100),
    ),
    _FarmingAlert(
      '💨',
      'Wind Warning',
      'Strong winds 25-35 km/h Thursday afternoon. Avoid spraying pesticides.',
      Color(0xFF6A1B9A),
    ),
  ];

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
              const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
            ],
          ),

          const SizedBox(height: 32),

          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                'Kurnool, Andhra Pradesh'.tr,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white70, size: 18),
            ],
          ),

          const SizedBox(height: 16),

          // Big temperature
          const Text(
            '28°C',
            style: TextStyle(
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
                'Partly Cloudy'.tr,
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
            'Feels like 31°C  ·  H: 34°  L: 20°'.tr,
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WeatherStatColumn(Icons.water_drop_rounded, '68%', 'Humidity'),
                _VerticalDivider(),
                _WeatherStatColumn(Icons.air_rounded, '12 km/h', 'Wind'),
                _VerticalDivider(),
                _WeatherStatColumn(Icons.compress_rounded, '1012 hPa', 'Pressure'),
                _VerticalDivider(),
                _WeatherStatColumn(Icons.wb_sunny_rounded, 'UV 7', 'UV Index'),
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
              value: '6:04 AM / 6:48 PM',
              icon: Icons.wb_twilight_rounded,
              color: const Color(0xFFF4A261),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _DetailCard(
              title: 'Rain Probability',
              value: '35% — 12mm',
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
