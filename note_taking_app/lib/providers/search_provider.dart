import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../domain/entities/todo.dart';
import '../domain/entities/category.dart';
import '../domain/entities/tag.dart';
import '../domain/entities/priority.dart';
import '../services/search_service.dart';
import 'todo_provider.dart';
import 'category_provider.dart';
import 'tag_provider.dart';

// Import enums and classes from search service
// SortOption, FilterStatus, and SearchResult are now imported from search_service.dart

// Search state class
class SearchState {
  final String currentQuery;
  final bool isSearching;
  final SearchResult? searchResult;
  final List<String> searchHistory;
  final List<String> suggestions;
  final FilterStatus statusFilter;
  final Priority? priorityFilter;
  final String? categoryFilter;
  final List<String> tagFilters;
  final SortOption sortBy;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;

  const SearchState({
    this.currentQuery = '',
    this.isSearching = false,
    this.searchResult,
    this.searchHistory = const [],
    this.suggestions = const [],
    this.statusFilter = FilterStatus.all,
    this.priorityFilter,
    this.categoryFilter,
    this.tagFilters = const [],
    this.sortBy = SortOption.dateUpdated,
    this.dueDateFrom,
    this.dueDateTo,
  });

  bool get hasResults => searchResult != null && searchResult!.totalResults > 0;
  bool get hasQuery => currentQuery.trim().isNotEmpty;
  List<Todo> get filteredTodos => searchResult?.todos ?? [];
  List<Category> get filteredCategories => searchResult?.categories ?? [];
  List<Tag> get filteredTags => searchResult?.tags ?? [];

  SearchState copyWith({
    String? currentQuery,
    bool? isSearching,
    SearchResult? searchResult,
    List<String>? searchHistory,
    List<String>? suggestions,
    FilterStatus? statusFilter,
    Priority? priorityFilter,
    String? categoryFilter,
    List<String>? tagFilters,
    SortOption? sortBy,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) {
    return SearchState(
      currentQuery: currentQuery ?? this.currentQuery,
      isSearching: isSearching ?? this.isSearching,
      searchResult: searchResult ?? this.searchResult,
      searchHistory: searchHistory ?? this.searchHistory,
      suggestions: suggestions ?? this.suggestions,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      tagFilters: tagFilters ?? this.tagFilters,
      sortBy: sortBy ?? this.sortBy,
      dueDateFrom: dueDateFrom ?? this.dueDateFrom,
      dueDateTo: dueDateTo ?? this.dueDateTo,
    );
  }
}

// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  final todoRepository = ref.watch(todoRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  
  return SearchService(
    todoRepository: todoRepository,
    categoryRepository: categoryRepository,
    tagRepository: tagRepository,
  );
});

// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _searchService;
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  SearchNotifier(this._searchService) : super(const SearchState());

  /// Perform search with debouncing
  void search(String query) {
    state = state.copyWith(currentQuery: query);

    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      _clearResults();
      return;
    }

    // Set up debounced search
    _debounceTimer = Timer(_debounceDuration, () {
      _performSearch(query);
    });
  }

  /// Perform immediate search without debouncing
  void searchImmediate(String query) {
    state = state.copyWith(currentQuery: query);
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      _clearResults();
      return;
    }
    
    _performSearch(query);
  }

  /// Internal method to perform the actual search
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    state = state.copyWith(isSearching: true);

    try {
      final result = await _searchService.search(
        query: query,
        statusFilter: state.statusFilter,
        priorityFilter: state.priorityFilter,
        categoryFilter: state.categoryFilter,
        tagFilters: state.tagFilters,
        sortBy: state.sortBy,
        dueDateFrom: state.dueDateFrom,
        dueDateTo: state.dueDateTo,
      );
      
      final updatedHistory = _addToHistory(query, state.searchHistory);
      state = state.copyWith(
        searchResult: result,
        searchHistory: updatedHistory,
        isSearching: false,
      );
    } catch (e) {
      debugPrint('Search error: $e');
      state = state.copyWith(
        searchResult: SearchResult(todos: [], categories: [], tags: []),
        isSearching: false,
      );
    }
  }

  /// Load search suggestions
  Future<void> loadSuggestions(String query) async {
    if (query.trim().isEmpty) {
      final suggestions = await _searchService.getPopularSearches();
      state = state.copyWith(suggestions: suggestions);
    } else {
      final suggestions = await _searchService.getSearchSuggestions(query);
      state = state.copyWith(suggestions: suggestions);
    }
  }

  /// Set status filter
  void setStatusFilter(FilterStatus filter) {
    if (state.statusFilter != filter) {
      state = state.copyWith(statusFilter: filter);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Set priority filter
  void setPriorityFilter(Priority? priority) {
    if (state.priorityFilter != priority) {
      state = state.copyWith(priorityFilter: priority);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Set due date range filter
  void setDateRangeFilter(DateTime? from, DateTime? to) {
    if (state.dueDateFrom != from || state.dueDateTo != to) {
      state = state.copyWith(dueDateFrom: from, dueDateTo: to);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Set category filter
  void setCategoryFilter(String? categoryId) {
    if (state.categoryFilter != categoryId) {
      state = state.copyWith(categoryFilter: categoryId);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Add tag filter
  void addTagFilter(String tagId) {
    if (!state.tagFilters.contains(tagId)) {
      final updatedFilters = [...state.tagFilters, tagId];
      state = state.copyWith(tagFilters: updatedFilters);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Remove tag filter
  void removeTagFilter(String tagId) {
    if (state.tagFilters.contains(tagId)) {
      final updatedFilters = state.tagFilters.where((id) => id != tagId).toList();
      state = state.copyWith(tagFilters: updatedFilters);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Clear all tag filters
  void clearTagFilters() {
    if (state.tagFilters.isNotEmpty) {
      state = state.copyWith(tagFilters: []);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Set sort option
  void setSortBy(SortOption sortOption) {
    if (state.sortBy != sortOption) {
      state = state.copyWith(sortBy: sortOption);
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Clear all filters
  void clearFilters() {
    bool hasChanges = false;
    
    if (state.statusFilter != FilterStatus.all ||
        state.priorityFilter != null ||
        state.categoryFilter != null ||
        state.tagFilters.isNotEmpty ||
        state.dueDateFrom != null ||
        state.dueDateTo != null) {
      hasChanges = true;
    }
    
    if (hasChanges) {
      state = state.copyWith(
        statusFilter: FilterStatus.all,
        priorityFilter: null,
        categoryFilter: null,
        tagFilters: [],
        dueDateFrom: null,
        dueDateTo: null,
      );
      
      if (state.hasQuery) {
        searchImmediate(state.currentQuery);
      }
    }
  }

  /// Clear search results and query
  void clearSearch() {
    _debounceTimer?.cancel();
    _clearResults();
  }

  /// Internal method to clear results
  void _clearResults() {
    state = state.copyWith(
      currentQuery: '',
      searchResult: null,
      isSearching: false,
    );
  }

  /// Add query to search history
  List<String> _addToHistory(String query, List<String> currentHistory) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return currentHistory;
    
    final updatedHistory = List<String>.from(currentHistory);
    
    // Remove if already exists
    updatedHistory.remove(trimmedQuery);
    
    // Add to beginning
    updatedHistory.insert(0, trimmedQuery);
    
    // Keep only last 20 searches
    if (updatedHistory.length > 20) {
      return updatedHistory.take(20).toList();
    }
    
    return updatedHistory;
  }

  /// Clear search history
  void clearHistory() {
    state = state.copyWith(searchHistory: []);
  }

  /// Remove item from search history
  void removeFromHistory(String query) {
    final updatedHistory = state.searchHistory.where((item) => item != query).toList();
    if (updatedHistory.length != state.searchHistory.length) {
      state = state.copyWith(searchHistory: updatedHistory);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return SearchNotifier(searchService);
});