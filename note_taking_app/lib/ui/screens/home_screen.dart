import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/note_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/empty_state.dart';
import 'note_editor_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Symbols.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Symbols.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildGradientBackground(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: notesAsyncValue.when(
            data: (notes) => notes.isEmpty
                ? const EmptyState(
                    key: ValueKey('empty'),
                    icon: Symbols.note_add,
                    title: 'No notes yet',
                    subtitle: 'Create your first note to get started',
                  )
                : _buildNotesList(notes),
            loading: () => const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
              key: const ValueKey('error'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.error,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      error.toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(notesProvider),
                    icon: const Icon(Symbols.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
          );
        },
        child: const Icon(Symbols.add),
      ),
    );
  }

  Widget _buildGradientBackground(Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F172A), // slate-900
                  const Color(0xFF111827), // gray-900
                ]
              : [
                  const Color(0xFFF5F7FB), // light backdrop
                  const Color(0xFFEAF2FF), // subtle tint
                ],
        ),
      ),
      child: child,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organize your thoughts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.home),
            title: const Text('All Notes'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Symbols.archive),
            title: const Text('Archived'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to archived notes
            },
          ),
          ListTile(
            leading: const Icon(Symbols.category),
            title: const Text('Categories'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to categories management
            },
          ),
          ListTile(
            leading: const Icon(Symbols.label),
            title: const Text('Tags'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to tags management
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<dynamic> notes) {
    return RefreshIndicator(
      onRefresh: () async {
        final _ = ref.refresh(notesProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: NoteCard(
              note: note,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteEditorScreen(note: note),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
