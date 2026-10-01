import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/extension_provider.dart';
import '../../providers/feed_board_provider.dart';
import '../../providers/tag_matrix_provider.dart';
import '../../providers/download_provider.dart';
import '../../providers/stealth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_card.dart';
import '../../widgets/shimmer_loaders.dart';
import '../../widgets/frosted_floating_dock.dart';
import '../detail/media_detail_view.dart';
import '../player/mini_player_dock.dart';
import '../shorts/infinity_reels_view.dart';
import '../explore/categories_genres_view.dart';
import '../settings/app_settings_sheet.dart';
import '../vault/private_vault_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _navIndex = 0; // 0: Discover, 1: Shorts, 2: Explore (Categories/Genres/Tags), 3: Vault
  final TextEditingController _searchController = TextEditingController();
  bool _isAggregatorMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ext = Provider.of<ExtensionProvider>(context, listen: false);
      final tag = Provider.of<TagMatrixProvider>(context, listen: false);
      ext.fetchFeed(
        refresh: true,
        whitelistedTags: tag.whitelistedTags,
        blacklistedTags: tag.blacklistedTags,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Active Tab Page
          IndexedStack(
            index: _navIndex,
            children: [
              _buildDiscoverFeed(),
              const InfinityReelsView(),
              const CategoriesGenresView(),
              const PrivateVaultView(),
            ],
          ),

          // Mini Player Floating Dynamic Island
          const MiniPlayerDock(),

          // Floating Frosted Glass Bottom Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Consumer<DownloadProvider>(
              builder: (_, downloads, _) => FrostedFloatingDock(
                currentIndex: _navIndex,
                activeDownloadCount: downloads.activeDownloads.length,
                onTabSelected: (idx) {
                  setState(() {
                    _navIndex = idx;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverFeed() {
    final extProvider = Provider.of<ExtensionProvider>(context);
    final feedBoard = Provider.of<FeedBoardProvider>(context);
    final stealth = Provider.of<StealthProvider>(context, listen: false);

    return CustomScrollView(
      slivers: [
        // Sleek Minimalist App Bar with Anymex Source Picker
        SliverAppBar(
          floating: true,
          pinned: false,
          backgroundColor: AppTheme.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 16,
          title: Row(
            children: [
              // Anymex-style Source Selector Pill
              GestureDetector(
                onTap: () => _showSourcePickerSheet(context, extProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        extProvider.activeExtension.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            // Aggregator Mode Toggle
            IconButton(
              icon: Icon(
                _isAggregatorMode ? Icons.dashboard_rounded : Icons.dashboard_outlined,
                color: _isAggregatorMode ? AppTheme.primaryAccent : AppTheme.textSecondary,
                size: 20,
              ),
              tooltip: "Bento Aggregator",
              onPressed: () {
                setState(() {
                  _isAggregatorMode = !_isAggregatorMode;
                });
              },
            ),
            // Settings & Equalizer Button (housing 3-State Tag Matrix)
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppTheme.textSecondary, size: 20),
              tooltip: "Settings & Filters",
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  builder: (_) => const AppSettingsSheet(),
                );
              },
            ),
            // Panic Stealth Button
            IconButton(
              icon: const Icon(Icons.shield_outlined, color: AppTheme.textSecondary, size: 20),
              tooltip: "Stealth Mode",
              onPressed: () => stealth.activateCalculatorDecoy(),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Sleek Minimalist Search Bar with Filter Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: "Search titles, studios, or tags...",
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                extProvider.search("");
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderBright, width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    ),
                    onSubmitted: (val) => extProvider.search(val),
                  ),
                ),
                const SizedBox(width: 8),
                _buildFilterButton(extProvider),
              ],
            ),
          ),
        ),

        // Anymex-style Horizontal Category & Genre Pill Tabs
        if (!_isAggregatorMode)
          SliverToBoxAdapter(
            child: Container(
              height: 38,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: extProvider.activeExtension.tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final tab = extProvider.activeExtension.tabs[idx];
                  final isSelected = extProvider.activeTabId == tab.id;

                  return GestureDetector(
                    onTap: () => extProvider.setActiveTab(tab.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryAccent : AppTheme.borderSubtle,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (tab.icon != null) ...[
                            Icon(
                              tab.icon,
                              size: 14,
                              color: isSelected ? Colors.white : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tab.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        // Main Feed: 2:3 Vertical Poster Grid or Bento Board
        if (_isAggregatorMode)
          ..._buildBentoRows(feedBoard)
        else
          _buildActiveExtensionGrid(extProvider),
      ],
    );
  }

  Widget _buildActiveExtensionGrid(ExtensionProvider provider) {
    // Elegant Anymex-style vertical poster card proportions: ~0.58 aspect ratio
    const double posterAspectRatio = 0.58;

    if (provider.isLoading && provider.items.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: posterAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, _) => const ShimmerMediaCard(),
            childCount: 6,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: posterAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = provider.items[index];
            return MediaCard(
              item: item,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MediaDetailView(item: item),
                  ),
                );
              },
            );
          },
          childCount: provider.items.length,
        ),
      ),
    );
  }

  List<Widget> _buildBentoRows(FeedBoardProvider feedBoard) {
    return feedBoard.rows.map((row) {
      final items = feedBoard.rowItems[row.id] ?? [];

      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.subtitle,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Horizontal Poster Carousel
              SizedBox(
                height: 250,
                child: items.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAccent, strokeWidth: 2))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          return Container(
                            width: 145,
                            margin: const EdgeInsets.only(right: 12),
                            child: MediaCard(
                              item: item,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MediaDetailView(item: item),
                                  ),
                                );
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
    }).toList();
  }

  Widget _buildFilterButton(ExtensionProvider extProvider) {
    final hasActiveFilters = extProvider.activeFilters.values.any((v) => v != null && v != 'all' && v != '');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showExtensionFilterSheet(context, extProvider),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters ? AppTheme.primaryAccent : AppTheme.borderSubtle,
              width: hasActiveFilters ? 1.2 : 0.8,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 19,
                color: hasActiveFilters ? AppTheme.primaryAccent : AppTheme.textSecondary,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Anymex-inspired Source Selector Modal Sheet
  void _showSourcePickerSheet(BuildContext context, ExtensionProvider extProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        String filterQuery = "";
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final allSources = extProvider.extensions;
            final filteredSources = allSources
                .where((s) => s.name.toLowerCase().contains(filterQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.8)),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderBright,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Select Source",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                        ),
                        child: Text(
                          "${allSources.length} Sources",
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search input for sources
                  TextField(
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Filter sources...",
                      hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 18),
                      filled: true,
                      fillColor: AppTheme.surfaceCard,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.borderBright, width: 1.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                    onChanged: (v) => setSheetState(() => filterQuery = v),
                  ),
                  const SizedBox(height: 12),

                  // Source List
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredSources.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final source = filteredSources[index];
                        final isSelected = extProvider.activeExtension.id == source.id;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              extProvider.setActiveExtension(source);
                              Navigator.pop(ctx);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryAccent.withValues(alpha: 0.12) : AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryAccent : AppTheme.borderSubtle,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: isSelected ? AppTheme.primaryAccent : AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      source.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${source.tabs.length} tabs",
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
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

  void _showExtensionFilterSheet(BuildContext context, ExtensionProvider extProvider) {
    final filters = extProvider.activeExtension.filters;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.8)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderBright,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.tune_rounded, size: 18, color: AppTheme.primaryAccent),
                          const SizedBox(width: 8),
                          Text(
                            "${extProvider.activeExtension.name} Filters",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (extProvider.activeFilters.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            for (final key in extProvider.activeFilters.keys.toList()) {
                              extProvider.updateFilter(key, null);
                            }
                            setModalState(() {});
                          },
                          child: const Text(
                            "Reset",
                            style: TextStyle(color: AppTheme.primaryAccent, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (filters.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppTheme.textMuted, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "This source exposes categories directly via top tabs. Use the Tag Matrix for advanced multi-tag filtering.",
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filters.map((group) {
                      final currentValue = extProvider.activeFilters[group.key] ?? group.defaultValue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: group.options.map((opt) {
                                final isSelected = currentValue == opt.value;
                                return ChoiceChip(
                                  label: Text(opt.label),
                                  selected: isSelected,
                                  selectedColor: AppTheme.primaryAccent,
                                  backgroundColor: AppTheme.surfaceCard,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? AppTheme.primaryAccent : AppTheme.borderSubtle,
                                    width: 0.8,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onSelected: (_) {
                                    extProvider.updateFilter(group.key, opt.value);
                                    setModalState(() {});
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.grid_view_rounded, size: 16, color: AppTheme.textPrimary),
                      label: const Text("Open 3-State Tag Matrix", style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderSubtle, width: 0.8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.surfaceCard,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _navIndex = 2; // Switch to Tag Matrix View
                        });
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
}
