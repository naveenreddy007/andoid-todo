enum TodoStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TodoStatus.pending:
        return 'Pending';
      case TodoStatus.inProgress:
        return 'In Progress';
      case TodoStatus.completed:
        return 'Completed';
      case TodoStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isCompleted => this == TodoStatus.completed;
  bool get isPending => this == TodoStatus.pending;
  bool get isInProgress => this == TodoStatus.inProgress;
  bool get isCancelled => this == TodoStatus.cancelled;
}