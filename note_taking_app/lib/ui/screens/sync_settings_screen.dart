import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../providers/sync_provider.dart';
import '../../data/services/sync_manager.dart';
import '../widgets/sync_status_indicator.dart';
import '../widgets/sync_progress_indicator.dart';
import '../widgets/conflict_resolution_dialog.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize sync manager when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncOperationsProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncSettings = ref.watch(syncSettingsProvider);
    final syncStatus = ref.watch(currentSyncStatusProvider);
    final isAuthenticated = ref.watch(authStatusProvider);
    final canSync = ref.watch(canSyncProvider);
    final statusMessage = ref.watch(syncStatusMessageProvider);
    final hasConflicts = ref.watch(hasConflictsProvider);
    final syncOperations = ref.watch(syncOperationsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showSyncHelp(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status Card
            _buildSyncStatusCard(context, syncStatus, statusMessage, hasConflicts),
            const SizedBox(height: 16),
            
            // Authentication Section
            _buildAuthenticationSection(context, isAuthenticated),
            const SizedBox(height: 16),
            
            // Sync Actions Section
            if (isAuthenticated) ..[
              _buildSyncActionsSection(context, canSync, hasConflicts),
              const SizedBox(height: 16),
            ],
            
            // Auto Sync Settings
            _buildAutoSyncSettings(context, syncSettings),
            const SizedBox(height: 16),
            
            // Sync Preferences
            _buildSyncPreferences(context, syncSettings),
            const SizedBox(height: 16),
            
            // Conflict Resolution Settings
            _buildConflictResolutionSettings(context, syncSettings),
            const SizedBox(height: 16),
            
            // Sync Statistics
            if (isAuthenticated) _buildSyncStatistics(context),
            
            // Loading overlay
            if (syncOperations.isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncStatusCard(BuildContext context, SyncStatus status, String message, bool hasConflicts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_sync, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SyncStatusIndicator(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (hasConflicts) ..[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Conflicts need resolution',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const SyncProgressIndicator(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuthenticationSection(BuildContext context, bool isAuthenticated) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAuthenticated ? Icons.account_circle : Icons.account_circle_outlined,
                  size: 24,
                  color: isAuthenticated ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Google Drive Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isAuthenticated
                  ? 'Connected to Google Drive'
                  : 'Sign in to enable sync',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => isAuthenticated ? _signOut() : _signIn(),
                icon: Icon(isAuthenticated ? Icons.logout : Icons.login),
                label: Text(isAuthenticated ? 'Sign Out' : 'Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAuthenticated
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncActionsSection(BuildContext context, bool canSync, bool hasConflicts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sync Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasConflicts) ..[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _resolveConflicts(),
                  icon: const Icon(Icons.build),
                  label: const Text('Resolve Conflicts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canSync ? () => _performSync(SyncDirection.bidirectional) : null,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sync Now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canSync ? () => _showSyncOptions() : null,
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('Options'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAutoSyncSettings(BuildContext context, SyncSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Auto Sync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Enable Auto Sync'),
              subtitle: const Text('Automatically sync data in the background'),
              value: settings.autoSyncEnabled,
              onChanged: (value) {
                ref.read(syncSettingsProvider.notifier).updateAutoSyncEnabled(value);
                if (value) {
                  ref.read(syncOperationsProvider.notifier).startAutoSync(
                    interval: settings.autoSyncInterval,
                  );
                } else {
                  ref.read(syncOperationsProvider.notifier).stopAutoSync();
                }
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (settings.autoSyncEnabled) ..[
              const Divider(),
              ListTile(
                title: const Text('Sync Interval'),
                subtitle: Text(_formatDuration(settings.autoSyncInterval)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showIntervalPicker(settings.autoSyncInterval),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncPreferences(BuildContext context, SyncSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sync Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('WiFi Only'),
              subtitle: const Text('Only sync when connected to WiFi'),
              value: settings.syncOnWifiOnly,
              onChanged: (value) {
                ref.read(syncSettingsProvider.notifier).updateSyncOnWifiOnly(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Sync Notifications'),
              subtitle: const Text('Show notifications for sync events'),
              value: settings.showSyncNotifications,
              onChanged: (value) {
                ref.read(syncSettingsProvider.notifier).updateShowSyncNotifications(value);
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConflictResolutionSettings(BuildContext context, SyncSettings settings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.merge_type, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Conflict Resolution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Default Strategy'),
              subtitle: Text(_getConflictStrategyDescription(settings.conflictResolution)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showConflictStrategyPicker(settings.conflictResolution),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncStatistics(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sync Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final statsAsync = ref.watch(syncStatsProvider);
                final lastSyncAsync = ref.watch(lastSyncTimeProvider);
                
                return statsAsync.when(
                  data: (stats) => Column(
                    children: [
                      _buildStatRow('Total Syncs', stats['totalSyncs']?.toString() ?? '0'),
                      _buildStatRow('Successful Syncs', stats['successfulSyncs']?.toString() ?? '0'),
                      _buildStatRow('Failed Syncs', stats['failedSyncs']?.toString() ?? '0'),
                      _buildStatRow('Conflicts Resolved', stats['conflictsResolved']?.toString() ?? '0'),
                      lastSyncAsync.when(
                        data: (lastSync) => _buildStatRow(
                          'Last Sync',
                          lastSync != null ? _formatDateTime(lastSync) : 'Never',
                        ),
                        loading: () => _buildStatRow('Last Sync', 'Loading...'),
                        error: (_, __) => _buildStatRow('Last Sync', 'Unknown'),
                      ),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Error loading stats: $error'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} minutes';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hours';
    } else {
      return '${duration.inDays} days';
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
  
  String _getConflictStrategyDescription(ConflictResolutionStrategy strategy) {
    switch (strategy) {
      case ConflictResolutionStrategy.askUser:
        return 'Ask me what to do';
      case ConflictResolutionStrategy.useLocal:
        return 'Always use local version';
      case ConflictResolutionStrategy.useRemote:
        return 'Always use remote version';
      case ConflictResolutionStrategy.useMostRecent:
        return 'Use most recently modified';
    }
  }
  
  // Action methods
  Future<void> _signIn() async {
    final success = await ref.read(syncOperationsProvider.notifier).signIn();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully signed in to Google Drive'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in to Google Drive'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Google Drive?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(syncOperationsProvider.notifier).signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out of Google Drive'),
          ),
        );
      }
    }
  }
  
  Future<void> _performSync(SyncDirection direction) async {
    final success = await ref.read(syncOperationsProvider.notifier).performSync(direction);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sync completed successfully' : 'Sync failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
  
  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Upload to Drive'),
              subtitle: const Text('Upload local changes to Google Drive'),
              onTap: () {
                Navigator.pop(context);
                _performSync(SyncDirection.upload);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download from Drive'),
              subtitle: const Text('Download changes from Google Drive'),
              onTap: () {
                Navigator.pop(context);
                _performSync(SyncDirection.download);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Bidirectional Sync'),
              subtitle: const Text('Sync changes in both directions'),
              onTap: () {
                Navigator.pop(context);
                _performSync(SyncDirection.bidirectional);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Force Upload All'),
              subtitle: const Text('Upload all data, overwriting remote'),
              onTap: () {
                Navigator.pop(context);
                _showForceUploadConfirmation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Force Download All'),
              subtitle: const Text('Download all data, overwriting local'),
              onTap: () {
                Navigator.pop(context);
                _showForceDownloadConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showForceUploadConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Upload All'),
        content: const Text(
          'This will upload all local data to Google Drive, overwriting any existing remote data. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(syncOperationsProvider.notifier).forceUpload();
            },
            child: const Text('Force Upload'),
          ),
        ],
      ),
    );
  }
  
  void _showForceDownloadConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Download All'),
        content: const Text(
          'This will download all data from Google Drive, overwriting any existing local data. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(syncOperationsProvider.notifier).forceDownload();
            },
            child: const Text('Force Download'),
          ),
        ],
      ),
    );
  }
  
  void _resolveConflicts() {
    showDialog(
      context: context,
      builder: (context) => const ConflictResolutionDialog(),
    );
  }
  
  void _showIntervalPicker(Duration currentInterval) {
    final intervals = [
      const Duration(minutes: 5),
      const Duration(minutes: 15),
      const Duration(minutes: 30),
      const Duration(hours: 1),
      const Duration(hours: 2),
      const Duration(hours: 6),
      const Duration(hours: 12),
      const Duration(days: 1),
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((interval) {
            return RadioListTile<Duration>(
              title: Text(_formatDuration(interval)),
              value: interval,
              groupValue: currentInterval,
              onChanged: (value) {
                if (value != null) {
                  ref.read(syncSettingsProvider.notifier).updateAutoSyncInterval(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showConflictStrategyPicker(ConflictResolutionStrategy currentStrategy) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict Resolution Strategy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ConflictResolutionStrategy.values.map((strategy) {
            return RadioListTile<ConflictResolutionStrategy>(
              title: Text(_getConflictStrategyDescription(strategy)),
              value: strategy,
              groupValue: currentStrategy,
              onChanged: (value) {
                if (value != null) {
                  ref.read(syncSettingsProvider.notifier).updateConflictResolution(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  
  void _showSyncHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Google Drive Sync',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This feature allows you to synchronize your todos, categories, and tags with Google Drive for backup and cross-device access.',
              ),
              SizedBox(height: 16),
              Text(
                'Sync Types:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Upload: Send local changes to Google Drive'),
              Text('• Download: Get changes from Google Drive'),
              Text('• Bidirectional: Sync changes in both directions'),
              SizedBox(height: 16),
              Text(
                'Conflict Resolution:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('When the same item is modified both locally and remotely, conflicts occur. You can choose how to resolve them automatically or manually.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}