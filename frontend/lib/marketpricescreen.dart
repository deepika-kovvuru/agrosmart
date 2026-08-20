// market_screen.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'offline_api_service.dart';
import 'connectivity_service.dart';
import 'user_session.dart';
import 'translation_provider.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _selectedCategory = 0;
  String? _selectedState;
  String _selectedMandi = 'All Mandis';
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;
  bool _hasError = false;

  final List<String> _categories = [
    'All', 'Cereals', 'Pulses', 'Oilseed', 'Vegetables', 'Fruits'
  ];

  List<String> _states = [];
  List<String> _mandis = ['All Mandis'];
  List<dynamic> _mandiPrices = []; // List of mandis with nested crop prices
  String _lastUpdatedText = '';

  @override
  void initState() {
    super.initState();
    _initializeStatesAndData();
  }

  void _initializeStatesAndData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // 1. Fetch available states
    final statesResult = await OfflineApiService.getStates();
    if (mounted) {
      setState(() {
        if (statesResult['success'] == true && statesResult['data'] != null) {
          final List<dynamic> data = statesResult['data'];
          _states = data.map((s) => s['state_name'].toString()).toList();
        } else {
          // Fallback static list of Indian states
          _states = [
            'Andhra Pradesh', 'Telangana', 'Karnataka', 'Tamil Nadu', 
            'Maharashtra', 'Kerala', 'Odisha', 'West Bengal', 'Gujarat', 
            'Rajasthan', 'Punjab', 'Haryana', 'Uttar Pradesh', 'Madhya Pradesh', 
            'Bihar', 'Chhattisgarh', 'Jharkhand', 'Assam'
          ];
        }

        // Auto-select user's state or fallback
        final String? userState = UserSession.currentUser?.state;
        if (userState != null && _states.contains(userState)) {
          _selectedState = userState;
        } else if (_states.isNotEmpty) {
          _selectedState = _states.first;
        }
      });
    }

    // 2. Load mandi prices for selected state
    await _loadStateMandisAndPrices();
  }

  Future<void> _loadStateMandisAndPrices() async {
    if (_selectedState == null) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // 1. Fetch mandis for selected state
    final mandisResult = await OfflineApiService.getMandisByState(_selectedState!);
    if (mounted && mandisResult['success'] == true && mandisResult['data'] != null) {
      final List<dynamic> data = mandisResult['data'];
      setState(() {
        _mandis = ['All Mandis'] + data.map((m) => m['mandi_name'].toString()).toList();
        if (!_mandis.contains(_selectedMandi)) {
          _selectedMandi = 'All Mandis';
        }
      });
    } else {
      setState(() {
        _mandis = ['All Mandis'];
        _selectedMandi = 'All Mandis';
      });
    }

    // 2. Fetch prices
    final String? mandiFilter = _selectedMandi == 'All Mandis' ? null : _selectedMandi;
    final pricesResult = await OfflineApiService.getMarketPricesByState(
      state: _selectedState,
      mandi: mandiFilter,
    );

    if (mounted) {
      setState(() {
        if (pricesResult['success'] == true && pricesResult['data'] != null) {
          _mandiPrices = pricesResult['data']['mandis'] as List<dynamic>? ?? [];
          _hasError = false;

          // Set last updated time from first available price record
          if (_mandiPrices.isNotEmpty) {
            final List<dynamic> firstPrices = _mandiPrices.first['prices'] as List<dynamic>? ?? [];
            if (firstPrices.isNotEmpty) {
              _lastUpdatedText = 'Last updated: ${firstPrices.first['updated_at']}';
            } else {
              _lastUpdatedText = 'Updated: Today';
            }
          } else {
            _lastUpdatedText = 'No price update';
          }
        } else {
          _mandiPrices = [];
          _hasError = pricesResult['error'] != null;
        }
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getFilteredMandiPrices() {
    final String query = _searchCtrl.text.toLowerCase();
    final String category = _categories[_selectedCategory];

    List<dynamic> filtered = [];

    for (var m in _mandiPrices) {
      final List<dynamic> rawPrices = m['prices'] as List<dynamic>? ?? [];
      final List<dynamic> filteredPrices = rawPrices.where((p) {
        final String cropName = p['crop']?.toString().toLowerCase() ?? '';
        final String cropCat = p['category']?.toString().toLowerCase() ?? '';
        
        final matchesQuery = query.isEmpty || cropName.contains(query);
        final matchesCategory = category == 'All' || cropCat == category.toLowerCase();
        
        return matchesQuery && matchesCategory;
      }).toList();

      if (filteredPrices.isNotEmpty) {
        filtered.add({
          'mandi_name': m['mandi_name'],
          'district': m['district'],
          'prices': filteredPrices,
        });
      }
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMandis = _getFilteredMandiPrices();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildStatsRow(filteredMandis)),
          SliverToBoxAdapter(child: _buildSearchAndFilter()),
          
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              : _hasError
                  ? SliverToBoxAdapter(
                      child: _buildErrorState('Unable to retrieve market prices. Please try again.'.tr),
                    )
                  : _mandiPrices.isEmpty
                      ? SliverToBoxAdapter(
                          child: _buildErrorState('Market information is currently unavailable for this state.'.tr),
                        )
                      : filteredMandis.isEmpty
                          ? SliverToBoxAdapter(
                              child: _buildErrorState('No matching commodities found.'.tr),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (_, i) => _MandiCard(mandiData: filteredMandis[i]),
                                  childCount: filteredMandis.length,
                                ),
                              ),
                            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.info_outline_rounded, size: 48, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E4620), Color(0xFF2D6A4F), Color(0xFF40916C)],
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
                child: const Icon(Icons.arrow_back_ios_new_rounded,
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
              ValueListenableBuilder<bool>(
                valueListenable: ConnectivityService.instance.isOnline,
                builder: (context, isOnline, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: isOnline ? const Color(0xFF69F0AE) : Colors.orange, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Live'.tr : 'Offline'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dropdowns layout
          Row(
            children: [
              // State Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E4620),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _states.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text(s.tr),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedState = val;
                            _selectedMandi = 'All Mandis';
                          });
                          _loadStateMandisAndPrices();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Mandi Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMandi,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E4620),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      items: _mandis.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m.tr),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedMandi = val;
                          });
                          _loadStateMandisAndPrices();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Text(
            _lastUpdatedText.tr,
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

  Widget _buildStatsRow(List<dynamic> mandis) {
    int rising = 0;
    int falling = 0;
    int stable = 0;

    for (var m in mandis) {
      final List<dynamic> prices = m['prices'] as List<dynamic>? ?? [];
      for (var p in prices) {
        final trend = p['trend']?.toString().toUpperCase() ?? 'STABLE';
        if (trend == 'RISING') {
          rising++;
        } else if (trend == 'FALLING') {
          falling++;
        } else {
          stable++;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _StatChip('↑ $rising', 'Rising'.tr, const Color(0xFF2D6A4F), const Color(0xFFE8F5E9)),
          const SizedBox(width: 8),
          _StatChip('↓ $falling', 'Falling'.tr, AppTheme.error, const Color(0xFFFFEBEE)),
          const SizedBox(width: 8),
          _StatChip('= $stable', 'Stable'.tr, AppTheme.accentGold, const Color(0xFFFFF8E1)),
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
                Icon(Icons.search_rounded, color: AppTheme.textLight, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() {}),
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
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
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

class _MandiCard extends StatelessWidget {
  final Map<String, dynamic> mandiData;
  const _MandiCard({required this.mandiData});

  @override
  Widget build(BuildContext context) {
    final String name = mandiData['mandi_name'] ?? 'Mandi';
    final String district = mandiData['district'] ?? '';
    final List<dynamic> prices = mandiData['prices'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandi Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.store_mall_directory_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (district.isNotEmpty)
                        Text(
                          district.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mandi prices items list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: prices.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            itemBuilder: (_, i) => _PriceItemTile(mandiName: name, priceData: prices[i]),
          ),
        ],
      ),
    );
  }
}

class _PriceItemTile extends StatefulWidget {
  final String mandiName;
  final Map<String, dynamic> priceData;
  const _PriceItemTile({required this.mandiName, required this.priceData});

  @override
  State<_PriceItemTile> createState() => _PriceItemTileState();
}

class _PriceItemTileState extends State<_PriceItemTile> {
  bool _isExpanded = false;
  bool _isLoadingHistory = false;
  List<dynamic> _priceHistory = [];
  int _historyDays = 30;

  void _fetchHistory() async {
    if (_priceHistory.isNotEmpty) return;
    setState(() => _isLoadingHistory = true);

    final crop = widget.priceData['crop'] ?? '';
    final result = await OfflineApiService.getPriceHistory(widget.mandiName, crop, days: 30);
    
    if (mounted) {
      setState(() {
        if (result['success'] == true && result['data'] != null) {
          _priceHistory = result['data'] as List<dynamic>? ?? [];
        }
        _isLoadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String crop = widget.priceData['crop'] ?? 'Crop';
    final double current = (widget.priceData['current_price'] as num).toDouble();
    final double minPrice = (widget.priceData['minimum_price'] as num).toDouble();
    final double maxPrice = (widget.priceData['maximum_price'] as num).toDouble();
    final double change = (widget.priceData['price_change'] as num).toDouble();
    final double pctChange = (widget.priceData['percentage_change'] as num).toDouble();
    final String trend = widget.priceData['trend']?.toString().toUpperCase() ?? 'STABLE';
    final String unit = widget.priceData['unit'] ?? '₹/quintal';

    String emoji = '🌾';
    if (crop.toLowerCase().contains('maize')) emoji = '🌽';
    if (crop.toLowerCase().contains('groundnut')) emoji = '🥜';
    if (crop.toLowerCase().contains('soybean')) emoji = '🫘';
    if (crop.toLowerCase().contains('chilli')) emoji = '🌶️';
    if (crop.toLowerCase().contains('onion')) emoji = '🧅';
    if (crop.toLowerCase().contains('turmeric')) emoji = '🌿';
    if (crop.toLowerCase().contains('tomato')) emoji = '🍅';
    if (crop.toLowerCase().contains('wheat')) emoji = '🌾';

    final Color trendColor = trend == 'RISING'
        ? AppTheme.success
        : trend == 'FALLING'
            ? AppTheme.error
            : AppTheme.accentGold;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
            if (_isExpanded) {
              _fetchHistory();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.transparent,
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        'Min: ₹${minPrice.toStringAsFixed(0)} | Max: ₹${maxPrice.toStringAsFixed(0)}'.tr,
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
                      '₹${current.toStringAsFixed(0)} / ${unit.tr}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trend == 'RISING'
                              ? Icons.arrow_upward_rounded
                              : trend == 'FALLING'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.trending_flat_rounded,
                          color: trendColor,
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '₹${change.abs().toStringAsFixed(0)} (${pctChange >= 0 ? '+' : ''}${pctChange.toStringAsFixed(2)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: Colors.grey.withValues(alpha: 0.12)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price History'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Row(
                      children: [1, 7, 30].map((d) {
                        final isSelected = _historyDays == d;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _historyDays = d;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              d == 1 ? '1 Day'.tr : '$d Days'.tr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoadingHistory
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : _PriceHistoryChart(historyData: _priceHistory, days: _historyDays),
              ],
            ),
          ),
      ],
    );
  }
}

class _PriceHistoryChart extends StatelessWidget {
  final List<dynamic> historyData;
  final int days;

  const _PriceHistoryChart({required this.historyData, required this.days});

  @override
  Widget build(BuildContext context) {
    if (historyData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Price information is currently unavailable for this mandi.'.tr,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    final filteredData = historyData.length > days
        ? historyData.sublist(historyData.length - days)
        : historyData;

    final prices = filteredData.map((d) => (d['price'] as num).toDouble()).toList();
    final double maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final double minPrice = prices.reduce((a, b) => a < b ? a : b);
    final double latestPrice = prices.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modal Price (Current)'.tr, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                Text(
                  '₹${latestPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Min / Max (Period)'.tr, style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                Text(
                  '₹${minPrice.toStringAsFixed(0)} - ₹${maxPrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          width: double.infinity,
          child: CustomPaint(
            painter: _LineChartPainter(
              prices: prices,
              minPrice: minPrice,
              maxPrice: maxPrice,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              filteredData.first['date'].toString(),
              style: TextStyle(fontSize: 9, color: AppTheme.textLight),
            ),
            Text(
              filteredData.last['date'].toString(),
              style: TextStyle(fontSize: 9, color: AppTheme.textLight),
            ),
          ],
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> prices;
  final double minPrice;
  final double maxPrice;

  _LineChartPainter({required this.prices, required this.minPrice, required this.maxPrice});

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paintLine = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintArea = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final areaPath = Path();

    final double widthStep = size.width / (prices.length - 1);
    final double priceRange = maxPrice - minPrice == 0 ? 1 : maxPrice - minPrice;

    Offset getOffset(int index) {
      final double x = index * widthStep;
      final double y = size.height - ((prices[index] - minPrice) / priceRange) * (size.height - 12) - 6;
      return Offset(x, y);
    }

    final startOffset = getOffset(0);
    path.moveTo(startOffset.dx, startOffset.dy);
    areaPath.moveTo(startOffset.dx, size.height);
    areaPath.lineTo(startOffset.dx, startOffset.dy);

    for (int i = 1; i < prices.length; i++) {
      final offset = getOffset(i);
      path.lineTo(offset.dx, offset.dy);
      areaPath.lineTo(offset.dx, offset.dy);
    }

    areaPath.lineTo(getOffset(prices.length - 1).dx, size.height);
    areaPath.close();

    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppTheme.primary.withValues(alpha: 0.35),
        AppTheme.primary.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    paintArea.shader = shader;

    canvas.drawPath(areaPath, paintArea);
    canvas.drawPath(path, paintLine);

    final dotPaint = Paint()..color = AppTheme.primary..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0;

    final lastOffset = getOffset(prices.length - 1);
    canvas.drawCircle(lastOffset, 5.0, dotPaint);
    canvas.drawCircle(lastOffset, 5.0, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.prices != prices || oldDelegate.minPrice != minPrice || oldDelegate.maxPrice != maxPrice;
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 10,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
