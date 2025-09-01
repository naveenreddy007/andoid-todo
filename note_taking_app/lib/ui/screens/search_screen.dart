import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../providers/note_provider.dart';
import '../widgets/note_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchNotesProvider(_controller.text));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
          ),
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _buildGradientBackground(
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: results.when(
            data: (notes) => notes.isEmpty
                ? const Center(
                    key: ValueKey('empty'),
                    child: Text('No results found'),
                  )
                : ListView.builder(
                    key: const ValueKey('list'),
                    padding: const EdgeInsets.all(16),
                    itemCount: notes.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: NoteCard(note: notes[index]),
                    ),
                  ),
            loading: () => const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              key: const ValueKey('error'),
              child: Text('Error: $error'),
            ),
          ),
        ),
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
                  const Color(0xFF0F172A),
                  const Color(0xFF111827),
                ]
              : [
                  const Color(0xFFF5F7FB),
                  const Color(0xFFEAF2FF),
                ],
        ),
      ),
      child: child,
    );
  }
}