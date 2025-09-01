import 'dart:math';

class IdGenerator {
  static const String _chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _random = Random();

  /// Generates a random ID with the specified length
  static String generateId([int length = 16]) {
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }

  /// Generates a UUID-like ID
  static String generateUuid() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomPart = generateId(8);
    return '$timestamp-$randomPart';
  }

  /// Generates a short ID (8 characters)
  static String generateShortId() {
    return generateId(8);
  }

  /// Generates a long ID (32 characters)
  static String generateLongId() {
    return generateId(32);
  }
}