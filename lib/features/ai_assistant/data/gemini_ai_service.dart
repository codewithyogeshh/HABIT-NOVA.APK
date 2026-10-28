import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synvero/features/ai_assistant/domain/ai_response_engine.dart';

/// Service connecting Synvero to live Google Gemini Generative AI.
///
/// Features:
/// - Real-time conversational AI answers for ANY question across any topic
/// - Pre-configured working Gemini API key with custom override support
/// - Automatic fallback to built-in [AIResponseEngine] if network is offline
class GeminiAIService {
  static const String _prefApiKey = 'synvero_gemini_api_key';

  /// Pre-configured active Gemini API key
  static const String _defaultApiKey =
      'AQ.Ab8RN6LkdS-RAacHXONo6_G1rlvwh4rJh8VfCU6UhTMHOWxQRQ';

  /// High-performance Gemini models verified with Google Generative Language API
  static const List<String> _models = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
  ];

  /// Active cached API key
  static String? _cachedApiKey;

  /// Retrieves the active Gemini API key (custom saved key or default key).
  static Future<String> getApiKey() async {
    if (_cachedApiKey != null && _cachedApiKey!.isNotEmpty) {
      return _cachedApiKey!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefApiKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _cachedApiKey = saved.trim();
        return _cachedApiKey!;
      }
    } catch (_) {}
    _cachedApiKey = _defaultApiKey;
    return _defaultApiKey;
  }

  /// Sets and persists a new custom Gemini API key.
  static Future<void> setApiKey(String key) async {
    _cachedApiKey = key.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefApiKey, key.trim());
    } catch (_) {}
  }

  /// Removes the custom saved Gemini API key, resetting to the default.
  static Future<void> removeApiKey() async {
    _cachedApiKey = _defaultApiKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefApiKey);
    } catch (_) {}
  }

  /// Checks if a valid Gemini API key is configured.
  static Future<bool> hasValidApiKey() async {
    final key = await getApiKey();
    return key.trim().length >= 15;
  }

  /// Queries Google Gemini API for an intelligent, contextual response.
  ///
  /// Seamlessly falls back to [AIResponseEngine] if offline or call fails.
  static Future<String> generateResponse({
    required String prompt,
    required String category,
    String? userName,
  }) async {
    final cleanPrompt = prompt.trim();
    final name = userName ?? 'Friend';
    final apiKey = await getApiKey();

    if (apiKey.trim().length >= 15) {
      final systemInstruction =
          'You are Synvero AI, a friendly, encouraging personal assistant and habit companion for $name. '
          'Your app focuses on habit building, focus study, task management, fitness, and nutrition. '
          'You can understand and answer in English, Marathi, Hindi, or any language the user speaks. '
          'Always provide clear, accurate, well-formatted markdown answers with emojis where appropriate. '
          'Current category mode: $category.';

      for (final model in _models) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
          );

          final body = jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemInstruction}
              ]
            },
            'contents': [
              {
                'parts': [
                  {'text': cleanPrompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            }
          });

          final response = await http
              .post(
                url,
                headers: {'Content-Type': 'application/json'},
                body: body,
              )
              .timeout(const Duration(seconds: 12));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final content = candidates[0]['content'] as Map<String, dynamic>?;
              final parts = content?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null && text.trim().isNotEmpty) {
                  return text.trim();
                }
              }
            }
          } else {
            debugPrint('Gemini API Error ($model): ${response.statusCode} - ${response.body}');
          }
        } catch (e) {
          debugPrint('Gemini API request error ($model): $e');
        }
      }
    }

    // Fallback: Comprehensive Multi-lingual Smart Knowledge Engine
    return AIResponseEngine.getResponse(
      prompt: cleanPrompt,
      category: category,
      userName: name,
    );
  }
}
