import 'dart:math';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class IdGenerator {
  static const Uuid _uuid = Uuid();

  /// Generate a unique UUID v4
  static String generateId() {
    return _uuid.v4();
  }

  /// Generate a short ID (8 characters)
  static String generateShortId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

class HashUtils {
  /// Generate simple hash of a string (for basic sync comparison)
  static String generateSimpleHash(String input) {
    var hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0x7fffffff;
    }
    return hash.toString();
  }

  /// Generate hash for note content for sync comparison
  static String generateNoteHash(
    String title,
    String content,
    String updatedAt,
  ) {
    final combined = '$title|$content|$updatedAt';
    return generateSimpleHash(combined);
  }
}
