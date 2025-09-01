import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../domain/entities/category.dart';
import '../../providers/providers.dart';
import '../widgets/empty_state.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Symbols.folder;
  Category? _editingCategory;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: () => _showCategoryDialog(),
          ),
        ],
      ),
      body: _buildGradientBackground(
        context,
        categoriesAsync.when(
          data: (categories) => categories.isEmpty
              ? const EmptyState(
                  icon: Symbols.folder_off,
                  title: 'No Categories',
                  subtitle: 'Create your first category to organize todos',
                )
              : _buildCategoriesList(categories),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ),
    );
  }

  Widget _buildGradientBackground(BuildContext context, Widget child) {
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

  Widget _buildCategoriesList(List<Category> categories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _parseColor(category.color).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            IconData(int.parse(category.icon!), fontFamily: 'MaterialSymbolsOutlined'),
            color: _parseColor(category.color),
          ),
        ),
        title: Text(
          category.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Symbols.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showCategoryDialog(category: category);
                break;
              case 'delete':
                _showDeleteConfirmation(category);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Symbols.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Symbols.delete),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Symbols.error,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading categories',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(categoriesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({Category? category}) {
    _editingCategory = category;
    if (category != null) {
      _nameController.text = category.name;
      _selectedColor = _parseColor(category.color);
      _selectedIcon = IconData(int.parse(category.icon!), fontFamily: 'MaterialSymbolsOutlined');
    } else {
      _nameController.clear();

      _selectedColor = Colors.blue;
      _selectedIcon = Symbols.folder;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Color: ', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showColorPicker(setState),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Icon: ', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showIconPicker(setState),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _selectedColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Icon(_selectedIcon, color: _selectedColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveCategory(),
              child: Text(category == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(StateSetter setState) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedColor == color ? Colors.black : Colors.grey,
                    width: _selectedColor == color ? 2 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showIconPicker(StateSetter setState) {
    final icons = [
      Symbols.folder,
      Symbols.work,
      Symbols.home,
      Symbols.school,
      Symbols.shopping_cart,
      Symbols.fitness_center,
      Symbols.favorite,
      Symbols.travel_explore,
      Symbols.restaurant,
      Symbols.local_hospital,
      Symbols.directions_car,
      Symbols.pets,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Icon'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: icons.map((icon) {
            return GestureDetector(
              onTap: () {
                setState(() => _selectedIcon = icon);
                Navigator.of(context).pop();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedIcon == icon ? _selectedColor : Colors.grey,
                    width: _selectedIcon == icon ? 2 : 1,
                  ),
                ),
                child: Icon(icon, color: _selectedColor),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    try {
      if (_editingCategory != null) {
        // Update existing category
        final updatedCategory = _editingCategory!.copyWith(
          name: _nameController.text.trim(),
          color: '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          icon: _selectedIcon.codePoint.toString(),
        );
        await ref.read(categoryOperationsProvider.notifier).updateCategory(updatedCategory);
      } else {
        // Create new category
        final newCategory = Category(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          color: '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
          icon: _selectedIcon.codePoint.toString(),
          createdAt: DateTime.now(),
        );
        await ref.read(categoryOperationsProvider.notifier).saveCategory(newCategory);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _editingCategory != null 
                  ? 'Category updated successfully' 
                  : 'Category created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving category: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCategory(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Remove '#' if present
      String cleanColor = colorString.replaceAll('#', '');
      // Parse as hex and create Color
      return Color(int.parse('FF$cleanColor', radix: 16));
    } catch (e) {
      // Return default color if parsing fails
      return Colors.blue;
    }
  }

  void _deleteCategory(Category category) async {
    try {
      await ref.read(categoryOperationsProvider.notifier).deleteCategory(category.id);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting category: $e')),
        );
      }
    }
  }
}
