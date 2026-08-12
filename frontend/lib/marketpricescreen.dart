// market_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'api_service.dart';
import 'translation_provider.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _selectedCategory = 0;
  String _selectedMandi = 'Kurnool Mandi';
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;

  final List<String> _categories = [
    'All', 'Cereals', 'Pulses', 'Oilseed', 'Vegetables', 'Fruits'
  ];

  List<String> _mandis = [
    'Kurnool Mandi',
    'Hyderabad Mandi',
    'Vijayawada Mandi',
    'Guntur Mandi',
  ];

  List<_CommodityPrice> _prices = [];

  @override
  void initState() {
    super.initState();
    _loadMarketData();
  }

  void _loadMarketData() async {
    setState(() => _isLoading = true);
    
    // Fetch live mandis
    final liveMandis = await ApiService.getMandis();
    if (mounted && liveMandis.isNotEmpty) {
      setState(() {
        _mandis = liveMandis.map((m) => m.contains('Mandi') ? m : '$m Mandi').toList();
        if (!_mandis.contains(_selectedMandi)) {
          _selectedMandi = _mandis.first;
        }
      });
    }

    // Fetch live prices for selected mandi (backend uses raw names, strip ' Mandi')
    final String cleanMandi = _selectedMandi.replaceAll(' Mandi', '');
    final String category = _categories[_selectedCategory];
    final livePrices = await ApiService.getMarketPrices(
      mandi: cleanMandi,
      category: category,
    );

    if (mounted) {
      setState(() {
        if (livePrices.isNotEmpty) {
          _prices = livePrices.map((p) {
            String name = p['commodity'] ?? '';
            String emoji = '🌾';
            if (name.toLowerCase().contains('maize')) emoji = '🌽';
            if (name.toLowerCase().contains('groundnut')) emoji = '🥜';
            if (name.toLowerCase().contains('soybean')) emoji = '🫘';
            if (name.toLowerCase().contains('chilli')) emoji = '🌶️';
            if (name.toLowerCase().contains('onion')) emoji = '🧅';
            if (name.toLowerCase().contains('turmeric')) emoji = '🌿';
            if (name.toLowerCase().contains('tomato')) emoji = '🍅';
            if (name.toLowerCase().contains('wheat')) emoji = '🌾';

            return _CommodityPrice(
              emoji,
              name,
              p['category'] ?? 'Cereals',
              '₹${p['price'].toString().split('.')[0]}',
              '₹${p['prev_price'].toString().split('.')[0]}',
              (p['change'] as num).toInt(),
              p['is_up'] == true,
              p['unit'] ?? 'qtl',
            );
          }).toList();
        } else {
          // fallback mock data
          _prices = const [
            _CommodityPrice('🌾', 'Paddy (Fine)', 'Cereals', '₹2,180', '₹2,140', 40, true, 'qtl'),
            _CommodityPrice('🌽', 'Maize', 'Cereals', '₹1,820', '₹1,835', -15, false, 'qtl'),
            _CommodityPrice('🥜', 'Groundnut', 'Oilseed', '₹5,640', '₹5,560', 80, true, 'qtl'),
            _CommodityPrice('🫘', 'Soybean', 'Oilseed', '₹4,120', '₹4,095', 25, true, 'qtl'),
            _CommodityPrice('🌶️', 'Red Chilli (Dry)', 'Vegetables', '₹14,200', '₹14,400', -200, false, 'qtl'),
            _CommodityPrice('🧅', 'Onion', 'Vegetables', '₹1,240', '₹1,180', 60, true, 'qtl'),
            _CommodityPrice('🌿', 'Turmeric', 'Oilseed', '₹7,800', '₹7,650', 150, true, 'qtl'),
            _CommodityPrice('🍅', 'Tomato', 'Vegetables', '₹680', '₹720', -40, false, 'qtl'),
          ];
        }
        
        // Apply category filter locally if mock data is used
        if (livePrices.isEmpty && _selectedCategory > 0) {
          _prices = _prices.where((p) => p.category.toLowerCase() == category.toLowerCase()).toList();
        }
        
        // Apply search query filter if search text is present
        if (_searchCtrl.text.isNotEmpty) {
          _prices = _prices.where((p) => p.name.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();
        }

        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildStatsRow()),
          SliverToBoxAdapter(child: _buildSearchAndFilter()),
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _PriceCard(item: _prices[i]),
                      childCount: _prices.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
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
                'Market Prices'.tr,
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
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF69F0AE), size: 8),
                    SizedBox(width: 4),
                    Text(
                      'Live'.tr,
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

          // Mandi selector
          Row(
            children: [
              Icon(Icons.store_mall_directory_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMandi,
                  dropdownColor: const Color(0xFF283593),
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70, size: 18),
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: _mandis
                      .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m.tr),
                  ))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedMandi = v!;
                    });
                    _loadMarketData();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            'Updated: Today 9:15 AM  ·  Thursday, 21 May 2026'.tr,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    int rising = _prices.where((element) => element.isUp).length;
    int falling = _prices.where((element) => !element.isUp).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip('↑ $rising', 'Rising'.tr, const Color(0xFF2D6A4F),
              const Color(0xFFE8F5E9)),
          const SizedBox(width: 8),
          _StatChip('↓ $falling', 'Falling'.tr, AppTheme.error,
              const Color(0xFFFFEBEE)),
          const SizedBox(width: 8),
          _StatChip('= 0', 'Stable'.tr, AppTheme.accentGold,
              const Color(0xFFFFF8E1)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // Search
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                )
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search_rounded,
                    color: AppTheme.textLight, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => _loadMarketData(),
                    decoration: InputDecoration(
                      hintText: 'Search commodity...'.tr,
                      hintStyle: TextStyle(
                        color: AppTheme.textLight,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      filled: false,
                    ),
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = i;
                  });
                  _loadMarketData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedCategory == i
                        ? const Color(0xFF1A237E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedCategory == i
                          ? const Color(0xFF1A237E)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    _categories[i].tr,
                    style: TextStyle(
                      color: _selectedCategory == i
                          ? Colors.white
                          : AppTheme.textSecondary,
                      fontWeight: _selectedCategory == i
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 12,
                      fontFamily: 'Poppins',
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
}

class _PriceCard extends StatelessWidget {
  final _CommodityPrice item;
  const _PriceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Text(item.emoji, style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name.tr,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  item.category.tr,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.price}/${item.unit.tr}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.isUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: item.isUp ? AppTheme.success : AppTheme.error,
                    size: 13,
                  ),
                  Text(
                    '₹${item.change.abs()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: item.isUp ? AppTheme.success : AppTheme.error,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String count, label;
  final Color color, bgColor;
  const _StatChip(this.count, this.label, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommodityPrice {
  final String emoji, name, category, price, prevPrice, unit;
  final int change;
  final bool isUp;
  const _CommodityPrice(this.emoji, this.name, this.category, this.price,
      this.prevPrice, this.change, this.isUp, this.unit);
}
