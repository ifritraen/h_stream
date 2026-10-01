import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_model.dart';
import '../../providers/extension_provider.dart';
import '../../theme/app_theme.dart';
import 'category_results_view.dart';

class CategoriesGenresView extends StatefulWidget {
  const CategoriesGenresView({super.key});

  @override
  State<CategoriesGenresView> createState() => _CategoriesGenresViewState();
}

class _CategoriesGenresViewState extends State<CategoriesGenresView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedGroup = "All";

  final List<String> _groups = [
    "All",
    "Genre",
    "Character",
    "Artist",
    "Trope",
    "Game Parody",
    "Anime Parody",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CatalogItem> _filterItems(List<CatalogItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.slug.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q) ||
          (i.categoryGroup != null && i.categoryGroup!.toLowerCase().contains(q));
    }).toList();
  }

  List<CatalogItem> _filterTagsAndGenres(List<CatalogItem> items) {
    var filtered = _filterItems(items);
    if (_selectedGroup != "All") {
      filtered = filtered.where((t) {
        if (_selectedGroup == "Genre") {
          return t.type == CatalogType.genre || t.categoryGroup == "Genre";
        }
        return t.categoryGroup == _selectedGroup;
      }).toList();
    }
    return filtered;
  }

  List<CatalogItem> _filterSectionItems(TaxonomySection sec) {
    if (sec.displayType == TaxonomyDisplayType.tags) {
      return _filterTagsAndGenres(sec.items);
    }
    return _filterItems(sec.items);
  }

  void _showSourcePickerSheet(BuildContext context, ExtensionProvider extProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 0.8)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      "Select Source for Dynamic Explore",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.borderSubtle, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: extProvider.extensions.length,
                  itemBuilder: (context, idx) {
                    final ext = extProvider.extensions[idx];
                    final isSelected = ext.id == extProvider.activeExtension.id;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
                        ),
                      ),
                      title: Text(
                        ext.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppTheme.primaryAccent : AppTheme.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_rounded, color: AppTheme.primaryAccent, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        extProvider.setActiveExtension(ext);
                      },
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ExtensionProvider>(
      builder: (context, extProvider, _) {
        final currentTaxonomy = extProvider.currentTaxonomy ?? ExtensionTaxonomy.fromDefaultCatalog();
        final sections = currentTaxonomy.effectiveSections;
        final tabCount = sections.isNotEmpty ? sections.length : 1;

        return DefaultTabController(
          key: ValueKey("${extProvider.activeExtension.id}_$tabCount"),
          length: tabCount,
          child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            bottom: false,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // Top Bar with Dynamic Source Selector Pill
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.category_rounded,
                                    color: AppTheme.primaryAccent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Explore",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        "Dynamic categories, genres & tags",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Dynamic Source Selector Pill
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => _showSourcePickerSheet(context, extProvider),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryAccent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 80),
                                        child: Text(
                                          extProvider.activeExtension.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.all(6),
                                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textMuted),
                                tooltip: "Reload Taxonomy",
                                onPressed: () => extProvider.loadTaxonomyForActiveExtension(forceRefresh: true),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: "Search ${extProvider.activeExtension.name} categories & tags...",
                          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppTheme.textMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = "";
                                    });
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
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val.trim();
                          });
                        },
                      ),
                    ),
                  ),

                  // Dynamic Tabs generated per active extension
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        isScrollable: sections.length > 3,
                        tabAlignment: sections.length > 3 ? TabAlignment.start : TabAlignment.fill,
                        indicatorColor: AppTheme.primaryAccent,
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: AppTheme.borderSubtle,
                        labelColor: AppTheme.textPrimary,
                        unselectedLabelColor: AppTheme.textMuted,
                        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        tabs: sections.map((sec) {
                          final filtered = _filterSectionItems(sec);
                          return Tab(text: "${sec.title} (${filtered.length})");
                        }).toList(),
                      ),
                    ),
                  ),
                ];
              },
              body: extProvider.isTaxonomyLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : TabBarView(
                      children: sections.map((sec) {
                        final filtered = _filterSectionItems(sec);
                        switch (sec.displayType) {
                          case TaxonomyDisplayType.grid:
                            return _buildCategoryGrid(filtered);
                          case TaxonomyDisplayType.tags:
                            return _buildTagsAndGenresSection(filtered);
                          case TaxonomyDisplayType.artists:
                            return _buildArtistsSection(filtered);
                          case TaxonomyDisplayType.list:
                            return _buildCategoryGrid(filtered);
                        }
                      }).toList(),
                    ),
            ),
          ),
        ),
      );
    },
  );
}

  // TAB 1: Category Sub-Page
  Widget _buildCategoryGrid(List<CatalogItem> items) {
    if (items.isEmpty) {
      return _buildEmptySearch();
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.15,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final item = items[idx];
        return _buildCatalogCard(item);
      },
    );
  }

  // TAB 2: Tags & Genre Sub-Page
  Widget _buildTagsAndGenresSection(List<CatalogItem> items) {
    return Column(
      children: [
        // Sub-filter pill row
        Container(
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _groups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final group = _groups[idx];
              final isSelected = _selectedGroup == group;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGroup = group;
                  });
                },
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
                  child: Text(
                    group,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Tags & Genres Wrap List
        Expanded(
          child: items.isEmpty
              ? _buildEmptySearch()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: items.map((tag) {
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoryResultsView(item: tag),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tag.icon, size: 14, color: AppTheme.primaryAccent),
                              const SizedBox(width: 6),
                              Text(
                                tag.name,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (tag.count > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppTheme.borderSubtle, width: 0.6),
                                  ),
                                  child: Text(
                                    "${(tag.count / 1000).toStringAsFixed(1)}k",
                                    style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  // TAB 3: Top Artists Sub-Page
  Widget _buildArtistsSection(List<CatalogItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.brush_outlined, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              const Text(
                "No Artists or Studios Found",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              const Text(
                "Switch to another source like Rule34 or Hanime to explore top creators.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, idx) {
        final artist = items[idx];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryResultsView(item: artist),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Avatar with Gradient & Letter
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryAccent.withValues(alpha: 0.35),
                        AppTheme.primaryNeon.withValues(alpha: 0.15),
                      ],
                    ),
                    border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.4), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      artist.name.isNotEmpty ? artist.name.substring(0, 1).toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Artist Name
                Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                // Dynamic badge: Star rating for artists / Release count for studios
                Builder(
                  builder: (context) {
                    String badgeText;
                    IconData badgeIcon = Icons.star_rounded;
                    Color badgeColor = AppTheme.accentGold;

                    if (artist.categoryGroup == "Studio") {
                      badgeText = artist.count > 0 ? "${artist.count} releases" : "Official Studio";
                      badgeIcon = Icons.business_rounded;
                      badgeColor = AppTheme.primaryAccent;
                    } else if (artist.description.contains("approval")) {
                      final parts = artist.description.split("•");
                      badgeText = parts.length > 1 ? parts.last.trim().replaceAll("positive ", "") : "Top Animator";
                      badgeIcon = Icons.star_rounded;
                      badgeColor = AppTheme.accentGold;
                    } else if (artist.count > 0) {
                      badgeText = "${artist.count} videos";
                      badgeIcon = Icons.movie_rounded;
                      badgeColor = AppTheme.primaryAccent;
                    } else {
                      badgeText = "Creator";
                      badgeIcon = Icons.palette_rounded;
                      badgeColor = AppTheme.primaryNeon;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderSubtle, width: 0.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 13, color: badgeColor),
                          const SizedBox(width: 3),
                          Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCatalogCard(CatalogItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryResultsView(item: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryAccent.withValues(alpha: 0.25), width: 0.8),
                  ),
                  child: Icon(item.icon, size: 18, color: AppTheme.primaryAccent),
                ),
                if (item.count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderSubtle, width: 0.6),
                    ),
                    child: Text(
                      "${(item.count / 1000).toStringAsFixed(1)}k+",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description.isNotEmpty ? item.description : item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textMuted,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearch() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(
              "No matches found for \"$_searchQuery\"",
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
