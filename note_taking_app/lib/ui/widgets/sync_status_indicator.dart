import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/sync_manager.dart';
import '../../providers/sync_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final SyncStatus? status;
  final bool showLabel;
  final double size;
  
  const SyncStatusIndicator({
    super.key,
    this.status,
    this.showLabel = false,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = status ?? ref.watch(currentSyncStatusProvider);
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(currentStatus, theme),
        if (showLabel) ..[
          const SizedBox(width: 8),
          Text(
            _getStatusLabel(currentStatus),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(currentStatus, theme),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildStatusIcon(SyncStatus status, ThemeData theme) {
    final color = _getStatusColor(status, theme);
    
    switch (status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_outlined,
          size: size,
          color: color,
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      case SyncStatus.success:
        return Icon(
          Icons.cloud_done,
          size: size,
          color: color,
        );
      case SyncStatus.error:
        return Icon(
          Icons.cloud_off,
          size: size,
          color: color,
        );
      case SyncStatus.conflict:
        return Icon(
          Icons.warning,
          size: size,
          color: color,
        );
      case SyncStatus.noInternet:
        return Icon(
          Icons.wifi_off,
          size: size,
          color: color,
        );
      case SyncStatus.notAuthenticated:
        return Icon(
          Icons.account_circle_outlined,
          size: size,
          color: color,
        );
    }
  }
  
  Color _getStatusColor(SyncStatus status, ThemeData theme) {
    switch (status) {
      case SyncStatus.idle:
        return theme.colorScheme.onSurface.withOpacity(0.6);
      case SyncStatus.syncing:
        return theme.colorScheme.primary;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return theme.colorScheme.error;
      case SyncStatus.conflict:
        return Colors.orange;
      case SyncStatus.noInternet:
        return theme.colorScheme.onSurface.withOpacity(0.4);
      case SyncStatus.notAuthenticated:
        return theme.colorScheme.onSurface.withOpacity(0.4);
    }
  }
  
  String _getStatusLabel(SyncStatus status) {
    switch (status) {
      case SyncStatus.idle:
        return 'Ready';
      case SyncStatus.syncing:
        return 'Syncing';
      case SyncStatus.success:
        return 'Synced';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.conflict:
        return 'Conflicts';
      case SyncStatus.noInternet:
        return 'Offline';
      case SyncStatus.notAuthenticated:
        return 'Not signed in';
    }
  }
}

/// A compact sync status indicator for use in app bars or toolbars
class CompactSyncStatusIndicator extends ConsumerWidget {
  final VoidCallback? onTap;
  
  const CompactSyncStatusIndicator({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(currentSyncStatusProvider);
    final hasConflicts = ref.watch(hasConflictsProvider);
    final isAuthenticated = ref.watch(authStatusProvider);
    
    if (!isAuthenticated) {
      return IconButton(
        icon: const Icon(Icons.cloud_off),
        onPressed: onTap,
        tooltip: 'Not signed in to Google Drive',
      );
    }
    
    return IconButton(
      icon: Stack(
        children: [
          SyncStatusIndicator(status: status, size: 24),
          if (hasConflicts)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: onTap,
      tooltip: _getTooltip(status, hasConflicts),
    );
  }
  
  String _getTooltip(SyncStatus status, bool hasConflicts) {
    if (hasConflicts) {
      return 'Sync conflicts need resolution';
    }
    
    switch (status) {
      case SyncStatus.idle:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing with Google Drive';
      case SyncStatus.success:
        return 'Sync completed successfully';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.conflict:
        return 'Conflicts need resolution';
      case SyncStatus.noInternet:
        return 'No internet connection';
      case SyncStatus.notAuthenticated:
        return 'Not signed in to Google Drive';
    }
  }
}

/// A detailed sync status card for use in settings or status screens
class DetailedSyncStatusCard extends ConsumerWidget {
  final VoidCallback? onTap;
  
  const DetailedSyncStatusCard({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(currentSyncStatusProvider);
    final statusMessage = ref.watch(syncStatusMessageProvider);
    final hasConflicts = ref.watch(hasConflictsProvider);
    final lastSyncAsync = ref.watch(lastSyncTimeProvider);
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SyncStatusIndicator(status: status, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sync Status',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          statusMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasConflicts)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Conflicts',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              if (status == SyncStatus.success) ..[
                const SizedBox(height: 8),
                lastSyncAsync.when(
                  data: (lastSync) => Text(
                    lastSync != null
                        ? 'Last synced ${_formatLastSync(lastSync)}'
                        : 'Never synced',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  loading: () => Text(
                    'Loading...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'on ${lastSync.day}/${lastSync.month}';
    }
  }
}

/// A floating action button that shows sync status and allows quick sync
class SyncFab extends ConsumerWidget {
  final VoidCallback? onPressed;
  final bool mini;
  
  const SyncFab({
    super.key,
    this.onPressed,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(currentSyncStatusProvider);
    final canSync = ref.watch(canSyncProvider);
    final hasConflicts = ref.watch(hasConflictsProvider);
    
    return FloatingActionButton(
      onPressed: canSync && !hasConflicts ? onPressed : null,
      mini: mini,
      backgroundColor: _getFabColor(status, hasConflicts, context),
      child: _getFabIcon(status, hasConflicts),
    );
  }
  
  Color? _getFabColor(SyncStatus status, bool hasConflicts, BuildContext context) {
    if (hasConflicts) {
      return Colors.orange;
    }
    
    switch (status) {
      case SyncStatus.syncing:
        return Theme.of(context).colorScheme.primary;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Theme.of(context).colorScheme.error;
      default:
        return null;
    }
  }
  
  Widget _getFabIcon(SyncStatus status, bool hasConflicts) {
    if (hasConflicts) {
      return const Icon(Icons.warning);
    }
    
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case SyncStatus.success:
        return const Icon(Icons.cloud_done);
      case SyncStatus.error:
        return const Icon(Icons.cloud_off);
      default:
        return const Icon(Icons.sync);
    }
  }
}