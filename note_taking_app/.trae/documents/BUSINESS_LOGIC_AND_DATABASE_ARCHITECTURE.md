# Business Logic and Database Architecture - Flutter Todo/Reminder Application

## 1. Project Overview

This document outlines the comprehensive business logic and database architecture for a Flutter-based todo/reminder application with offline-first functionality and Google Drive synchronization. The application follows clean architecture principles with secure local storage and intelligent notification management.

## 2. Database Schema and Entity Relationships

### 2.1 Entity Relationship Diagram

```mermaid
erDiagram
    TODOS ||--o{ TODO_TAGS : has
    CATEGORIES ||--o{ TODOS : contains
    TAGS ||--o{ TODO_TAGS : belongs_to
    TODOS ||--o{ REMINDERS : has
    TODOS ||--o{ ATTACHMENTS : contains
    TODOS ||--o{ SYNC_METADATA : tracks
    GOOGLE_DRIVE_FILES ||--o{ SYNC_METADATA : syncs
    
    TODOS {
        string id PK
        string title
        string description
        string category_id FK
        boolean is_completed
        int priority
        datetime due_date
        datetime created_at
        datetime updated_at
        datetime completed_at
        string google_drive_file_id
        boolean is_synced
        datetime last_sync_at
    }
    
    CATEGORIES {
        string id PK
        string name
        string color_hex
        string icon_name
        datetime created_at
        datetime updated_at
        boolean is_default
        int sort_order
    }
    
    TAGS {
        string id PK
        string name
        string color_hex
        datetime created_at
        int usage_count
    }
    
    TODO_TAGS {
        string todo_id FK
        string tag_id FK
        datetime created_at
    }
    
    REMINDERS {
        string id PK
        string todo_id FK
        datetime reminder_time
        string reminder_type
        boolean is_triggered
        string notification_title
        string notification_body
        datetime created_at
        boolean is_recurring
        string recurrence_pattern
    }
    
    ATTACHMENTS {
        string id PK
        string todo_id FK
        string file_name
        string file_path
        string file_type
        int file_size
        datetime created_at
        string google_drive_file_id
        boolean is_synced
    }
    
    SYNC_METADATA {
        string id PK
        string todo_id FK
        string google_drive_file_id FK
        datetime last_sync_at
        string sync_status
        string conflict_resolution
        string local_hash
        string remote_hash
        datetime created_at
        datetime updated_at
    }
    
    GOOGLE_DRIVE_FILES {
        string id PK
        string drive_file_id
        string file_name
        string mime_type
        datetime modified_time
        string etag
        int size
        datetime created_at
        datetime updated_at
    }
```

### 2.2 Database Tables Definition

#### Todos Table
```sql
CREATE TABLE todos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category_id TEXT,
    is_completed BOOLEAN DEFAULT FALSE,
    priority INTEGER DEFAULT 0,
    due_date DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,
    google_drive_file_id TEXT,
    is_synced BOOLEAN DEFAULT FALSE,
    last_sync_at DATETIME,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE INDEX idx_todos_category ON todos(category_id);
CREATE INDEX idx_todos_due_date ON todos(due_date);
CREATE INDEX idx_todos_completed ON todos(is_completed);
CREATE INDEX idx_todos_sync_status ON todos(is_synced);
```

#### Categories Table
```sql
CREATE TABLE categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color_hex TEXT DEFAULT '#2196F3',
    icon_name TEXT DEFAULT 'folder',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_default BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0
);

CREATE INDEX idx_categories_sort_order ON categories(sort_order);
```

#### Tags Table
```sql
CREATE TABLE tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    color_hex TEXT DEFAULT '#4CAF50',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    usage_count INTEGER DEFAULT 0
);

CREATE INDEX idx_tags_usage_count ON tags(usage_count DESC);
```

#### Reminders Table
```sql
CREATE TABLE reminders (
    id TEXT PRIMARY KEY,
    todo_id TEXT NOT NULL,
    reminder_time DATETIME NOT NULL,
    reminder_type TEXT DEFAULT 'notification',
    is_triggered BOOLEAN DEFAULT FALSE,
    notification_title TEXT,
    notification_body TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern TEXT,
    FOREIGN KEY (todo_id) REFERENCES todos(id) ON DELETE CASCADE
);

CREATE INDEX idx_reminders_time ON reminders(reminder_time);
CREATE INDEX idx_reminders_todo ON reminders(todo_id);
```

## 3. Clean Architecture Layers

### 3.1 Architecture Overview

```mermaid
graph TB
    subgraph "Presentation Layer"
        UI[UI Widgets]
        Screens[Screens]
        Providers[Riverpod Providers]
    end
    
    subgraph "Domain Layer"
        Entities[Entities]
        UseCases[Use Cases]
        Repositories[Repository Interfaces]
    end
    
    subgraph "Data Layer"
        RepoImpl[Repository Implementations]
        DataSources[Data Sources]
        Models[Data Models]
    end
    
    subgraph "External"
        SQLite[(SQLite Database)]
        GoogleDrive[Google Drive API]
        Notifications[Local Notifications]
        FileSystem[File System]
    end
    
    UI --> Providers
    Screens --> Providers
    Providers --> UseCases
    UseCases --> Repositories
    Repositories --> RepoImpl
    RepoImpl --> DataSources
    DataSources --> SQLite
    DataSources --> GoogleDrive
    DataSources --> Notifications
    DataSources --> FileSystem
    Models --> Entities
```

### 3.2 Layer Responsibilities

**Presentation Layer:**
- UI components and screens
- State management with Riverpod
- User input handling
- Navigation logic

**Domain Layer:**
- Business entities and rules
- Use cases for business operations
- Repository contracts
- Domain-specific exceptions

**Data Layer:**
- Repository implementations
- Data source abstractions
- Data models and mappers
- External service integrations

## 4. Business Logic Flow Diagrams

### 4.1 Todo Creation Flow

```mermaid
flowchart TD
    A[User Creates Todo] --> B[Validate Input]
    B --> C{Valid?}
    C -->|No| D[Show Error Message]
    C -->|Yes| E[Generate UUID]
    E --> F[Create Todo Entity]
    F --> G[Save to Local Database]
    G --> H[Update UI State]
    H --> I{Auto-sync Enabled?}
    I -->|Yes| J[Queue for Google Drive Sync]
    I -->|No| K[Mark as Pending Sync]
    J --> L[Background Sync Process]
    K --> M[End]
    L --> M
    D --> N[Return to Form]
```

### 4.2 Reminder Setting Flow

```mermaid
flowchart TD
    A[User Sets Reminder] --> B[Select Date/Time]
    B --> C[Choose Reminder Type]
    C --> D[Configure Recurrence]
    D --> E[Validate Reminder Time]
    E --> F{Time Valid?}
    F -->|No| G[Show Error]
    F -->|Yes| H[Create Reminder Entity]
    H --> I[Save to Database]
    I --> J[Schedule Local Notification]
    J --> K[Update Todo State]
    K --> L[Sync with Google Drive]
    L --> M[End]
    G --> B
```

### 4.3 Todo Completion Flow

```mermaid
flowchart TD
    A[User Marks Todo Complete] --> B[Update Todo Status]
    B --> C[Set Completion Timestamp]
    C --> D[Cancel Active Reminders]
    D --> E[Update Local Database]
    E --> F[Trigger Completion Animation]
    F --> G[Update UI State]
    G --> H[Queue for Sync]
    H --> I[Background Sync Process]
    I --> J[End]
```

## 5. State Management with Riverpod

### 5.1 Provider Architecture

```mermaid
graph TD
    subgraph "UI Layer"
        TodoScreen[Todo Screen]
        CategoryScreen[Category Screen]
        SettingsScreen[Settings Screen]
    end
    
    subgraph "State Providers"
        TodoProvider[Todo Provider]
        CategoryProvider[Category Provider]
        SyncProvider[Sync Provider]
        NotificationProvider[Notification Provider]
    end
    
    subgraph "Repository Providers"
        TodoRepo[Todo Repository]
        CategoryRepo[Category Repository]
        SyncRepo[Sync Repository]
    end
    
    subgraph "Service Providers"
        DatabaseService[Database Service]
        GoogleDriveService[Google Drive Service]
        NotificationService[Notification Service]
    end
    
    TodoScreen --> TodoProvider
    CategoryScreen --> CategoryProvider
    SettingsScreen --> SyncProvider
    
    TodoProvider --> TodoRepo
    CategoryProvider --> CategoryRepo
    SyncProvider --> SyncRepo
    
    TodoRepo --> DatabaseService
    SyncRepo --> GoogleDriveService
    NotificationProvider --> NotificationService
```

### 5.2 State Management Flow

```mermaid
sequenceDiagram
    participant UI as UI Widget
    participant Provider as Riverpod Provider
    participant UseCase as Use Case
    participant Repo as Repository
    participant DB as Database
    
    UI->>Provider: User Action
    Provider->>UseCase: Execute Business Logic
    UseCase->>Repo: Data Operation
    Repo->>DB: Database Query/Update
    DB-->>Repo: Result
    Repo-->>UseCase: Processed Data
    UseCase-->>Provider: Updated State
    Provider-->>UI: State Change Notification
    UI->>UI: Rebuild Widget
```

## 6. Google Drive Synchronization Workflow

### 6.1 Sync Process Overview

```mermaid
flowchart TD
    A[Sync Trigger] --> B{Internet Available?}
    B -->|No| C[Queue for Later]
    B -->|Yes| D[Authenticate with Google]
    D --> E{Auth Success?}
    E -->|No| F[Show Auth Error]
    E -->|Yes| G[Get Local Changes]
    G --> H[Get Remote Changes]
    H --> I[Compare Timestamps]
    I --> J{Conflicts?}
    J -->|Yes| K[Conflict Resolution]
    J -->|No| L[Apply Changes]
    K --> M[User Resolution]
    M --> L
    L --> N[Update Sync Metadata]
    N --> O[Update UI]
    O --> P[Schedule Next Sync]
    P --> Q[End]
    C --> Q
    F --> Q
```

### 6.2 Conflict Resolution Strategy

```mermaid
flowchart TD
    A[Conflict Detected] --> B[Compare Modification Times]
    B --> C{Local Newer?}
    C -->|Yes| D[Use Local Version]
    C -->|No| E{Remote Newer?}
    E -->|Yes| F[Use Remote Version]
    E -->|No| G[Same Timestamp]
    G --> H[Compare Content Hash]
    H --> I{Content Different?}
    I -->|Yes| J[Show User Dialog]
    I -->|No| K[No Action Needed]
    J --> L[User Chooses Version]
    L --> M[Apply Choice]
    D --> N[Update Remote]
    F --> O[Update Local]
    M --> P[Update Both]
    N --> Q[End]
    O --> Q
    P --> Q
    K --> Q
```

### 6.3 Sync Data Structure

```mermaid
classDiagram
    class SyncMetadata {
        +String id
        +String todoId
        +String googleDriveFileId
        +DateTime lastSyncAt
        +SyncStatus status
        +String localHash
        +String remoteHash
        +ConflictResolution resolution
    }
    
    class SyncStatus {
        <<enumeration>>
        PENDING
        IN_PROGRESS
        COMPLETED
        FAILED
        CONFLICT
    }
    
    class ConflictResolution {
        <<enumeration>>
        USE_LOCAL
        USE_REMOTE
        MERGE
        USER_CHOICE
    }
    
    SyncMetadata --> SyncStatus
    SyncMetadata --> ConflictResolution
```

## 7. Local Notification System

### 7.1 Notification Scheduling Flow

```mermaid
flowchart TD
    A[Reminder Created] --> B[Calculate Notification Time]
    B --> C{Recurring?}
    C -->|Yes| D[Generate Recurrence Schedule]
    C -->|No| E[Single Notification]
    D --> F[Schedule Multiple Notifications]
    E --> G[Schedule Single Notification]
    F --> H[Store in Notification Queue]
    G --> H
    H --> I[Register with System]
    I --> J{Registration Success?}
    J -->|Yes| K[Update Reminder Status]
    J -->|No| L[Log Error]
    K --> M[End]
    L --> M
```

### 7.2 Notification Handling

```mermaid
sequenceDiagram
    participant System as System Scheduler
    participant App as Flutter App
    participant Handler as Notification Handler
    participant DB as Database
    participant UI as User Interface
    
    System->>App: Notification Triggered
    App->>Handler: Process Notification
    Handler->>DB: Get Todo Details
    DB-->>Handler: Todo Data
    Handler->>Handler: Format Notification
    Handler->>System: Show Notification
    System->>UI: Display to User
    UI->>App: User Taps Notification
    App->>UI: Open Todo Details
```

### 7.3 Notification Types and Patterns

```mermaid
classDiagram
    class NotificationType {
        <<enumeration>>
        SIMPLE
        RECURRING
        LOCATION_BASED
        SMART_REMINDER
    }
    
    class RecurrencePattern {
        +String pattern
        +int interval
        +List~DayOfWeek~ days
        +DateTime endDate
        +int maxOccurrences
    }
    
    class SmartReminder {
        +String todoId
        +DateTime suggestedTime
        +double confidence
        +String reason
        +bool userAccepted
    }
    
    class NotificationPayload {
        +String todoId
        +String title
        +String body
        +Map~String,String~ data
        +String actionType
    }
    
    NotificationType --> RecurrencePattern
    NotificationType --> SmartReminder
    NotificationType --> NotificationPayload
```

## 8. Performance Optimization Strategies

### 8.1 Database Optimization

- **Indexing Strategy**: Create indexes on frequently queried columns (due_date, category_id, is_completed)
- **Query Optimization**: Use prepared statements and batch operations
- **Pagination**: Implement cursor-based pagination for large todo lists
- **Caching**: Cache frequently accessed data in memory

### 8.2 Sync Optimization

- **Incremental Sync**: Only sync changed items since last sync
- **Batch Operations**: Group multiple changes into single API calls
- **Background Sync**: Use background tasks for non-urgent syncing
- **Compression**: Compress data before uploading to Google Drive

### 8.3 UI Performance

- **Lazy Loading**: Load todo items as user scrolls
- **Virtual Scrolling**: Use virtual scrolling for large lists
- **Image Optimization**: Compress and cache attachment images
- **State Optimization**: Use Riverpod's selective rebuilding

## 9. Security Considerations

### 9.1 Data Protection

- **Local Encryption**: Encrypt sensitive data in SQLite database
- **Secure Storage**: Use Flutter Secure Storage for tokens
- **Authentication**: Implement OAuth 2.0 for Google Drive
- **Data Validation**: Validate all user inputs

### 9.2 Privacy Measures

- **Data Minimization**: Only sync necessary data to Google Drive
- **User Consent**: Request explicit permission for data sync
- **Audit Logging**: Log sync operations for transparency
- **Data Retention**: Implement data retention policies

## 10. Error Handling and Recovery

### 10.1 Error Categories

```mermaid
classDiagram
    class AppError {
        <<abstract>>
        +String message
        +String code
        +DateTime timestamp
        +Map~String,dynamic~ context
    }
    
    class DatabaseError {
        +String query
        +String table
        +String operation
    }
    
    class SyncError {
        +String syncType
        +String remoteId
        +int retryCount
    }
    
    class NetworkError {
        +int statusCode
        +String endpoint
        +bool isRetryable
    }
    
    class ValidationError {
        +String field
        +String rule
        +dynamic value
    }
    
    AppError <|-- DatabaseError
    AppError <|-- SyncError
    AppError <|-- NetworkError
    AppError <|-- ValidationError
```

### 10.2 Recovery Strategies

- **Automatic Retry**: Implement exponential backoff for transient errors
- **Graceful Degradation**: Continue working offline when sync fails
- **User Feedback**: Provide clear error messages and recovery options
- **Data Backup**: Maintain local backups before risky operations

## 11. Testing Strategy

### 11.1 Testing Pyramid

```mermaid
graph TD
    subgraph "Testing Pyramid"
        E2E["End-to-End Tests<br/>UI Flows & Integration"]
        Integration["Integration Tests<br/>Repository & Service Layer"]
        Unit["Unit Tests<br/>Business Logic & Entities"]
    end
    
    Unit --> Integration
    Integration --> E2E
    
    style Unit fill:#4CAF50
    style Integration fill:#FF9800
    style E2E fill:#F44336
```

### 11.2 Test Coverage Areas

- **Unit Tests**: Business logic, entities, use cases
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Database operations, API calls
- **End-to-End Tests**: Complete user workflows

This comprehensive architecture provides a solid foundation for building a robust, scalable, and maintainable Flutter todo/reminder application with offline-first capabilities and Google Drive synchronization.
