import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../screens/home_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/sync_settings_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/search_screen.dart';
import '../screens/reminder_screen.dart';
import 'sync_status_indicator.dart';
import '../../providers/search_provider.dart';

/// Provider for managing the current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main navigation widget with bottom navigation bar
class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          CategoriesScreen(),
          SearchScreen(),
          StatisticsScreen(),
          ReminderScreen(),
          SyncSettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(navigationIndexProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_outlined, Icons.home, 0, currentIndex),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.folder_outlined, Icons.folder, 1, currentIndex),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.search_outlined, Icons.search, 2, currentIndex),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.analytics_outlined, Icons.analytics, 3, currentIndex),
              label: 'Statistics',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.alarm_outlined, Icons.alarm, 4, currentIndex),
              label: 'Reminders',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.sync_outlined, Icons.sync, 5, currentIndex),
              label: 'Sync',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index, int currentIndex) {
    final isSelected = index == currentIndex;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(
        isSelected ? filledIcon : outlinedIcon,
        key: ValueKey(isSelected),
      ),
    );
  }
}

/// Enhanced app bar with sync status and search functionality
class EnhancedAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSearch;
  final VoidCallback? onSearchPressed;
  final bool showSyncStatus;
  
  const EnhancedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSearch = true,
    this.onSearchPressed,
    this.showSyncStatus = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1,
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed ?? () => _showSearchDialog(context, ref),
            tooltip: 'Search',
          ),
        IconButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ThemeSettingsScreen(),
            ),
          ),
          icon: const Icon(LucideIcons.palette),
          tooltip: 'Theme Settings',
        ),
        if (showSyncStatus)
          CompactSyncStatusIndicator(
            onTap: () => _showSyncBottomSheet(context, ref),
          ),
        ...?actions,
        const SizedBox(width: 8),
      ],
    );
  }
  
  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SearchScreen(),
      ),
    );
  }
  
  void _showSyncBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SyncStatusBottomSheet(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Search dialog for global search functionality
class SearchDialog extends ConsumerStatefulWidget {
  const SearchDialog({super.key});

  @override
  ConsumerState<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<SearchDialog> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Search todos, categories, tags...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    ref.read(searchProvider.notifier).performSearch(value);
                  } else {
                    ref.read(searchProvider.notifier).clearSearch();
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    ref.read(searchProvider.notifier).performSearch(value);
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final searchState = ref.watch(searchProvider);
                  
                  if (_searchController.text.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search,
                                  size: 48,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Start typing to search',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  
                  if (searchState.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  final hasResults = searchState.results.todos.isNotEmpty ||
                      searchState.results.categories.isNotEmpty ||
                      searchState.results.tags.isNotEmpty;
                  
                  if (!hasResults) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (searchState.results.todos.isNotEmpty) ..[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Todos (${searchState.results.todos.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...searchState.results.todos.take(3).map(
                          (todo) => ListTile(
                            title: Text(todo.title),
                            subtitle: todo.description?.isNotEmpty == true
                                ? Text(todo.description!)
                                : null,
                            leading: Icon(
                              todo.isCompleted
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: todo.isCompleted
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        if (searchState.results.todos.length > 3)
                          ListTile(
                            title: Text(
                              'View all ${searchState.results.todos.length} todos',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward,
                              color: theme.colorScheme.primary,
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                ),
                              );
                            },
                          ),
                      ],
                      if (searchState.results.categories.isNotEmpty) ..[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Categories (${searchState.results.categories.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...searchState.results.categories.take(2).map(
                          (category) => ListTile(
                            title: Text(category.name),
                            leading: Icon(
                              Icons.folder,
                              color: Color(category.color),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const SearchScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      if (searchState.results.tags.isNotEmpty) ..[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Tags (${searchState.results.tags.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: searchState.results.tags.take(6).map(
                            (tag) => ActionChip(
                              label: Text(tag.name),
                              backgroundColor: Color(tag.color).withOpacity(0.1),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SearchScreen(),
                                  ),
                                );
                              },
                            ),
                          ).toList(),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for sync status and quick actions
class SyncStatusBottomSheet extends ConsumerWidget {
  const SyncStatusBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sync Status',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DetailedSyncStatusCard(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SyncSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(syncProvider.notifier).performManualSync();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SyncSettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

/// Navigation helper for programmatic navigation
class NavigationHelper {
  static void navigateToTab(WidgetRef ref, int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
  }
  
  static void navigateToHome(WidgetRef ref) => navigateToTab(ref, 0);
  static void navigateToCategories(WidgetRef ref) => navigateToTab(ref, 1);
  static void navigateToSearch(WidgetRef ref) => navigateToTab(ref, 2);
  static void navigateToStatistics(WidgetRef ref) => navigateToTab(ref, 3);
  static void navigateToReminders(WidgetRef ref) => navigateToTab(ref, 4);
  static void navigateToSync(WidgetRef ref) => navigateToTab(ref, 5);
  
  static int getCurrentTab(WidgetRef ref) {
    return ref.read(navigationIndexProvider);