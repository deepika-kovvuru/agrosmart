import 'app_theme.dart';
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'translation_provider.dart';

// ─────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────

class NewsArticle {
  final String id;
  final String category;
  final String title;
  final String summary;
  final String source;
  final String timeAgo;
  final String imageEmoji;
  final Color categoryColor;
  final bool isFeatured;

  const NewsArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.source,
    required this.timeAgo,
    required this.imageEmoji,
    required this.categoryColor,
    this.isFeatured = false,
  });
}

class FarmingTip {
  final String icon;
  final String title;
  final String description;
  final String tag;
  final Color color;

  const FarmingTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    required this.color,
  });
}

// ─────────────────────────────────────────
// FARMING TIPS & NEWS SCREEN
// ─────────────────────────────────────────

class FarmingTipsNewsScreen extends StatefulWidget {
  const FarmingTipsNewsScreen({super.key});

  @override
  State<FarmingTipsNewsScreen> createState() => _FarmingTipsNewsScreenState();
}

class _FarmingTipsNewsScreenState extends State<FarmingTipsNewsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategory = 0;
  final Set<String> _savedArticles = {};
  bool _isLoadingNews = true;
  bool _isLoadingTips = true;
  List<NewsArticle> _news = [];
  List<FarmingTip> _tips = [];

  final List<String> _categories = [
    'All',
    'Market Update',
    'Technology',
    'Pest Alert',
    'Policy',
    'Climate',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNews();
    _loadTips();
  }

  Color _parseHexColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF2D6A4F);
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF2D6A4F);
    }
  }

  void _loadNews() async {
    setState(() => _isLoadingNews = true);
    final res = await ApiService.getNewsArticles();
    if (mounted) {
      setState(() {
        if (res.isNotEmpty) {
          _news = res.map((a) {
            return NewsArticle(
              id: a['id']?.toString() ?? '',
              category: a['category'] ?? 'General',
              title: a['title'] ?? '',
              summary: a['summary'] ?? '',
              source: a['source'] ?? 'Agrosmart',
              timeAgo: a['published_at'] ?? 'Today',
              imageEmoji: a['image_emoji'] ?? '📰',
              categoryColor: _parseHexColor(a['category_color']),
              isFeatured: a['is_featured'] == true,
            );
          }).toList();
        } else {
          // fallback mock news
          _news = const [
            NewsArticle(id: '1', category: 'Market Update', title: 'Wheat Prices Surge 12% Amid Global Supply Concerns', summary: 'International wheat futures climbed sharply this week as drought conditions persist in key growing regions.', source: 'Agrosmart Market Daily', timeAgo: '2h ago', imageEmoji: '🌾', categoryColor: Color(0xFFE07B39), isFeatured: true),
            NewsArticle(id: '2', category: 'Technology', title: 'AI-Powered Irrigation Systems Cut Water Usage by 40%', summary: 'New smart drip systems with soil-moisture sensors help farmers reduce water consumption.', source: 'FarmTech Review', timeAgo: '5h ago', imageEmoji: '💧', categoryColor: Color(0xFF2196F3)),
            NewsArticle(id: '3', category: 'Pest Alert', title: 'Fall Armyworm Detected in Northern Districts', summary: 'Agricultural authorities issued an advisory after fall armyworm infestations were confirmed.', source: 'Crop Protection News', timeAgo: '8h ago', imageEmoji: '🐛', categoryColor: Color(0xFFE53935)),
            NewsArticle(id: '4', category: 'Policy', title: 'Govt Announces ₹50,000 Cr Subsidy Package for Farmers', summary: 'New relief package supports small farmers with fertilizer subsidies and low-interest crop loans.', source: 'Agrosmart Policy Hub', timeAgo: '1d ago', imageEmoji: '🏛️', categoryColor: Color(0xFF7B1FA2)),
          ];
        }
        _isLoadingNews = false;
      });
    }
  }

  void _loadTips() async {
    setState(() => _isLoadingTips = true);
    final res = await ApiService.getFarmingTips();
    if (mounted) {
      setState(() {
        if (res.isNotEmpty) {
          _tips = res.map((t) {
            String tag = t['tag'] ?? 'General';
            Color color = const Color(0xFF2D6A4F);
            if (tag.toLowerCase().contains('soil')) color = const Color(0xFF52796F);
            if (tag.toLowerCase().contains('fertil')) color = const Color(0xFFE07B39);
            if (tag.toLowerCase().contains('pest')) color = const Color(0xFFE53935);

            return FarmingTip(
              icon: t['icon'] ?? '🌱',
              title: t['title'] ?? '',
              description: t['description'] ?? '',
              tag: tag,
              color: color,
            );
          }).toList();
        } else {
          // fallback mock tips
          _tips = const [
            FarmingTip(icon: '🌱', title: 'Seed Treatment', description: 'Treat seeds with fungicide + insecticide before sowing to prevent soil-borne diseases.', tag: 'Pre-Sowing', color: Color(0xFF2D6A4F)),
            FarmingTip(icon: '🌿', title: 'Intercropping Benefits', description: 'Growing legumes alongside cereals improves soil nitrogen naturally, reducing fertilizer cost.', tag: 'Soil Health', color: Color(0xFF52796F)),
            FarmingTip(icon: '💊', title: 'Nutrient Management', description: 'Split fertilizer application improves nutrient uptake efficiency and reduces runoff.', tag: 'Fertilization', color: Color(0xFFE07B39)),
            FarmingTip(icon: '🔍', title: 'Scouting Protocol', description: 'Walk fields in W-pattern twice a week. Early detection saves 70% on pesticide costs.', tag: 'Pest Control', color: Color(0xFFE53935)),
          ];
        }
        _isLoadingTips = false;
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(innerBoxIsScrolled),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNewsTab(),
                  _buildTipsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SLIVER APP BAR ──
  Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1B4332),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.bookmark_border_rounded, color: Colors.white),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: AnimatedOpacity(
          opacity: innerBoxIsScrolled ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Tips & News'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B788).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🌿 ' + 'Agrosmart'.tr,
                        style: const TextStyle(
                          color: Color(0xFF95D5B2),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Farming Tips & News'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── TAB BAR ──
  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF1B4332),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF95D5B2),
        indicator: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFF52B788), width: 3),
          ),
        ),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: [
          Tab(text: '📰  ' + 'Latest News'.tr),
          Tab(text: '💡  ' + 'Expert Tips'.tr),
        ],
      ),
    );
  }

  // ── NEWS TAB ──
  Widget _buildNewsTab() {
    if (_isLoadingNews) {
      return const Center(child: CircularProgressIndicator());
    }

    final categoryName = _categories[_selectedCategory];
    List<NewsArticle> filtered = _selectedCategory == 0
        ? _news
        : _news
        .where((a) => a.category.toLowerCase() == categoryName.toLowerCase())
        .toList();

    final featuredList = filtered.where((a) => a.isFeatured).toList();
    final nonFeaturedList = filtered.where((a) => !a.isFeatured).toList();
    final NewsArticle? featured = featuredList.isNotEmpty ? featuredList.first : null;

    return RefreshIndicator(
      onRefresh: () async {
        _loadNews();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildCategoryFilter()),
          if (featured != null)
            SliverToBoxAdapter(
              child: _buildFeaturedCard(featured),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Latest Updates'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'See All'.tr,
                      style: const TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                if (i >= nonFeaturedList.length) return null;
                return _buildNewsCard(nonFeaturedList[i]);
              },
              childCount: nonFeaturedList.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, i) {
          final selected = _selectedCategory == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2D6A4F) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2D6A4F)
                      : const Color(0xFFDDE5DB),
                ),
              ),
              child: Center(
                child: Text(
                  _categories[i].tr,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF52796F),
                    fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCard(NewsArticle article) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B4332),
              Color(0xFF2D6A4F),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Text(
                article.imageEmoji,
                style: TextStyle(fontSize: 100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: article.categoryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.timeAgo.tr,
                        style: const TextStyle(
                          color: Color(0xFF95D5B2),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    article.title.tr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.source_outlined,
                          color: Color(0xFF95D5B2), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        article.source.tr,
                        style: const TextStyle(
                          color: Color(0xFF95D5B2),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Read More'.tr + ' →',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    final isSaved = _savedArticles.contains(article.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
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
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: article.categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    article.imageEmoji,
                    style: TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 14),
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
                            color: article.categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            article.category.tr,
                            style: TextStyle(
                              color: article.categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          article.timeAgo.tr,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.title.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A2E1A),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.summary.tr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.newspaper_rounded,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          article.source.tr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            isSaved
                                ? _savedArticles.remove(article.id)
                                : _savedArticles.add(article.id);
                          }),
                          child: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: isSaved
                                ? const Color(0xFF2D6A4F)
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TIPS TAB ──
  Widget _buildTipsTab() {
    if (_isLoadingTips) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadTips();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildTipsBanner()),
          SliverToBoxAdapter(child: _buildSeasonAdvisory()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expert Tips'.tr,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_tips.length} ' + 'tips'.tr,
                      style: const TextStyle(
                        color: Color(0xFF2D6A4F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                if (i >= _tips.length) return null;
                return _buildTipCard(_tips[i], i);
              },
              childCount: _tips.length,
            ),
          ),
          SliverToBoxAdapter(child: _buildVideoSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildTipsBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFD8F3DC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF95D5B2).withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF52B788),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lightbulb_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Smart Tip'.tr,
                    style: const TextStyle(
                      color: Color(0xFF1B4332),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Early weeding reduces competition for soil nutrients by up to 40%. Plan weeding before top-dress.'.tr,
                    style: const TextStyle(
                      color: Color(0xFF2D6A4F),
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonAdvisory() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kharif Season Advisory'.tr + ' 🌦️',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B4332),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Monsoon onset is expected next week. Prepare drainage channels for low-lying fields. Delay urea application if heavy precipitation is forecast.'.tr,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF52796F),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(FarmingTip tip, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    tip.icon,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: tip.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tip.tag.tr,
                        style: TextStyle(
                          color: tip.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip.title.tr,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tip.description.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Guides'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1592982537447-6f2a6a0c7c18?auto=format&fit=crop&q=80&w=800'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How to implement smart drip irrigation in sandy loam soils'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4332),
            ),
          ),
        ],
      ),
    );
  }
}
