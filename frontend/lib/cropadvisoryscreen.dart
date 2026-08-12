// crop_advisory_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'user_session.dart';
import 'translation_provider.dart';

class CropAdvisoryScreen extends StatefulWidget {
  const CropAdvisoryScreen({super.key});

  @override
  State<CropAdvisoryScreen> createState() => _CropAdvisoryScreenState();
}

class _CropAdvisoryScreenState extends State<CropAdvisoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCrop = 0;
  bool _isLoadingAdvisories = true;
  bool _isLoadingSchedule = true;

  final List<String> _crops = ['Paddy', 'Maize', 'Groundnut', 'Cotton', 'Soybean'];

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
    if (user == null) return;
    setState(() => _isLoadingAdvisories = true);
    final cropName = _crops[_selectedCrop];
    final res = await ApiService.getCropAdvisories(user!.id, crop: cropName);
    
    if (mounted) {
      setState(() {
        if (res.isNotEmpty) {
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
        } else {
          // fallback mock data
          _advisories = [
            _AdvisoryItem(
              id: 1,
              emoji: '💧',
              title: '$cropName Irrigation',
              description: 'Soil moisture is optimal at 62%. Irrigate within 2 days for best yield.',
              priority: 'Medium',
              priorityColor: const Color(0xFFF4A261),
              time: '2h ago',
            ),
            _AdvisoryItem(
              id: 2,
              emoji: '🌿',
              title: '$cropName Fertilizer Schedule',
              description: 'Apply 2nd dose of NPK (20:20:0) — 40 kg/acre this week.',
              priority: 'High',
              priorityColor: const Color(0xFFE63946),
              time: 'Today',
            ),
            _AdvisoryItem(
              id: 3,
              emoji: '☀️',
              title: '$cropName Growth Stage Update',
              description: 'Crop at vegetative stage. Expect flowering in 18 days.',
              priority: 'Info',
              priorityColor: const Color(0xFF4CC9F0),
              time: 'Yesterday',
            ),
          ];
        }
        _isLoadingAdvisories = false;
      });
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
          // fallback mock schedule
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

  void _askAI() async {
    if (user == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating AI advisory recommendations...'.tr), backgroundColor: AppTheme.primary),
    );
    final cropName = _crops[_selectedCrop];
    final res = await ApiService.addCropAdvisory(
      userId: user!.id,
      crop: cropName,
      title: '$cropName Disease Prevention'.tr,
      description: 'Humid weather may promote bacterial blight. Spray Pseudomonas fluorescens @ 10g/L to protect crop leaves.'.tr,
      emoji: '🔬',
      priority: 'Medium',
    );
    if (res['success'] == true) {
      _loadAdvisories();
    }
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
                labelStyle: TextStyle(
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
        icon: Icon(Icons.auto_awesome_rounded, color: Colors.white),
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
                child: Icon(Icons.arrow_back_ios_new_rounded,
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
                    Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      (user?.state ?? 'Kurnool').tr,
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
          const SizedBox(height: 20),

          // Crop selector
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _crops.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCrop = i;
                  });
                  _loadAdvisories();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCrop == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCrop == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _crops[i].tr,
                    style: TextStyle(
                      color: _selectedCrop == i
                          ? AppTheme.primary
                          : Colors.white,
                      fontWeight: _selectedCrop == i
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Crop stats row
          Row(
            children: [
              _CropStat('Growth Stage'.tr, 'Vegetative V5'.tr, Icons.spa_rounded),
              _divider(),
              _CropStat('Health Score'.tr, '87/100 🟢'.tr, Icons.favorite_rounded),
              _divider(),
              _CropStat('Next Action'.tr, 'Irrigate'.tr, Icons.alarm_rounded),
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
    return _isLoadingAdvisories
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadAdvisories();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🤖 AI Recommendation'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Based on current weather & soil data, your ${_crops[_selectedCrop].tr} crop needs attention.'.tr,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.5,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text('🌾', style: TextStyle(fontSize: 28)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ..._advisories.map((a) => _AdvisoryCard(item: a)),
              ],
            ),
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
                Text(
                  'Upcoming Farm Activities'.tr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 14),
                ..._schedule.map((s) => GestureDetector(
                      onTap: () => _showActivityActions(s),
                      child: _ScheduleCard(item: s),
                    )),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _addActivity,
                  icon: Icon(Icons.add_rounded, color: AppTheme.primary, size: 18),
                  label: Text(
                    'Add Activity'.tr,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildHistoryTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📋', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            'Advisory History'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Past 30 days of ${_crops[_selectedCrop].tr} farm activity\nand AI recommendations'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CropStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _CropStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
        ],
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
          Text(item.emoji, style: TextStyle(fontSize: 28)),
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
