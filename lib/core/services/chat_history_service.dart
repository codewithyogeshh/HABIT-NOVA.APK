import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/core/services/supabase_service.dart';

/// Represents a persistent message in the AI Assistant chat history.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String time;
  final String? date;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    required this.time,
    this.date,
  }) : id = id ?? 'msg-${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isUser': isUser,
    'time': time,
    'date': date ?? DateTime.now().toIso8601String().split('T').first,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String?,
    text: json['text'] as String? ?? '',
    isUser: json['isUser'] as bool? ?? false,
    time: json['time'] as String? ?? '',
    date: json['date'] as String?,
  );
}

/// Service to persist, load, and manage AI Assistant conversation history
/// permanently per user account (ChatGPT-like persistence).
class ChatHistoryService {
  static String _historyKey(String userId) => 'user_${userId}_ai_chat_history_v2';

  static String get _currentUserId => SupabaseService.user?.id ?? 'guest';

  /// Loads saved chat history for the user. If empty, creates and returns the friendly greeting.
  static Future<List<ChatMessage>> loadHistory({String? userId}) async {
    final targetId = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_historyKey(targetId));
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
        final list = decoded
            .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('ChatHistoryService.loadHistory error: $e');
    }

    // Default welcome message if fresh conversation
    final user = SupabaseService.user;
    final name = (user?.userMetadata?['username'] as String?) ??
        (user?.email != null && user!.email!.isNotEmpty ? user.email!.split('@').first : 'Friend');

    final defaultGreeting = [
      ChatMessage(
        text: "Hi $name! 👋 I'm your personal AI Assistant. How can I help you achieve your goals today?",
        isUser: false,
        time: _currentTimeString(),
      ),
    ];
    await saveHistory(defaultGreeting, userId: targetId);
    return defaultGreeting;
  }

  /// Persists full list of chat messages for the target user
  static Future<void> saveHistory(List<ChatMessage> messages, {String? userId}) async {
    final targetId = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString(_historyKey(targetId), rawJson);
    } catch (e) {
      debugPrint('ChatHistoryService.saveHistory error: $e');
    }
  }

  /// Clears chat history for the user (when user explicitly taps "Clear Chat")
  static Future<void> clearHistory({String? userId}) async {
    final targetId = userId ?? _currentUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey(targetId));
    } catch (e) {
      debugPrint('ChatHistoryService.clearHistory error: $e');
    }
  }

  static String _currentTimeString() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

