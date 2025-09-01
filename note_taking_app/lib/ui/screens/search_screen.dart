import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/search_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/tag_provider.dart';
import '../../services/search_service.dart';

import '../../domain/entities/todo.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/tag.dart';
import '../widgets/todo_card.dart';
import 'todo_editor_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchProvider.notifier).loadSuggestions('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            if (_showFilters) _buildFiltersSection(),
            Expanded(
              child: _buildSearchContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchField(),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  color: _showFilters ? Theme.of(context).primaryColor : Colors.grey[600],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _showFilters 
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : Colors.grey[100],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final searchState = ref.watch(searchProvider);
    return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _searchFocusNode.hasFocus 
                ? Theme.of(context).primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search todos, categories, tags...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[500],
            ),
            suffixIcon: searchState.hasQuery
                ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clearSearch();
                    },
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey[500],
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            ref.read(searchProvider.notifier).search(value);
            ref.read(searchProvider.notifier).loadSuggestions(value);
          },
        ),
      );
  }

  Widget _buildFiltersSection() {
    final searchState = ref.watch(searchProvider);
    final categoryState = ref.watch(categoriesProvider);
    final tagState = ref.watch(tagsProvider);
    return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusFilter(searchState),
              const SizedBox(height: 16),
              _buildPriorityFilter(searchState),
              const SizedBox(height: 16),
              _buildCategoryFilter(searchState, categoryState),
              const SizedBox(height: 16),
              _buildTagFilter(searchState, tagState),
              const SizedBox(height: 16),
              _buildDateRangeFilter(searchState),
              const SizedBox(height: 16),
              _buildSortOptions(searchState),
              const SizedBox(height: 12),
              _buildFilterActions(searchState),
            ],
          ),
        );
  }

  Widget _buildStatusFilter(SearchState searchState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: FilterStatus.values.map((status) {
            final isSelected = searchState.statusFilter == status;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getStatusLabel(status)),
                selected: isSelected,
                onSelected: (_) => ref.read(searchProvider.notifier).setStatusFilter(status),
                backgroundColor: Colors.grey[100],
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriorityFilter(SearchState searchState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: searchState.priorityFilter == null,
              onSelected: (_) => ref.read(searchProvider.notifier).setPriorityFilter(null),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
            ...Priority.values.map((priority) {
              final isSelected = searchState.priorityFilter == priority;
              return FilterChip(
                label: Text(priority.displayName),
                selected: isSelected,
                onSelected: (_) => ref.read(searchProvider.notifier).setPriorityFilter(
                  isSelected ? null : priority,
                ),
                backgroundColor: Colors.grey[100],
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(SearchState searchState, AsyncValue<List<Category>> categoryState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: searchState.categoryFilter == null,
              onSelected: (_) => ref.read(searchProvider.notifier).setCategoryFilter(null),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
            ...categoryState.when(
              data: (categories) => categories.map((category) {
                final isSelected = searchState.categoryFilter == category.id;
                return FilterChip(
                  label: Text(category.name),
                  selected: isSelected,
                  onSelected: (_) => ref.read(searchProvider.notifier).setCategoryFilter(
                    isSelected ? null : category.id,
                  ),
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }),
              loading: () => <Widget>[],
              error: (_, _) => <Widget>[],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagFilter(SearchState searchState, AsyncValue<List<Tag>> tagState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: searchState.tagFilters.isEmpty,
              onSelected: (_) => ref.read(searchProvider.notifier).clearTagFilters(),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            ),
            ...tagState.when(
              data: (tags) => tags.map((tag) {
                final isSelected = searchState.tagFilters.contains(tag.id);
                return FilterChip(
                  label: Text(tag.name),
                  selected: isSelected,
                  onSelected: (_) {
                    if (isSelected) {
                      ref.read(searchProvider.notifier).removeTagFilter(tag.id);
                    } else {
                      ref.read(searchProvider.notifier).addTagFilter(tag.id);
                    }
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                );
              }),
              loading: () => <Widget>[],
              error: (_, _) => <Widget>[],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeFilter(SearchState searchState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date Range',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectFromDate(searchState),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    searchState.dueDateFrom != null
                        ? '${searchState.dueDateFrom!.day}/${searchState.dueDateFrom!.month}/${searchState.dueDateFrom!.year}'
                        : 'From Date',
                    style: TextStyle(
                      color: searchState.dueDateFrom != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectToDate(searchState),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    searchState.dueDateTo != null
                        ? '${searchState.dueDateTo!.day}/${searchState.dueDateTo!.month}/${searchState.dueDateTo!.year}'
                        : 'To Date',
                    style: TextStyle(
                      color: searchState.dueDateTo != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            if (searchState.dueDateFrom != null || searchState.dueDateTo != null)
              IconButton(
                onPressed: () => ref.read(searchProvider.notifier).setDateRangeFilter(null, null),
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Clear date range',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions(SearchState searchState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort by',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: SortOption.values.map((option) {
            final isSelected = searchState.sortBy == option;
            return FilterChip(
              label: Text(_getSortLabel(option)),
              selected: isSelected,
              onSelected: (_) => ref.read(searchProvider.notifier).setSortBy(option),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFilterActions(SearchState searchState) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => ref.read(searchProvider.notifier).clearFilters(),
          icon: const Icon(Icons.clear_all),
          label: const Text('Clear Filters'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchContent() {
    final searchState = ref.watch(searchProvider);
    
    if (!searchState.hasQuery) {
      return _buildSearchSuggestions(searchState);
    }

    if (searchState.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (!searchState.hasResults) {
      return _buildNoResults();
    }

    return _buildSearchResults(searchState);
  }

  Widget _buildSearchSuggestions(SearchState searchState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchState.searchHistory.isNotEmpty) ...[
            _buildSectionHeader('Recent Searches', Icons.history),
            const SizedBox(height: 12),
            _buildSearchHistoryList(searchState),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Popular Searches', Icons.trending_up),
          const SizedBox(height: 12),
          _buildSuggestionsList(searchState),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHistoryList(SearchState searchState) {
    return Column(
      children: searchState.searchHistory.take(5).map((query) {
        return ListTile(
          leading: Icon(
            Icons.history,
            color: Colors.grey[500],
          ),
          title: Text(query),
          trailing: IconButton(
            onPressed: () => ref.read(searchProvider.notifier).removeFromHistory(query),
            icon: Icon(
              Icons.close,
              color: Colors.grey[400],
            ),
          ),
          onTap: () {
            _searchController.text = query;
            ref.read(searchProvider.notifier).searchImmediate(query);
          },
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionsList(SearchState searchState) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: searchState.suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () {
            _searchController.text = suggestion;
            ref.read(searchProvider.notifier).searchImmediate(suggestion);
          },
          backgroundColor: Colors.grey[100],
          side: BorderSide(color: Colors.grey[300]!),
        );
      }).toList(),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    final result = searchState.searchResult!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(result),
          const SizedBox(height: 16),
          if (result.todos.isNotEmpty) ...[
            _buildResultSection(
              'Todos (${result.todos.length})',
              Icons.task_alt,
              _buildTodoResults(result.todos),
            ),
            const SizedBox(height: 24),
          ],
          if (result.categories.isNotEmpty) ...[
            _buildResultSection(
              'Categories (${result.categories.length})',
              Icons.category,
              _buildCategoryResults(result.categories),
            ),
            const SizedBox(height: 24),
          ],
          if (result.tags.isNotEmpty) ...[
            _buildResultSection(
              'Tags (${result.tags.length})',
              Icons.label,
              _buildTagResults(result.tags),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsHeader(SearchResult result) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${result.totalResults} results found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildTodoResults(List<Todo> todos) {
    return Column(
      children: todos.map((todo) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TodoCard(
            todo: todo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TodoEditorScreen(todo: todo),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryResults(List<Category> categories) {
    return Column(
      children: categories.map((category) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.category,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Category',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            onTap: () {
              // Navigate to category view or filter by category
              Navigator.pop(context);
              // You can add navigation to category-specific view here
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagResults(List<Tag> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return ActionChip(
          label: Text(tag.name),
          avatar: Icon(
            Icons.label,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
          onPressed: () {
            // Filter by this tag
            ref.read(searchProvider.notifier).addTagFilter(tag.id);
          },
        );
      }).toList(),
    );
  }

  Future<void> _selectFromDate(SearchState searchState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: searchState.dueDateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref.read(searchProvider.notifier).setDateRangeFilter(picked, searchState.dueDateTo);
    }
  }

  Future<void> _selectToDate(SearchState searchState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: searchState.dueDateTo ?? DateTime.now(),
      firstDate: searchState.dueDateFrom ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ref.read(searchProvider.notifier).setDateRangeFilter(searchState.dueDateFrom, picked);
    }
  }

  String _getStatusLabel(FilterStatus status) {
    switch (status) {
      case FilterStatus.all:
        return 'All';
      case FilterStatus.completed:
        return 'Completed';
      case FilterStatus.pending:
        return 'Pending';
      case FilterStatus.inProgress:
        return 'In Progress';
      case FilterStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.dateCreated:
        return 'Date Created';
      case SortOption.dateUpdated:
        return 'Date Updated';
      case SortOption.priority:
        return 'Priority';
      case SortOption.title:
        return 'Alphabetical';
      case SortOption.dueDate:
        return 'Due Date';
    }
  }
}