import '../domain/entities/todo.dart';
import '../domain/entities/category.dart';
import '../domain/entities/tag.dart';
import '../domain/entities/priority.dart';
import '../domain/entities/todo_status.dart';
import '../domain/repositories/todo_repository.dart';
import '../domain/repositories/category_repository.dart';
import '../domain/repositories/tag_repository.dart';

enum SortOption {
  dateCreated,
  dateUpdated,
  priority,
  title,
  dueDate,
}

enum FilterStatus {
  all,
  pending,
  inProgress,
  completed,
  cancelled,
}

class SearchResult {
  final List<Todo> todos;
  final List<Category> categories;
  final List<Tag> tags;
  final int totalResults;

  SearchResult({
    required this.todos,
    required this.categories,
    required this.tags,
  }) : totalResults = todos.length + categories.length + tags.length;
}

class SearchService {
  final TodoRepository _todoRepository;
  final CategoryRepository _categoryRepository;
  final TagRepository _tagRepository;

  SearchService({
    required TodoRepository todoRepository,
    required CategoryRepository categoryRepository,
    required TagRepository tagRepository,
  }) : _todoRepository = todoRepository,
       _categoryRepository = categoryRepository,
       _tagRepository = tagRepository;

  /// Performs comprehensive search across todos, categories, and tags
  Future<SearchResult> search({
    required String query,
    FilterStatus statusFilter = FilterStatus.all,
    Priority? priorityFilter,
    String? categoryFilter,
    List<String> tagFilters = const [],
    SortOption sortBy = SortOption.dateUpdated,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResult(todos: [], categories: [], tags: []);
    }

    final lowercaseQuery = query.toLowerCase();

    // Search todos
    final allTodos = await _todoRepository.getAllTodos();
    final filteredTodos = _searchTodos(
      allTodos,
      lowercaseQuery,
      statusFilter,
      priorityFilter,
      categoryFilter,
      tagFilters,
      dueDateFrom,
      dueDateTo,
    );
    final sortedTodos = _sortTodos(filteredTodos, sortBy);

    // Search categories
    final allCategories = await _categoryRepository.getAllCategories();
    final filteredCategories = _searchCategories(allCategories, lowercaseQuery);

    // Search tags
    final allTags = await _tagRepository.getAllTags();
    final filteredTags = _searchTags(allTags, lowercaseQuery);

    return SearchResult(
      todos: sortedTodos,
      categories: filteredCategories,
      tags: filteredTags,
    );
  }

  /// Search todos by title, description, and associated tags/categories
  List<Todo> _searchTodos(
    List<Todo> todos,
    String query,
    FilterStatus statusFilter,
    Priority? priorityFilter,
    String? categoryFilter,
    List<String> tagFilters,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
  ) {
    return todos.where((todo) {
      // Text search
      final titleMatch = todo.title.toLowerCase().contains(query);
      final descriptionMatch = todo.description?.toLowerCase().contains(query) ?? false;
      
      if (!titleMatch && !descriptionMatch) {
        return false;
      }

      // Status filter
      switch (statusFilter) {
        case FilterStatus.pending:
          if (todo.status != TodoStatus.pending) return false;
          break;
        case FilterStatus.inProgress:
          if (todo.status != TodoStatus.inProgress) return false;
          break;
        case FilterStatus.completed:
          if (todo.status != TodoStatus.completed) return false;
          break;
        case FilterStatus.cancelled:
          if (todo.status != TodoStatus.cancelled) return false;
          break;
        case FilterStatus.all:
          break;
      }

      // Priority filter
      if (priorityFilter != null && todo.priority != priorityFilter) {
        return false;
      }

      // Due date range filter
      if (dueDateFrom != null || dueDateTo != null) {
        final todoDueDate = todo.dueDate;
        if (todoDueDate == null) return false;
        
        if (dueDateFrom != null && todoDueDate.isBefore(dueDateFrom)) {
          return false;
        }
        
        if (dueDateTo != null && todoDueDate.isAfter(dueDateTo)) {
          return false;
        }
      }

      // Category filter
      if (categoryFilter != null && todo.categoryId != categoryFilter) {
        return false;
      }

      // Tag filters
      if (tagFilters.isNotEmpty) {
        final todoTagIds = todo.tagIds;
        final hasMatchingTag = tagFilters.any((tagId) => todoTagIds.contains(tagId));
        if (!hasMatchingTag) return false;
      }

      return true;
    }).toList();
  }

  /// Search categories by name
  List<Category> _searchCategories(List<Category> categories, String query) {
    return categories.where((category) {
      final nameMatch = category.name.toLowerCase().contains(query);
      return nameMatch;
    }).toList();
  }

  /// Search tags by name
  List<Tag> _searchTags(List<Tag> tags, String query) {
    return tags.where((tag) {
      return tag.name.toLowerCase().contains(query);
    }).toList();
  }

  /// Sort todos based on the specified option
  List<Todo> _sortTodos(List<Todo> todos, SortOption sortBy) {
    final sortedTodos = List<Todo>.from(todos);
    
    switch (sortBy) {
      case SortOption.dateCreated:
        sortedTodos.sort((a, b) {
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case SortOption.dateUpdated:
        sortedTodos.sort((a, b) {
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
      case SortOption.priority:
        sortedTodos.sort((a, b) {
          return _comparePriority(a.priority, b.priority);
        });
        break;
      case SortOption.title:
        sortedTodos.sort((a, b) {
          return a.title.compareTo(b.title);
        });
        break;
      case SortOption.dueDate:
        sortedTodos.sort((a, b) {
          final aDueDate = a.dueDate;
          final bDueDate = b.dueDate;
          if (aDueDate == null && bDueDate == null) return 0;
          if (aDueDate == null) return 1;
          if (bDueDate == null) return -1;
          return aDueDate.compareTo(bDueDate);
        });
        break;
    }
    
    return sortedTodos;
  }

  /// Helper method to compare priorities
  int _comparePriority(Priority a, Priority b) {
    const priorityOrder = {
      Priority.high: 0,
      Priority.medium: 1,
      Priority.low: 2,
    };
    return (priorityOrder[a] ?? 999).compareTo(priorityOrder[b] ?? 999);
  }

  /// Get search suggestions based on existing data
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];

    final suggestions = <String>{};
    final lowercaseQuery = query.toLowerCase();

    // Get suggestions from todos
    final todos = await _todoRepository.getAllTodos();
    for (final todo in todos) {
      if (todo.title.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(todo.title);
      }
    }

    // Get suggestions from categories
    final categories = await _categoryRepository.getAllCategories();
    for (final category in categories) {
      if (category.name.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(category.name);
      }
    }

    // Get suggestions from tags
    final tags = await _tagRepository.getAllTags();
    for (final tag in tags) {
      if (tag.name.toLowerCase().contains(lowercaseQuery)) {
        suggestions.add(tag.name);
      }
    }

    return suggestions.take(10).toList();
  }

  /// Get popular search terms (could be enhanced with actual usage tracking)
  Future<List<String>> getPopularSearches() async {
    // For now, return some common search terms based on existing data
    final suggestions = <String>{};

    final categories = await _categoryRepository.getAllCategories();
    suggestions.addAll(categories.map((c) => c.name));

    final tags = await _tagRepository.getAllTags();
    suggestions.addAll(tags.map((t) => t.name));

    return suggestions.take(5).toList();
  }
}