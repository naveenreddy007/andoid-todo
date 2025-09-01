import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../domain/entities/todo.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/todo_status.dart';
import '../widgets/todo_card.dart';
import 'todo_editor_screen.dart';
import '../../core/utils/date_time_utils.dart';
import '../../providers/todo_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final todosAsyncValue = ref.watch(todosProvider);
    
    // Debug logging
    todosAsyncValue.when(
      data: (todos) => print('🏠 HomeScreen: Received ${todos.length} todos from provider'),
      loading: () => print('🏠 HomeScreen: Loading todos...'),
      error: (error, stack) => print('🏠 HomeScreen: Error loading todos: $error'),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: todosAsyncValue.when(
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Symbols.task_alt,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Welcome to Todo App',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first todo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(todosProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
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
                    onComplete: () {
                      if (todo.status == TodoStatus.completed) {
                        ref.read(todoOperationsProvider.notifier).uncompleteTodo(todo.id);
                      } else {
                        ref.read(todoOperationsProvider.notifier).completeTodo(todo.id);
                      }
                    },
                    onDelete: () => _showDeleteConfirmation(todo),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
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
                'Error loading todos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(todosProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TodoEditorScreen(),
            ),
          );
        },
        tooltip: 'Add Todo',
        child: const Icon(Symbols.add),
      ),
    );
  }

  void _showDeleteConfirmation(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(todoOperationsProvider.notifier).deleteTodo(todo.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
