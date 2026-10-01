import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/catalog_model.dart';
import '../../models/media_item.dart';
import '../../providers/extension_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/media_card.dart';
import '../../widgets/shimmer_loaders.dart';
import '../detail/media_detail_view.dart';
import '../../extensions/base_extension.dart';

class CategoryResultsView extends StatefulWidget {
  final CatalogItem item;

  const CategoryResultsView({super.key, required this.item});

  @override
  State<CategoryResultsView> createState() => _CategoryResultsViewState();
}

class _CategoryResultsViewState extends State<CategoryResultsView> {
  final List<MediaItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();
  late HentaiExtension _selectedExtension;

  @override
  void initState() {
    super.initState();
    final extProvider = Provider.of<ExtensionProvider>(context, listen: false);
    _selectedExtension = extProvider.activeExtension;
    _fetchResults(refresh: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoading &&
          _hasMore) {
        _fetchResults(refresh: false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      setState(() {
        _currentPage = 1;
        _items.clear();
        _hasMore = true;
        _errorMessage = null;
        _isLoading = true;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      List<MediaItem> results = await _selectedExtension.fetchTaxonomyFeed(widget.item, _currentPage);

      // If page 1 gave nothing, try slug search fallback
      if (results.isEmpty && _currentPage == 1) {
        results = await _selectedExtension.search(widget.item.slug, 1);
      }

      if (mounted) {
        setState(() {
          if (results.isEmpty) {
            _hasMore = false;
          } else {
            _items.addAll(results);
            _currentPage++;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showSourcePickerSheet(BuildContext context, ExtensionProvider extProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      "Select Source for Catalog",
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
                    final isSelected = ext.id == _selectedExtension.id;

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
                        setState(() {
                          _selectedExtension = ext;
                        });
                        _fetchResults(refresh: true);
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
    final extProvider = Provider.of<ExtensionProvider>(context, listen: false);
    const double posterAspectRatio = 0.58;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.item.icon, size: 16, color: AppTheme.primaryAccent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    "${widget.item.type.name.toUpperCase()} • ${_selectedExtension.name}",
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Change source button
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, color: AppTheme.textSecondary, size: 22),
            tooltip: "Switch Source Extension",
            onPressed: () => _showSourcePickerSheet(context, extProvider),
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
            tooltip: "Refresh",
            onPressed: () => _fetchResults(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.surfaceCard,
        onRefresh: () => _fetchResults(refresh: true),
        child: _buildBody(posterAspectRatio),
      ),
    );
  }

  Widget _buildBody(double posterAspectRatio) {
    if (_isLoading && _items.isEmpty) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: posterAspectRatio,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const ShimmerMediaCard(),
      );
    }

    if (_items.isEmpty && !_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.item.icon, size: 54, color: AppTheme.textMuted.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                "No releases found for \"${widget.item.name}\"",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                "Try switching the source extension using the top switch button.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryAccent),
                ),
              ],
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _fetchResults(refresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Retry Search"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryAccent,
                  side: const BorderSide(color: AppTheme.primaryAccent, width: 0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Category Header Banner
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderSubtle, width: 0.8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.description.isNotEmpty
                            ? widget.item.description
                            : "Showing all anime matching ${widget.item.name}",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_items.length} titles loaded from ${_selectedExtension.name}",
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2:3 Vertical Poster Grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: posterAspectRatio,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _items[index];
                return MediaCard(
                  item: item,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaDetailView(item: item, autoPlay: true),
                      ),
                    );
                  },
                );
              },
              childCount: _items.length,
            ),
          ),
        ),

        // Pagination Loader
        if (_isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryAccent,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
