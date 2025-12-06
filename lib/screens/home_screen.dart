import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../providers/app_provider.dart';
import '../widgets/creator_card.dart';
import '../widgets/search_bar_widget.dart';
import '../utils/theme.dart';
import 'creator_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<AppProvider>().search(query);
      if (query.isNotEmpty) {
        context.read<AppProvider>().addRecentSearch(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coomer',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Downloader',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.accent,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<AppProvider>().toggleTheme();
                    },
                    icon: Icon(
                      isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SearchBarWidget(
                onChanged: _onSearchChanged,
                onClear: () {
                  context.read<AppProvider>().clearSearch();
                },
                hintText: 'Creator ara...',
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: Consumer<AppProvider>(
                builder: (context, provider, child) {
                  // Show recent searches when no search
                  if (provider.searchQuery.isEmpty) {
                    return _buildEmptyState(context, provider);
                  }

                  // Loading
                  if (provider.isSearching) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // No results
                  if (provider.searchResults.isEmpty) {
                    return _buildNoResults(context);
                  }

                  // Results
                  return _buildResults(context, provider);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Favorites section
          if (provider.favorites.isNotEmpty) ...[
            Text(
              'Favoriler',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: provider.favorites.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final creator = provider.favorites[index];
                  return SizedBox(
                    width: 160,
                    child: CreatorCard(
                      creator: creator,
                      onTap: () => _navigateToCreator(creator),
                      isFavorite: true,
                      onFavoriteToggle: () => provider.toggleFavorite(creator),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Recent searches
          if (provider.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Son Aramalar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => provider.clearRecentSearches(),
                  child: Text(
                    'Temizle',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textSecondaryDark
                          : AppTheme.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _onSearchChanged(search);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          // Instructions
          if (provider.favorites.isEmpty && provider.recentSearches.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Icon(
                    Icons.search,
                    size: 80,
                    color: isDark
                        ? AppTheme.textSecondaryDark.withOpacity(0.3)
                        : AppTheme.textSecondaryLight.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Creator aramaya basla',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OnlyFans, Fansly ve diger\nplatformlardan icerik indir',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoResults(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: isDark
                ? AppTheme.textSecondaryDark.withOpacity(0.3)
                : AppTheme.textSecondaryLight.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuc bulunamadi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farkli bir arama deneyin',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${provider.searchResults.length} sonuc',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: provider.searchResults.length,
              itemBuilder: (context, index) {
                final creator = provider.searchResults[index];
                return CreatorCard(
                  creator: creator,
                  onTap: () => _navigateToCreator(creator),
                  isFavorite: provider.isFavorite(creator),
                  onFavoriteToggle: () => provider.toggleFavorite(creator),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCreator(dynamic creator) {
    context.read<AppProvider>().selectCreator(creator);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreatorDetailScreen(),
      ),
    );
  }
}

