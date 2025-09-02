import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/reminder.dart';
import '../../domain/entities/todo.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/todo_provider.dart';
import '../widgets/reminder_card.dart';
import '../widgets/reminder_form_dialog.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationStatus = ref.watch(notificationStatusProvider);
    final reminderStats = ref.watch(reminderStatsProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '🔔 Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showNotificationSettings(context),
            tooltip: 'Notification Settings',
          ),
          IconButton(
            icon: const Icon(Icons.notification_add_outlined),
            onPressed: () => _showTestNotification(),
            tooltip: 'Test Notification',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.schedule_outlined),
              text: 'Active',
            ),
            Tab(
              icon: Icon(Icons.upcoming_outlined),
              text: 'Upcoming',
            ),
            Tab(
              icon: Icon(Icons.analytics_outlined),
              text: 'Statistics',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Notification status banner
          notificationStatus.when(
            data: (enabled) => !enabled
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notifications Disabled',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              Text(
                                'Enable notifications to receive reminders',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openNotificationSettings(),
                          child: Text(
                            'Enable',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveRemindersTab(),
                _buildUpcomingRemindersTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedTabIndex < 2
          ? FloatingActionButton.extended(
              onPressed: () => _showReminderDialog(context),
              icon: const Icon(Icons.add_alarm_outlined),
              label: const Text('Add Reminder'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null,
    );
  }

  Widget _buildActiveRemindersTab() {
    final activeReminders = ref.watch(activeRemindersProvider);

    return activeReminders.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.schedule_outlined,
            title: 'No Active Reminders',
            subtitle: 'Create your first reminder to get started',
            actionText: 'Add Reminder',
            onAction: () => _showCreateReminderDialog(),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeRemindersProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              final reminder = reminders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReminderCard(
                  reminder: reminder,
                  onEdit: () => _showEditReminderDialog(reminder),
                  onDelete: () => _deleteReminder(reminder.id),
                  onToggle: () => _toggleReminder(reminder),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading reminders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(activeRemindersProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingRemindersTab() {
    final upcomingReminders = ref.watch(upcomingRemindersProvider(24));

    return upcomingReminders.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.upcoming_outlined,
            title: 'No Upcoming Reminders',
            subtitle: 'No reminders scheduled for the next 24 hours',
          );
        }

        // Group reminders by date
        final groupedReminders = <String, List<Reminder>>{};
        for (final reminder in reminders) {
          final dateKey = DateFormat('yyyy-MM-dd').format(reminder.dateTime);
          groupedReminders.putIfAbsent(dateKey, () => []).add(reminder);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(upcomingRemindersProvider(24));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedReminders.length,
            itemBuilder: (context, index) {
              final dateKey = groupedReminders.keys.elementAt(index);
              final dayReminders = groupedReminders[dateKey]!;
              final date = DateTime.parse(dateKey);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      _formatDateHeader(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  ...dayReminders.map((reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ReminderCard(
                      reminder: reminder,
                      onEdit: () => _showEditReminderDialog(reminder),
                      onDelete: () => _deleteReminder(reminder.id),
                      onToggle: () => _toggleReminder(reminder),
                      showTimeUntil: true,
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final reminderStats = ref.watch(reminderStatsProvider);

    return reminderStats.when(
      data: (stats) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reminder Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Overview cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Active',
                      stats['total']?.toString() ?? '0',
                      Icons.schedule_outlined,
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Next 24h',
                      stats['upcoming_24h']?.toString() ?? '0',
                      Icons.upcoming_outlined,
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Reminder types
              Text(
                'By Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              _buildTypeStatCard('One-time', stats['one_time'] ?? 0, Icons.event_outlined),
              const SizedBox(height: 8),
              _buildTypeStatCard('Daily', stats['daily'] ?? 0, Icons.today_outlined),
              const SizedBox(height: 8),
              _buildTypeStatCard('Weekly', stats['weekly'] ?? 0, Icons.view_week_outlined),
              const SizedBox(height: 8),
              _buildTypeStatCard('Monthly', stats['monthly'] ?? 0, Icons.calendar_month_outlined),
              
              const SizedBox(height: 24),
              
              // Actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      ListTile(
                        leading: const Icon(Icons.refresh_outlined),
                        title: const Text('Reschedule All Reminders'),
                        subtitle: const Text('Refresh all notification schedules'),
                        onTap: () => _rescheduleAllReminders(),
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.notification_add_outlined),
                        title: const Text('Test Notification'),
                        subtitle: const Text('Send a test notification'),
                        onTap: () => _showTestNotification(),
                      ),
                      
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Notification Settings'),
                        subtitle: const Text('Configure system notifications'),
                        onTap: () => _openNotificationSettings(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ..[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeStatCard(String type, int count, IconData icon) {
    final theme = Theme.of(context);
    
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(type),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEEE, MMM d').format(date);
    }
  }

  void _showCreateReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => const ReminderFormDialog(),
    );
  }

  void _showEditReminderDialog(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => ReminderFormDialog(reminder: reminder),
    );
  }

  void _deleteReminder(String reminderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(reminderOperationsProvider.notifier).deleteReminder(reminderId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleReminder(Reminder reminder) {
    if (reminder.isActive) {
      ref.read(reminderOperationsProvider.notifier).deactivateReminder(reminder.id);
    } else {
      ref.read(reminderOperationsProvider.notifier).activateReminder(reminder.id);
    }
  }

  void _rescheduleAllReminders() {
    ref.read(reminderOperationsProvider.notifier).rescheduleAllReminders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All reminders have been rescheduled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showTestNotification() {
    ref.read(reminderOperationsProvider.notifier).showTestNotification();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openNotificationSettings() {
    ref.read(reminderOperationsProvider.notifier).openNotificationSettings();
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Consumer(
                  builder: (context, ref, child) {
                    final notificationStatus = ref.watch(notificationStatusProvider);
                    
                    return notificationStatus.when(
                      data: (enabled) => Card(
                        child: ListTile(
                          leading: Icon(
                            enabled ? Icons.notifications_active : Icons.notifications_off,
                            color: enabled ? Colors.green : Colors.red,
                          ),
                          title: Text('Notifications ${enabled ? 'Enabled' : 'Disabled'}'),
                          subtitle: Text(
                            enabled
                                ? 'You will receive reminder notifications'
                                : 'Enable notifications to receive reminders',
                          ),
                          trailing: enabled
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : TextButton(
                                  onPressed: () => _openNotificationSettings(),
                                  child: const Text('Enable'),
                                ),
                        ),
                      ),
                      loading: () => const Card(
                        child: ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('Checking notification status...'),
                        ),
                      ),
                      error: (_, __) => const Card(
                        child: ListTile(
                          leading: Icon(Icons.error, color: Colors.red),
                          title: Text('Error checking notification status'),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notification_add),
                        title: const Text('Test Notification'),
                        subtitle: const Text('Send a test notification to verify setup'),
                        onTap: () => _showTestNotification(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('System Settings'),
                        subtitle: const Text('Open device notification settings'),
                        onTap: () => _openNotificationSettings(),
                      ),
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('Reschedule All'),
                        subtitle: const Text('Refresh all notification schedules'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _rescheduleAllReminders();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showReminderDialog(BuildContext context, [Reminder? reminder]) {
    showDialog(
      context: context,
      builder: (context) => ReminderFormDialog(reminder: reminder),
    );
  }
}