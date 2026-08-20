// crop_advisory_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'translation_provider.dart';
import 'ai_assistant_screen.dart';

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCropIndex = 0;
  int _selectedStageIndex = 1; // Default to Stage 2: Vegetative Growth
  bool _isLoadingAdvisories = true;
  bool _isLoadingSchedule = true;

  final List<String> _crops = [
    'Paddy',
    'Maize',
    'Groundnut',
    'Cotton',
    'Soybean',
    'Tomato',
    'Chilli',
    'Wheat',
    'Sugarcane',
    'Banana',
    'Onion',
    'Potato',
    'Mustard',
    'Mango',
    'Pulses',
    'Turmeric',
    'Pomegranate',
    'Grape',
    'Coffee',
    'Tea',
  ];

  final List<Map<String, String>> _allCropPlants = [
    {'name': 'Paddy / Rice', 'category': 'Cereals', 'emoji': '🌾'},
    {'name': 'Maize / Corn', 'category': 'Cereals', 'emoji': '🌽'},
    {'name': 'Wheat', 'category': 'Cereals', 'emoji': '🌾'},
    {'name': 'Bajra / Pearl Millet', 'category': 'Millets', 'emoji': '🌾'},
    {'name': 'Jowar / Sorghum', 'category': 'Millets', 'emoji': '🌾'},
    {'name': 'Ragi / Finger Millet', 'category': 'Millets', 'emoji': '🌾'},
    {'name': 'Groundnut / Peanut', 'category': 'Oilseeds', 'emoji': '🥜'},
    {'name': 'Cotton', 'category': 'Commercial', 'emoji': '☁️'},
    {'name': 'Soybean', 'category': 'Oilseeds', 'emoji': '🫘'},
    {'name': 'Sugarcane', 'category': 'Commercial', 'emoji': '🎋'},
    {'name': 'Tomato', 'category': 'Vegetables', 'emoji': '🍅'},
    {'name': 'Chilli / Red Pepper', 'category': 'Vegetables', 'emoji': '🌶️'},
    {'name': 'Onion', 'category': 'Vegetables', 'emoji': '🧅'},
    {'name': 'Potato', 'category': 'Vegetables', 'emoji': '🥔'},
    {'name': 'Brinjal / Eggplant', 'category': 'Vegetables', 'emoji': '🍆'},
    {'name': 'Garlic', 'category': 'Vegetables', 'emoji': '🧄'},
    {'name': 'Ginger', 'category': 'Spices', 'emoji': '🫚'},
    {'name': 'Turmeric', 'category': 'Spices', 'emoji': '🟡'},
    {'name': 'Mustard', 'category': 'Oilseeds', 'emoji': '🌼'},
    {'name': 'Banana', 'category': 'Fruits', 'emoji': '🍌'},
    {'name': 'Mango', 'category': 'Fruits', 'emoji': '🥭'},
    {'name': 'Pomegranate', 'category': 'Fruits', 'emoji': '🔴'},
    {'name': 'Grape', 'category': 'Fruits', 'emoji': '🍇'},
    {'name': 'Guava', 'category': 'Fruits', 'emoji': '🍏'},
    {'name': 'Papaya', 'category': 'Fruits', 'emoji': '🍈'},
    {'name': 'Watermelon', 'category': 'Fruits', 'emoji': '🍉'},
    {'name': 'Pulses / Red Gram (Tur)', 'category': 'Pulses', 'emoji': '🫘'},
    {'name': 'Black Gram (Urad)', 'category': 'Pulses', 'emoji': '🫘'},
    {'name': 'Green Gram (Moong)', 'category': 'Pulses', 'emoji': '🫘'},
    {'name': 'Bengal Gram (Chickpea)', 'category': 'Pulses', 'emoji': '🫘'},
    {'name': 'Coffee', 'category': 'Plantation', 'emoji': '☕'},
    {'name': 'Tea', 'category': 'Plantation', 'emoji': '🍵'},
    {'name': 'Cardamom', 'category': 'Spices', 'emoji': '🫛'},
    {'name': 'Vanilla', 'category': 'Spices', 'emoji': '🌿'},
    {'name': 'Black Pepper', 'category': 'Spices', 'emoji': '⚫'},
    {'name': 'Coconut', 'category': 'Plantation', 'emoji': '🥥'},
    {'name': 'Arecanut', 'category': 'Plantation', 'emoji': '🌰'},
    {'name': 'Rubber', 'category': 'Plantation', 'emoji': '🪵'},
    {'name': 'Cabbage', 'category': 'Vegetables', 'emoji': '🥬'},
    {'name': 'Cauliflower', 'category': 'Vegetables', 'emoji': '🥦'},
    {'name': 'Carrot', 'category': 'Vegetables', 'emoji': '🥕'},
    {'name': 'Ladyfinger / Okra', 'category': 'Vegetables', 'emoji': '🥒'},
    {'name': 'Dragon Fruit', 'category': 'Exotic Fruits', 'emoji': '🐉'},
    {'name': 'Sunflower', 'category': 'Oilseeds', 'emoji': '🌻'},
  ];

  final List<Map<String, String>> _growthStages = [
    {
      'stage': 'Germination & Seedling',
      'code': 'Stage 1',
      'icon': '🌱',
      'desc': 'Seed sprouting, root establishment, and early leaf emergence.',
      'health': '95/100 🟢',
      'next_action': 'Moisture check'
    },
    {
      'stage': 'Vegetative Growth (V1-V5)',
      'code': 'Stage 2',
      'icon': '🌿',
      'desc': 'Rapid leaf expansion, stem elongation, and root expansion.',
      'health': '88/100 🟢',
      'next_action': 'Fertilizer top-dress'
    },
    {
      'stage': 'Flowering & Tillering / Budding',
      'code': 'Stage 3',
      'icon': '🌸',
      'desc': 'Floral initiation, pollination, and high nutrient demand phase.',
      'health': '84/100 🟡',
      'next_action': 'Pest scouting & Irrigate'
    },
    {
      'stage': 'Fruit / Pod / Grain Formation',
      'code': 'Stage 4',
      'icon': '🌾',
      'desc': 'Grain filling, boll development, or pod swelling.',
      'health': '90/100 🟢',
      'next_action': 'Potash spray & Water'
    },
    {
      'stage': 'Ripening & Maturation',
      'code': 'Stage 5',
      'icon': '🍇',
      'desc': 'Crop color shift, moisture reduction, and seed dry-down.',
      'health': '92/100 🟢',
      'next_action': 'Stop irrigation'
    },
    {
      'stage': 'Harvest & Post-Harvest',
      'code': 'Stage 6',
      'icon': '🚜',
      'desc': 'Maturity reached. Field harvesting, drying, and storage.',
      'health': '96/100 🟢',
      'next_action': 'Harvest field'
    },
  ];

  List<_AdvisoryItem> _advisories = [];
  List<_ScheduleItem> _schedule = [];

  User? get user => UserSession.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  void _loadAllData() {
    _loadAdvisories();
    _loadSchedule();
  }

  void _loadAdvisories() async {
    setState(() => _isLoadingAdvisories = true);
    final cropName = _crops[_selectedCropIndex];
    
    if (user != null) {
      final res = await ApiService.getCropAdvisories(user!.id, crop: cropName);
      if (mounted && res.isNotEmpty) {
        setState(() {
          _advisories = res.map((a) {
            String p = a['priority']?.toString() ?? 'Info';
            Color pc = const Color(0xFF4CC9F0);
            if (p == 'High') pc = const Color(0xFFE63946);
            if (p == 'Medium') pc = const Color(0xFFF4A261);
            if (p == 'Low') pc = const Color(0xFF2D6A4F);
            
            return _AdvisoryItem(
              id: a['id'],
              emoji: a['emoji'] ?? '🌿',
              title: a['title'] ?? 'Advisory',
              description: a['description'] ?? '',
              priority: p,
              priorityColor: pc,
              time: a['created_at'] ?? 'Just now',
            );
          }).toList();
          _isLoadingAdvisories = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() {
        _advisories = _getStageAdvisories(cropName, _selectedStageIndex);
        _isLoadingAdvisories = false;
      });
    }
  }

  List<_AdvisoryItem> _getStageAdvisories(String crop, int stageIdx) {
    switch (stageIdx) {
      case 0: // Germination & Seedling
        return [
          _AdvisoryItem(
            id: 101,
            emoji: '🌱',
            title: '$crop Seedling Moisture & Soil Care',
            description: 'Maintain 55-60% soil moisture for uniform seed germination. Avoid waterlogging which causes seedling damp-off.',
            priority: 'Medium',
            priorityColor: const Color(0xFFF4A261),
            time: 'Live Update',
          ),
          _AdvisoryItem(
            id: 102,
            emoji: '🛡️',
            title: '$crop Seed Treatment & Root Shield',
            description: 'Apply Trichoderma viride 5g/kg seed or bio-fungicide to shield emerging roots from soil-borne pathogens.',
            priority: 'High',
            priorityColor: const Color(0xFFE63946),
            time: 'Today',
          ),
          _AdvisoryItem(
            id: 103,
            emoji: '🌤️',
            title: '$crop Climate & Temperature Impact',
            description: 'Current temperature (28-32°C) is ideal for $crop seedling emergence. Keep field drains clear for unexpected rains.',
            priority: 'Info',
            priorityColor: const Color(0xFF4CC9F0),
            time: 'Live Weather',
          ),
        ];
      case 1: // Vegetative Growth
        return [
          _AdvisoryItem(
            id: 201,
            emoji: '💧',
            title: '$crop Irrigation Schedule (Vegetative)',
            description: 'Soil moisture is optimal at 62%. Irrigate within 2 days to support rapid canopy and shoot growth.',
            priority: 'Medium',
            priorityColor: const Color(0xFFF4A261),
            time: '2h ago',
          ),
          _AdvisoryItem(
            id: 202,
            emoji: '🌿',
            title: '$crop Nitrogen Fertilizer Top-Dress',
            description: 'Apply 2nd dose of NPK / Urea (40 kg/acre) during early vegetative stage for stem vigor.',
            priority: 'High',
            priorityColor: const Color(0xFFE63946),
            time: 'Today',
          ),
          _AdvisoryItem(
            id: 203,
            emoji: '🐛',
            title: '$crop Weeding & Sucking Pest Scouting',
            description: 'Perform early weeding to prevent nutrient loss. Scout leaf undersides for thrips or aphid nymphs twice weekly.',
            priority: 'Info',
            priorityColor: const Color(0xFF4CC9F0),
            time: 'Yesterday',
          ),
        ];
      case 2: // Flowering & Tillering
        return [
          _AdvisoryItem(
            id: 301,
            emoji: '🌸',
            title: '$crop Critical Flowering Irrigation',
            description: 'Flowering is the most moisture-sensitive stage. Ensure light, frequent irrigation to prevent flower/bud drop.',
            priority: 'High',
            priorityColor: const Color(0xFFE63946),
            time: 'Live Update',
          ),
          _AdvisoryItem(
            id: 302,
            emoji: '🧪',
            title: '$crop Micronutrient & Boron Spray',
            description: 'Spray Soluble Boron (1.5g/L) + Phosphorous booster to promote healthy pollen tube growth and fruit set.',
            priority: 'Medium',
            priorityColor: const Color(0xFFF4A261),
            time: 'Today',
          ),
          _AdvisoryItem(
            id: 303,
            emoji: '🐝',
            title: '$crop Pollinator Safety & Weather Alert',
            description: 'Avoid high-pressure chemical sprays during daytime flowering hours to protect beneficial pollinators.',
            priority: 'Info',
            priorityColor: const Color(0xFF4CC9F0),
            time: 'Live Weather',
          ),
        ];
      case 3: // Fruit / Pod / Grain Formation
        return [
          _AdvisoryItem(
            id: 401,
            emoji: '🌾',
            title: '$crop Grain / Pod Weight Enhancement',
            description: 'Apply Sulphate of Potash (MOP/SOP 13:0:45) at 3g/L to increase test weight and pod/grain density.',
            priority: 'High',
            priorityColor: const Color(0xFFE63946),
            time: 'Today',
          ),
          _AdvisoryItem(
            id: 402,
            emoji: '💧',
            title: '$crop Pod/Fruit Filling Irrigation',
            description: 'Maintain steady moisture in root zone. Drought stress now will lead to shriveled grains or small fruit size.',
            priority: 'Medium',
            priorityColor: const Color(0xFFF4A261),
            time: '4h ago',
          ),
          _AdvisoryItem(
            id: 403,
            emoji: '🐛',
            title: '$crop Caterpillar & Blast Disease Guard',
            description: 'Monitor crop for pod borer or leaf blast spots. Apply biological bio-control or recommended fungicide at first sign.',
            priority: 'Info',
            priorityColor: const Color(0xFF4CC9F0),
            time: 'Yesterday',
          ),
        ];
      case 4: // Ripening & Maturation
        return [
          _AdvisoryItem(
            id: 501,
            emoji: '🍇',
            title: '$crop Irrigation Tapering & Stop Advisory',
            description: 'Stop irrigation 10-14 days before harvest to allow natural crop maturation and field drying.',
            priority: 'High',
            priorityColor: const Color(0xFFE63946),
            time: 'Today',
          ),
          _AdvisoryItem(
            id: 502,
            emoji: '☀️',
            title: '$crop Sun Drying & Maturity Check',
            description: 'Check grain/fruit moisture level. Ensure crop achieves golden-yellow color and uniform field ripening.',
            priority: 'Medium',
            priorityColor: const Color(0xFFF4A261),
            time: 'Yesterday',
          ),
          _AdvisoryItem(
            id: 503,
            emoji: '🌦️',
            title: '$crop Rain & Weather Protection',
            description: 'Monitor weather forecast for unseasonal rain. Plan early harvest if heavy precipitation is predicted.',
            priority: 'Info',
            priorityColor: const Color(0xFF4CC9F0),
            time: 'Live Weather',
          ),
        ];
      case 5: // Harvest & Post-Harvest
      default:
        return [
          _AdvisoryItem(
            id: 601,
            emoji: '🚜',
            title: '$crop Optimal Harvest Timing',
            description: 'Harvest crop when grain moisture is between 14-16%. Perform harvesting during dry morning hours.',
            priority: 'High',
            priorityColor: const Color(0xFFE63946),
            time: 'Live Update',
          ),
          _AdvisoryItem(
            id: 602,
            emoji: '📦',
            title: '$crop Threshing, Drying & Safe Storage',
            description: 'Sun-dry harvested produce on clean tarpaulins to 12% moisture. Treat storage bags with Neem oil or herbal bio-powder.',
            priority: 'Medium',
            priorityColor: const Color(0xFFF4A261),
            time: 'Today',
          ),
          _AdvisoryItem(
            id: 603,
            emoji: '🌾',
            title: '$crop Field Preparation for Next Season',
            description: 'Incorporate crop residue back into field with deep summer plowing to build soil organic matter.',
            priority: 'Info',
            priorityColor: const Color(0xFF4CC9F0),
            time: 'Yesterday',
          ),
        ];
    }
  }

  void _loadSchedule() async {
    if (user == null) return;
    setState(() => _isLoadingSchedule = true);
    final res = await ApiService.getFarmSchedule(user!.id);
    if (mounted) {
      setState(() {
        if (res.isNotEmpty) {
          _schedule = res.map((s) {
            String act = s['activity']?.toString() ?? '';
            IconData icon = Icons.event_note_rounded;
            Color color = const Color(0xFF9B59B6);
            if (act.toLowerCase().contains('irrigation') || act.toLowerCase().contains('water')) {
              icon = Icons.water_drop_rounded;
              color = const Color(0xFF4CC9F0);
            } else if (act.toLowerCase().contains('fertilizer') || act.toLowerCase().contains('urea') || act.toLowerCase().contains('npk')) {
              icon = Icons.science_rounded;
              color = const Color(0xFF9B59B6);
            } else if (act.toLowerCase().contains('weed') || act.toLowerCase().contains('harvest')) {
              icon = Icons.grass_rounded;
              color = const Color(0xFF2D6A4F);
            } else if (act.toLowerCase().contains('test') || act.toLowerCase().contains('soil')) {
              icon = Icons.biotech_rounded;
              color = const Color(0xFFF4A261);
            }
            
            return _ScheduleItem(
              id: s['id'],
              activity: act,
              time: s['scheduled_at'] ?? '',
              icon: icon,
              color: color,
              status: s['status'] ?? 'pending',
            );
          }).toList();
        } else {
          _schedule = [
            const _ScheduleItem(id: 1, activity: 'Irrigation', time: 'Tomorrow, 6 AM', icon: Icons.water_drop_rounded, color: Color(0xFF4CC9F0), status: 'pending'),
            const _ScheduleItem(id: 2, activity: 'Spray Urea', time: 'Thu, 7 AM', icon: Icons.science_rounded, color: Color(0xFF9B59B6), status: 'pending'),
            const _ScheduleItem(id: 3, activity: 'Weeding', time: 'Sat, 6:30 AM', icon: Icons.grass_rounded, color: Color(0xFF2D6A4F), status: 'completed'),
            const _ScheduleItem(id: 4, activity: 'Soil Test', time: 'Next Mon', icon: Icons.biotech_rounded, color: Color(0xFFF4A261), status: 'pending'),
          ];
        }
        _isLoadingSchedule = false;
      });
    }
  }

  void _askAI() {
    final cropName = _crops[_selectedCropIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIAssistantScreen(initialCrop: cropName),
      ),
    ).then((_) => _loadAdvisories());
  }

  void _showCropSearchModal() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCrops = _allCropPlants.where((c) {
              final q = searchQuery.toLowerCase().trim();
              if (q.isEmpty) return true;
              return c['name']!.toLowerCase().contains(q) ||
                  c['category']!.toLowerCase().contains(q);
            }).toList();

            final bool exactMatchFound = _allCropPlants.any(
                (c) => c['name']!.toLowerCase().trim() == searchQuery.toLowerCase().trim());

            return Container(
              height: MediaQuery.of(ctx).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Search & Select Crop Plant'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4332),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.black54),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    autofocus: true,
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Type to search crop (e.g. Paddy, Tomato, Dragon Fruit...)'.tr,
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => setModalState(() => searchQuery = ''),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (searchQuery.trim().isNotEmpty && !exactMatchFound) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: ListTile(
                        onTap: () {
                          final newCropName = searchQuery.trim();
                          setState(() {
                            if (!_crops.contains(newCropName)) {
                              _crops.insert(0, newCropName);
                              _selectedCropIndex = 0;
                            } else {
                              _selectedCropIndex = _crops.indexOf(newCropName);
                            }
                          });
                          Navigator.pop(ctx);
                          _loadAdvisories();
                        },
                        leading: const Icon(Icons.add_circle_rounded, color: AppTheme.primary, size: 28),
                        title: Text(
                          'Select "${searchQuery.trim()}"'.tr,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        subtitle: Text(
                          'Tap to generate custom advisory for this crop plant'.tr,
                          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primary, size: 16),
                      ),
                    ),
                  ],

                  Expanded(
                    child: filteredCrops.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.agriculture_rounded, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'No pre-listed crop matching "$searchQuery"'.tr,
                                  style: const TextStyle(color: Colors.grey, fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredCrops.length,
                            itemBuilder: (context, idx) {
                              final item = filteredCrops[idx];
                              final cropName = item['name']!.split('/')[0].trim();
                              final isSelected = _crops[_selectedCropIndex].toLowerCase() == cropName.toLowerCase();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: ListTile(
                                  onTap: () {
                                    setState(() {
                                      if (!_crops.contains(cropName)) {
                                        _crops.insert(0, cropName);
                                        _selectedCropIndex = 0;
                                      } else {
                                        _selectedCropIndex = _crops.indexOf(cropName);
                                      }
                                    });
                                    Navigator.pop(ctx);
                                    _loadAdvisories();
                                  },
                                  leading: Text(item['emoji']!, style: const TextStyle(fontSize: 24)),
                                  title: Text(
                                    item['name']!.tr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppTheme.primary : const Color(0xFF1B4332),
                                      fontSize: 14,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  subtitle: Text(
                                    item['category']!.tr,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 22)
                                      : const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStagePickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.spa_rounded, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Select Growth Stage (All 6 Stages)'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.black54),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _growthStages.length,
                  itemBuilder: (context, idx) {
                    final stg = _growthStages[idx];
                    final isSelected = _selectedStageIndex == idx;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedStageIndex = idx;
                          });
                          Navigator.pop(ctx);
                          _loadAdvisories();
                        },
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(stg['icon']!, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              stg['code']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.primary : Colors.grey.shade600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stg['stage']!.tr,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.primary : const Color(0xFF1B4332),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            stg['desc']!.tr,
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontFamily: 'Poppins'),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 24)
                            : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addActivity() async {
    if (user == null) return;
    final activityCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 6, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Farm Activity'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: activityCtrl,
                decoration: InputDecoration(labelText: 'Activity Name'.tr, hintText: 'e.g. Watering, Fertilizer spray'.tr),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_month, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final dt = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (dt != null) {
                        setDialogState(() => selectedDate = dt);
                      }
                    },
                    child: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final tod = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (tod != null) {
                        setDialogState(() => selectedTime = tod);
                      }
                    },
                    child: Text(selectedTime.format(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel'.tr)),
          ElevatedButton(
            onPressed: () async {
              if (activityCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                final monthStr = selectedDate.month.toString().padLeft(2, '0');
                final dayStr = selectedDate.day.toString().padLeft(2, '0');
                final hourStr = selectedTime.hour.toString().padLeft(2, '0');
                final minStr = selectedTime.minute.toString().padLeft(2, '0');
                final timeStr = '${selectedDate.year}-$monthStr-$dayStr $hourStr:$minStr';

                final res = await ApiService.addFarmSchedule(
                  userId: user!.id,
                  activity: activityCtrl.text,
                  scheduledAt: timeStr,
                );
                if (res['success'] == true) {
                  _loadSchedule();
                }
              }
            },
            child: Text('Save'.tr),
          ),
        ],
      ),
    );
  }

  void _showActivityActions(_ScheduleItem item) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              item.status == 'completed' ? Icons.pending_actions_rounded : Icons.check_circle_rounded,
              color: item.status == 'completed' ? Colors.orange : Colors.green,
            ),
            title: Text(item.status == 'completed' ? 'Mark as Pending'.tr : 'Mark as Completed'.tr),
            onTap: () async {
              Navigator.pop(ctx);
              final newStatus = item.status == 'completed' ? 'pending' : 'completed';
              final res = await ApiService.updateScheduleStatus(item.id, newStatus);
              if (res['success'] == true) {
                _loadSchedule();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: Text('Delete Activity'.tr),
            onTap: () async {
              Navigator.pop(ctx);
              final res = await ApiService.deleteFarmSchedule(item.id);
              if (res['success'] == true) {
                _loadSchedule();
              }
            },
          ),
        ],
      ),
    );
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
      body: NestedScrollView(
        headerSliverBuilder: (_, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeader()),
        ],
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
                tabs: [
                  Tab(text: 'Advisory'.tr),
                  Tab(text: 'Schedule'.tr),
                  Tab(text: 'History'.tr),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAdvisoryTab(),
                  _buildScheduleTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _askAI,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        label: Text(
          'Ask AI'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final activeStage = _growthStages[_selectedStageIndex];
    final activeCrop = _crops[_selectedCropIndex];

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                'Crop Advisory'.tr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      ((user?.district != null && (user?.district?.isNotEmpty ?? false))
                              ? '${user?.district}, ${user?.state ?? ''}'
                              : (user?.state ?? 'Andhra Pradesh')).tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Prominent Search & Select Crop Plant Bar
          GestureDetector(
            onTap: _showCropSearchModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: AppTheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search & Select Crop Plant ($activeCrop)...'.tr,
                      style: const TextStyle(
                        color: Color(0xFF1B4332),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.manage_search_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Search'.tr,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Universal Crop selector pills + Search trigger
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length + 1,
              itemBuilder: (_, i) {
                if (i == _crops.length) {
                  return GestureDetector(
                    onTap: _showCropSearchModal,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text('Search All Crops'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                final selected = _selectedCropIndex == i;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCropIndex = i;
                    });
                    _loadAdvisories();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _crops[i].tr,
                      style: TextStyle(
                        color: selected ? AppTheme.primary : Colors.white,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Crop stats & stage selector trigger row
          Row(
            children: [
              _CropStat(
                'Growth Stage'.tr,
                '${activeStage['code']} ${activeStage['icon']}'.tr,
                Icons.spa_rounded,
                onTap: _showStagePickerModal,
              ),
              _divider(),
              _CropStat(
                'Health Score'.tr,
                activeStage['health']!.tr,
                Icons.favorite_rounded,
              ),
              _divider(),
              _CropStat(
                'Next Action'.tr,
                activeStage['next_action']!.tr,
                Icons.alarm_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 32,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Colors.white.withValues(alpha: 0.25),
  );

  Widget _buildAdvisoryTab() {
    final activeCrop = _crops[_selectedCropIndex];
    final activeStage = _growthStages[_selectedStageIndex];

    return _isLoadingAdvisories
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadAdvisories();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 6 Growth Stages quick selector bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Select Plant Growth Stage (6 Stages)'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _showStagePickerModal,
                          child: Text('View All'.tr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _growthStages.length,
                        itemBuilder: (context, idx) {
                          final stg = _growthStages[idx];
                          final isSelected = _selectedStageIndex == idx;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStageIndex = idx;
                              });
                              _loadAdvisories();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF1B4332) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF1B4332) : Colors.grey.shade300,
                                ),
                                boxShadow: isSelected
                                    ? [BoxShadow(color: const Color(0xFF1B4332).withValues(alpha: 0.3), blurRadius: 6)]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Text(stg['icon']!, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    stg['code']!,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF1B4332),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Weather & Crop Health Conditions Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🤖 AI Crop & Weather Advisory'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$activeCrop is in ${activeStage['code']}: ${activeStage['stage']}'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Text(activeStage['icon']!, style: const TextStyle(fontSize: 24)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _WeatherMetric('🌡️ Temp', '31°C'),
                            _WeatherMetric('💧 Humidity', '72%'),
                            _WeatherMetric('🌧️ Rain Forecast', '35%'),
                            _WeatherMetric('🌱 Soil Moisture', '64%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stage-Specific Advisories Header
                Row(
                  children: [
                    Text(
                      'Stage Recommendations for $activeCrop'.tr,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B4332),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activeStage['code']!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ..._advisories.map((a) => _AdvisoryCard(item: a)),
              ],
            ),
          );
  }

  Widget _WeatherMetric(String label, String val) {
    return Column(
      children: [
        Text(label.tr, style: const TextStyle(fontSize: 10, color: Colors.white70, fontFamily: 'Poppins')),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Poppins')),
      ],
    );
  }

  Widget _buildScheduleTab() {
    return _isLoadingSchedule
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadSchedule();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming Activities'.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addActivity,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text('Add Task'.tr),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ..._schedule.map((s) => GestureDetector(
                      onTap: () => _showActivityActions(s),
                      child: _ScheduleCard(item: s),
                    )),
              ],
            ),
          );
  }

  Widget _buildHistoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Advisory History'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppTheme.textLight),
              const SizedBox(height: 10),
              Text(
                'No past advisories logged yet.'.tr,
                style: TextStyle(color: AppTheme.textSecondary, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CropStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  const _CropStat(this.label, this.value, this.icon, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  final _AdvisoryItem item;
  const _AdvisoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
        border: Border(
          left: BorderSide(color: item.priorityColor, width: 3),
        ),
      ),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.priority.tr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: item.priorityColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.description.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.time.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
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

class _ScheduleCard extends StatelessWidget {
  final _ScheduleItem item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
        border: isCompleted ? Border.all(color: Colors.green.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withValues(alpha: 0.1) : item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isCompleted ? Icons.check_circle_rounded : item.icon, color: isCompleted ? Colors.green : item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activity.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.grey : AppTheme.textPrimary,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 12, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      item.time.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted ? Colors.grey : AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.more_vert_rounded, color: AppTheme.textLight),
        ],
      ),
    );
  }
}

class _AdvisoryItem {
  final dynamic id;
  final String emoji, title, description, priority, time;
  final Color priorityColor;
  const _AdvisoryItem({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.priority,
    required this.priorityColor,
    required this.time,
  });
}

class _ScheduleItem {
  final dynamic id;
  final String activity, time;
  final IconData icon;
  final Color color;
  final String status;
  const _ScheduleItem({
    required this.id,
    required this.activity,
    required this.time,
    required this.icon,
    required this.color,
    required this.status,
  });
}
