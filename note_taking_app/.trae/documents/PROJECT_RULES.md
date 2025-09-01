# PROJECT RULES - Flutter Todo/Reminder Application

## 📱 What We're Building

We're creating a **smart todo and reminder application** that:
- Works completely on your phone (no internet required for basic features)
- Automatically syncs with Google Drive to keep your data safe
- Sends you notifications for important reminders
- Has a beautiful, easy-to-use interface

---

## 🏗️ Development Standards & Best Practices

### Flutter Development Rules

#### 1. **Code Organization (Clean Architecture)**
*Think of this like organizing your house - everything has its place*

```
lib/
├── core/           # Basic building blocks (like foundation of house)
├── data/           # Where we store and get information
├── domain/         # Business rules (what the app should do)
├── ui/             # What users see and interact with
└── services/       # Helper functions (like utilities)
```

**Why this matters:** Just like a well-organized house, organized code is easier to find things, fix problems, and add new features.

#### 2. **Naming Conventions**
- **Files:** `snake_case` (like `todo_item.dart`)
- **Classes:** `PascalCase` (like `TodoItem`)
- **Variables:** `camelCase` (like `todoTitle`)
- **Constants:** `UPPER_SNAKE_CASE` (like `MAX_TODO_LENGTH`)

**Example:**
```dart
// ✅ Good naming
class TodoItem {
  final String todoTitle;
  final DateTime dueDate;
  static const int MAX_TITLE_LENGTH = 100;
}

// ❌ Bad naming
class todoitem {
  final String Title;
  final DateTime date;
}
```

#### 3. **Code Quality Standards**

**Every piece of code must:**
- Have clear comments explaining what it does
- Handle errors gracefully (what happens when something goes wrong)
- Be tested to make sure it works
- Follow Dart/Flutter best practices

**Example of good code:**
```dart
/// Creates a new todo item with validation
/// Returns null if validation fails
TodoItem? createTodoItem(String title, DateTime dueDate) {
  try {
    // Validate input
    if (title.trim().isEmpty) {
      logger.warning('Todo title cannot be empty');
      return null;
    }
    
    if (dueDate.isBefore(DateTime.now())) {
      logger.warning('Due date cannot be in the past');
      return null;
    }
    
    // Create and return todo item
    return TodoItem(
      title: title.trim(),
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
  } catch (e) {
    logger.error('Failed to create todo item: $e');
    return null;
  }
}
```

---

## 🔒 Security Practices

### Local Storage Security
- **Encryption:** All sensitive data is encrypted before storing on device
- **Secure Storage:** Use Flutter Secure Storage for sensitive information
- **Data Validation:** Always check data before saving or displaying

### Google Drive Sync Security
- **OAuth 2.0:** Secure authentication (like a digital key)
- **Encrypted Uploads:** Data is encrypted before sending to Google Drive
- **Token Management:** Secure handling of access tokens
- **Privacy:** Only your app can access your app's data folder

**What this means for you:** Your personal information is protected like money in a bank vault.

---

## 🧪 Testing Strategy

### Types of Tests We Write

1. **Unit Tests** - Test individual pieces
   ```dart
   test('should create valid todo item', () {
     final todo = createTodoItem('Buy groceries', DateTime.now().add(Duration(days: 1)));
     expect(todo, isNotNull);
     expect(todo!.title, equals('Buy groceries'));
   });
   ```

2. **Widget Tests** - Test user interface components
3. **Integration Tests** - Test complete features working together

**Testing Rules:**
- Every new feature must have tests
- Tests must pass before code is accepted
- Aim for 80%+ code coverage

---

## ⚡ Performance Optimization Rules

### Memory Management
- **Dispose resources:** Always clean up when done
- **Lazy loading:** Only load data when needed
- **Image optimization:** Compress images for faster loading

### Database Performance
- **Indexing:** Make searches faster
- **Batch operations:** Group database changes together
- **Pagination:** Load data in chunks, not all at once

### UI Performance
- **Smooth animations:** 60 FPS target
- **Efficient rebuilds:** Only update what changed
- **Background processing:** Heavy work happens behind the scenes

---

## 📚 Documentation Requirements

### Code Documentation
Every function, class, and complex logic must have:
```dart
/// Brief description of what this does
/// 
/// [parameter1] - What this parameter is for
/// [parameter2] - What this parameter is for
/// 
/// Returns: What this function gives back
/// 
/// Example:
/// ```dart
/// final result = myFunction('example', 42);
/// ```
String myFunction(String parameter1, int parameter2) {
  // Implementation here
}
```

### Feature Documentation
- **User stories:** What the user wants to accomplish
- **Technical specs:** How we build it
- **API documentation:** How different parts communicate

---

## 🔄 Git Workflow & Version Control

### Branch Strategy
```
main           # Production-ready code
├── develop    # Integration branch
├── feature/   # New features
├── bugfix/    # Bug fixes
└── hotfix/    # Emergency fixes
```

### Commit Message Format
```
type(scope): brief description

Detailed explanation if needed

Closes #issue-number
```

**Examples:**
- `feat(todo): add due date reminder functionality`
- `fix(sync): resolve Google Drive authentication issue`
- `docs(readme): update installation instructions`

### Code Review Process
1. Create feature branch
2. Write code and tests
3. Submit pull request
4. Code review and feedback
5. Merge to develop
6. Deploy to main

---

## 📦 Dependency Management

### Package Selection Criteria
- **Actively maintained:** Regular updates
- **Good documentation:** Clear instructions
- **Community support:** Popular and trusted
- **Performance:** Doesn't slow down the app
- **Security:** No known vulnerabilities

### Key Dependencies
```yaml
dependencies:
  flutter_riverpod: ^2.5.1      # State management
  sqflite: ^2.3.3               # Local database
  google_sign_in: ^6.1.5        # Google authentication
  googleapis: ^11.4.0           # Google Drive API
  flutter_local_notifications: ^17.2.2  # Notifications
  encrypt: ^5.0.1               # Data encryption
```

### Update Strategy
- **Monthly dependency review**
- **Security updates immediately**
- **Major version updates with testing**
- **Document all changes**

---

## 🚨 Error Handling Patterns

### Error Categories
1. **User Errors:** Invalid input, missing data
2. **System Errors:** Network issues, storage problems
3. **Programming Errors:** Bugs in our code

### Error Handling Strategy
```dart
// Always use try-catch for operations that might fail
try {
  await saveToDatabase(todoItem);
  showSuccessMessage('Todo saved successfully!');
} on DatabaseException catch (e) {
  logger.error('Database error: $e');
  showErrorMessage('Failed to save todo. Please try again.');
} on NetworkException catch (e) {
  logger.error('Network error: $e');
  showErrorMessage('No internet connection. Todo saved locally.');
} catch (e) {
  logger.error('Unexpected error: $e');
  showErrorMessage('Something went wrong. Please contact support.');
}
```

### User-Friendly Error Messages
- **Clear and simple:** "Couldn't save your todo"
- **Actionable:** "Check your internet connection and try again"
- **Reassuring:** "Your data is safe, we'll try again automatically"

---

## 🎯 Quality Gates

### Before Any Code is Accepted
- [ ] All tests pass
- [ ] Code review approved
- [ ] Documentation updated
- [ ] Performance benchmarks met
- [ ] Security review passed
- [ ] User experience validated

### Definition of Done
A feature is complete when:
- [ ] Code is written and tested
- [ ] Documentation is updated
- [ ] User can successfully use the feature
- [ ] Performance meets requirements
- [ ] Security requirements are met
- [ ] Code is deployed and working

---

## 🔧 Development Environment Setup

### Required Tools
- **Flutter SDK:** Latest stable version
- **Android Studio/VS Code:** IDE with Flutter plugins
- **Git:** Version control
- **Firebase CLI:** For Google services setup

### Project Setup Commands
```bash
# Get dependencies
flutter pub get

# Run code generation
flutter packages pub run build_runner build

# Run tests
flutter test

# Run app
flutter run
```

---

## 📊 Monitoring & Analytics

### What We Track
- **App performance:** Loading times, crashes
- **User behavior:** Most used features
- **Sync success rates:** Google Drive integration health
- **Error rates:** What's breaking and how often

### Privacy First
- **No personal data collection**
- **Anonymous usage statistics only**
- **User consent required**
- **Data retention limits**

---

*Remember: These rules exist to help us build a reliable, secure, and user-friendly application. When in doubt, prioritize user experience and data security.*