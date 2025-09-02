import 'dart:math';
import '../domain/entities/category.dart';
import '../domain/entities/tag.dart';
import '../domain/entities/todo.dart';
import '../domain/entities/priority.dart';
import '../domain/entities/todo_status.dart';
import '../domain/entities/reminder.dart';

import '../services/local/database_helper.dart';
import '../data/repositories/local_category_repository.dart';
import '../data/repositories/local_tag_repository.dart';
import '../data/repositories/local_todo_repository.dart';
import '../data/repositories/local_reminder_repository.dart';

class DatabasePush {
  final DatabaseHelper _databaseHelper;
  late final LocalCategoryRepository _categoryRepository;
  late final LocalTagRepository _tagRepository;
  late final LocalTodoRepository _todoRepository;
  late final LocalReminderRepository _reminderRepository;
  final Random _random = Random();

  DatabasePush(this._databaseHelper) {
    _categoryRepository = LocalCategoryRepository(_databaseHelper);
    _tagRepository = LocalTagRepository(_databaseHelper);
    _todoRepository = LocalTodoRepository(_databaseHelper);
    _reminderRepository = LocalReminderRepository(_databaseHelper);
  }

  /// Push comprehensive test data to the database
  Future<void> pushTestData() async {
    print('🚀 Starting database push with test data...');
    
    try {
      // Clear existing data first
      await _clearExistingData();
      
      // Create categories
      final categories = await _createCategories();
      print('✅ Created ${categories.length} categories');
      
      // Create tags
      final tags = await _createTags();
      print('✅ Created ${tags.length} tags');
      
      // Create todos with various attributes
      final todos = await _createTodos(categories, tags);
      print('✅ Created ${todos.length} todos');
      
      // Create reminders for some todos
      final reminders = await _createReminders(todos);
      print('✅ Created ${reminders.length} reminders');
      
      print('🎉 Database push completed successfully!');
      print('📊 Summary:');
      print('   - Categories: ${categories.length}');
      print('   - Tags: ${tags.length}');
      print('   - Todos: ${todos.length}');
      print('   - Reminders: ${reminders.length}');
      
    } catch (e) {
      print('❌ Error during database push: $e');
      rethrow;
    }
  }

  Future<void> _clearExistingData() async {
    print('🧹 Clearing existing data...');
    // Note: This will clear all data - use with caution
    final db = await _databaseHelper.database;
    await db.delete('todo_tags');
    await db.delete('reminders');
    await db.delete('todos');
    await db.delete('tags');
    await db.delete('categories');
  }

  Future<List<Category>> _createCategories() async {
    final categories = [
      Category(
        id: _generateId(),
        name: 'Personal',
        color: '#FF6B6B',
        icon: 'person',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Category(
        id: _generateId(),
        name: 'Work',
        color: '#4ECDC4',
        icon: 'work',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      Category(
        id: _generateId(),
        name: 'Shopping',
        color: '#45B7D1',
        icon: 'shopping_cart',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Category(
        id: _generateId(),
        name: 'Health',
        color: '#96CEB4',
        icon: 'health_and_safety',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Category(
        id: _generateId(),
        name: 'Study',
        color: '#FFEAA7',
        icon: 'school',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Category(
        id: _generateId(),
        name: 'Travel',
        color: '#DDA0DD',
        icon: 'flight',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Category(
        id: _generateId(),
        name: 'Finance',
        color: '#98D8C8',
        icon: 'account_balance',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Category(
        id: _generateId(),
        name: 'Fitness',
        color: '#F7DC6F',
        icon: 'fitness_center',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];

    for (final category in categories) {
      await _categoryRepository.saveCategory(category);
    }

    return categories;
  }

  Future<List<Tag>> _createTags() async {
    final tags = [
      Tag(
        id: _generateId(),
        name: 'Urgent',
        color: '#FF4757',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      Tag(
        id: _generateId(),
        name: 'Important',
        color: '#FF6348',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
      Tag(
        id: _generateId(),
        name: 'Quick',
        color: '#2ED573',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      Tag(
        id: _generateId(),
        name: 'Meeting',
        color: '#3742FA',
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Tag(
        id: _generateId(),
        name: 'Review',
        color: '#F79F1F',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Tag(
        id: _generateId(),
        name: 'Planning',
        color: '#A55EEA',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Tag(
        id: _generateId(),
        name: 'Research',
        color: '#26D0CE',
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      Tag(
        id: _generateId(),
        name: 'Follow-up',
        color: '#FD79A8',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Tag(
        id: _generateId(),
        name: 'Creative',
        color: '#FDCB6E',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Tag(
        id: _generateId(),
        name: 'Maintenance',
        color: '#6C5CE7',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (final tag in tags) {
      await _tagRepository.saveTag(tag);
    }

    return tags;
  }

  Future<List<Todo>> _createTodos(List<Category> categories, List<Tag> tags) async {
    final todoTemplates = [
      {
        'title': 'Complete quarterly report',
        'description': 'Analyze Q4 performance metrics and prepare comprehensive report for stakeholders. Include revenue analysis, customer satisfaction scores, and growth projections.',
        'priority': Priority.high,
        'status': TodoStatus.inProgress,
        'categoryIndex': 1, // Work
        'tagIndices': [0, 1], // Urgent, Important
        'daysFromNow': 2,
      },
      {
        'title': 'Buy groceries for the week',
        'description': 'Weekly grocery shopping: milk, bread, eggs, vegetables, fruits, chicken, rice, and cleaning supplies. Check pantry before leaving.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 2, // Shopping
        'tagIndices': [2], // Quick
        'daysFromNow': 1,
      },
      {
        'title': 'Schedule annual health checkup',
        'description': 'Book appointment with Dr. Smith for annual physical examination. Include blood work, vision test, and dental cleaning.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 3, // Health
        'tagIndices': [1, 7], // Important, Follow-up
        'daysFromNow': 7,
      },
      {
        'title': 'Prepare presentation for client meeting',
        'description': 'Create PowerPoint presentation for ABC Corp meeting. Include project timeline, budget breakdown, and deliverables overview.',
        'priority': Priority.high,
        'status': TodoStatus.pending,
        'categoryIndex': 1, // Work
        'tagIndices': [0, 3], // Urgent, Meeting
        'daysFromNow': 3,
      },
      {
        'title': 'Study for certification exam',
        'description': 'Review chapters 8-12 for AWS Solutions Architect certification. Practice with mock exams and review weak areas.',
        'priority': Priority.high,
        'status': TodoStatus.inProgress,
        'categoryIndex': 4, // Study
        'tagIndices': [1, 6], // Important, Research
        'daysFromNow': 14,
      },
      {
        'title': 'Plan weekend trip to mountains',
        'description': 'Research hiking trails, book accommodation, check weather forecast, and prepare packing list for 2-day mountain trip.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 5, // Travel
        'tagIndices': [5, 8], // Planning, Creative
        'daysFromNow': 10,
      },
      {
        'title': 'Update investment portfolio',
        'description': 'Review current stock performance, rebalance portfolio allocation, and research new investment opportunities.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 6, // Finance
        'tagIndices': [4, 6], // Review, Research
        'daysFromNow': 5,
      },
      {
        'title': 'Morning workout routine',
        'description': '45-minute workout: 15 min cardio, 20 min strength training, 10 min stretching. Focus on core and upper body today.',
        'priority': Priority.medium,
        'status': TodoStatus.completed,
        'categoryIndex': 7, // Fitness
        'tagIndices': [2], // Quick
        'daysFromNow': 0,
      },
      {
        'title': 'Call mom for birthday',
        'description': 'Wish mom happy birthday and catch up on family news. Ask about her health and upcoming family events.',
        'priority': Priority.high,
        'status': TodoStatus.completed,
        'categoryIndex': 0, // Personal
        'tagIndices': [0, 1], // Urgent, Important
        'daysFromNow': -2,
      },
      {
        'title': 'Fix leaky kitchen faucet',
        'description': 'Replace worn-out washer in kitchen faucet. Check if we have spare parts or need to buy from hardware store.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 0, // Personal
        'tagIndices': [9], // Maintenance
        'daysFromNow': 3,
      },
      {
        'title': 'Team building event planning',
        'description': 'Organize quarterly team building event. Research venues, activities, catering options, and send invitations to team members.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 1, // Work
        'tagIndices': [5, 8], // Planning, Creative
        'daysFromNow': 21,
      },
      {
        'title': 'Buy new running shoes',
        'description': 'Current shoes have 500+ miles. Research best running shoes for flat feet, read reviews, and visit store for fitting.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 2, // Shopping
        'tagIndices': [6], // Research
        'daysFromNow': 7,
      },
      {
        'title': 'Dental cleaning appointment',
        'description': 'Bi-annual dental cleaning and checkup. Schedule with Dr. Johnson and confirm insurance coverage.',
        'priority': Priority.medium,
        'status': TodoStatus.completed,
        'categoryIndex': 3, // Health
        'tagIndices': [7], // Follow-up
        'daysFromNow': -5,
      },
      {
        'title': 'Learn new programming language',
        'description': 'Start learning Rust programming language. Complete online course modules and build a small project to practice.',
        'priority': Priority.low,
        'status': TodoStatus.inProgress,
        'categoryIndex': 4, // Study
        'tagIndices': [6, 8], // Research, Creative
        'daysFromNow': 30,
      },
      {
        'title': 'Book flight for conference',
        'description': 'Book round-trip flight to San Francisco for tech conference. Compare prices and check baggage policies.',
        'priority': Priority.high,
        'status': TodoStatus.pending,
        'categoryIndex': 5, // Travel
        'tagIndices': [0, 6], // Urgent, Research
        'daysFromNow': 4,
      },
      {
        'title': 'Review monthly budget',
        'description': 'Analyze last month\'s expenses, categorize spending, and adjust budget for next month. Look for cost-saving opportunities.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 6, // Finance
        'tagIndices': [4], // Review
        'daysFromNow': 2,
      },
      {
        'title': 'Join local hiking group',
        'description': 'Research local hiking clubs, attend a meetup, and sign up for regular weekend hikes to stay active.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 7, // Fitness
        'tagIndices': [6, 8], // Research, Creative
        'daysFromNow': 14,
      },
      {
        'title': 'Organize photo albums',
        'description': 'Sort through digital photos from last year, create albums by event/date, and backup to cloud storage.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 0, // Personal
        'tagIndices': [8, 9], // Creative, Maintenance
        'daysFromNow': 20,
      },
      {
        'title': 'Code review for new feature',
        'description': 'Review pull request for user authentication feature. Check for security vulnerabilities and code quality.',
        'priority': Priority.high,
        'status': TodoStatus.inProgress,
        'categoryIndex': 1, // Work
        'tagIndices': [0, 4], // Urgent, Review
        'daysFromNow': 1,
      },
      {
        'title': 'Buy birthday gift for sister',
        'description': 'Find perfect birthday gift for sister. She likes books, jewelry, and art supplies. Budget: \$50-100.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 2, // Shopping
        'tagIndices': [1, 8], // Important, Creative
        'daysFromNow': 8,
      },
      {
        'title': 'Meditation practice',
        'description': 'Daily 20-minute meditation session. Focus on breathing techniques and mindfulness exercises.',
        'priority': Priority.medium,
        'status': TodoStatus.inProgress,
        'categoryIndex': 3, // Health
        'tagIndices': [2], // Quick
        'daysFromNow': 0,
      },
      {
        'title': 'Research graduate programs',
        'description': 'Look into MBA programs at top universities. Compare curriculum, costs, and admission requirements.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 4, // Study
        'tagIndices': [6, 5], // Research, Planning
        'daysFromNow': 45,
      },
      {
        'title': 'Plan summer vacation',
        'description': 'Research destinations for 2-week summer vacation. Consider Europe tour or beach resort. Check visa requirements.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 5, // Travel
        'tagIndices': [5, 6], // Planning, Research
        'daysFromNow': 60,
      },
      {
        'title': 'Set up emergency fund',
        'description': 'Open high-yield savings account for emergency fund. Target: 6 months of expenses. Research best rates.',
        'priority': Priority.high,
        'status': TodoStatus.pending,
        'categoryIndex': 6, // Finance
        'tagIndices': [1, 6], // Important, Research
        'daysFromNow': 7,
      },
      {
        'title': 'Train for 5K race',
        'description': 'Follow 8-week training plan for upcoming 5K charity race. Gradually increase distance and pace.',
        'priority': Priority.medium,
        'status': TodoStatus.inProgress,
        'categoryIndex': 7, // Fitness
        'tagIndices': [5], // Planning
        'daysFromNow': 56,
      },
      {
        'title': 'Clean garage',
        'description': 'Deep clean and organize garage. Donate unused items, organize tools, and create storage system.',
        'priority': Priority.low,
        'status': TodoStatus.pending,
        'categoryIndex': 0, // Personal
        'tagIndices': [9], // Maintenance
        'daysFromNow': 15,
      },
      {
        'title': 'Update resume',
        'description': 'Refresh resume with recent projects and achievements. Tailor for software engineering positions.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 1, // Work
        'tagIndices': [4, 8], // Review, Creative
        'daysFromNow': 12,
      },
      {
        'title': 'Buy winter clothes',
        'description': 'Shop for winter wardrobe: warm coat, boots, gloves, and scarves. Check for sales and quality.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 2, // Shopping
        'tagIndices': [6], // Research
        'daysFromNow': 25,
      },
      {
        'title': 'Eye exam appointment',
        'description': 'Annual eye exam with optometrist. Check if prescription needs updating and screen for eye diseases.',
        'priority': Priority.medium,
        'status': TodoStatus.pending,
        'categoryIndex': 3, // Health
        'tagIndices': [1, 7], // Important, Follow-up
        'daysFromNow': 18,
      },
      {
        'title': 'Complete online course',
        'description': 'Finish "Machine Learning Fundamentals" course on Coursera. Complete final project and get certificate.',
        'priority': Priority.medium,
        'status': TodoStatus.inProgress,
        'categoryIndex': 4, // Study
        'tagIndices': [1], // Important
        'daysFromNow': 21,
      },
    ];

    final todos = <Todo>[];
    
    for (int i = 0; i < todoTemplates.length; i++) {
      final template = todoTemplates[i];
      final dueDate = DateTime.now().add(Duration(days: template['daysFromNow'] as int));
      
      final todo = Todo(
        id: _generateId(),
        title: template['title'] as String,
        description: template['description'] as String,
        priority: template['priority'] as Priority,
        status: template['status'] as TodoStatus,
        categoryId: categories[template['categoryIndex'] as int].id,
        dueDate: dueDate,
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(5))),
      );
      
      await _todoRepository.saveTodo(todo);
      todos.add(todo);
      
      // Add tags to todo
      final tagIndices = template['tagIndices'] as List<int>;
      for (final tagIndex in tagIndices) {
        await _tagRepository.addTagToTodo(todo.id, tags[tagIndex].id);
      }
    }

    return todos;
  }

  Future<List<Reminder>> _createReminders(List<Todo> todos) async {
    final reminders = <Reminder>[];
    
    // Create reminders for about 40% of todos
    final todosWithReminders = todos.where((todo) => _random.nextBool() && _random.nextBool()).toList();
    
    for (final todo in todosWithReminders) {
      if (todo.dueDate != null && todo.dueDate!.isAfter(DateTime.now())) {
        final reminderTypes = [ReminderType.oneTime, ReminderType.recurring];
        final reminderType = reminderTypes[_random.nextInt(reminderTypes.length)];
        
        // Set reminder 1-24 hours before due date
        final hoursBeforeDue = _random.nextInt(24) + 1;
        final reminderTime = todo.dueDate!.subtract(Duration(hours: hoursBeforeDue));
        
        if (reminderTime.isAfter(DateTime.now())) {
          final reminder = Reminder(
            id: _generateId(),
            todoId: todo.id,
            dateTime: reminderTime,
            type: reminderType,
            createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(10))),
          );
          
          await _reminderRepository.saveReminder(reminder);
          reminders.add(reminder);
        }
      }
    }
    
    return reminders;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + _random.nextInt(1000).toString();
  }
}