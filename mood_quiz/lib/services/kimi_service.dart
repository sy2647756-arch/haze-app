import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class ChatMessage {
  ChatMessage({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;

  Map<String, String> toApi() => {
    'role': fromUser ? 'user' : 'assistant',
    'content': text,
  };

  Map<String, dynamic> toJson() => {'u': fromUser, 't': text};

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      ChatMessage(fromUser: json['u'] as bool, text: json['t'] as String);
}

class KimiException implements Exception {
  KimiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Calls the server-side Kimi function. Transient failures are retried here so
/// both chat experiences share the same recovery behavior.
class KimiService {
  const KimiService();

  Future<String> reply(List<ChatMessage> history) {
    return _invoke(history, mode: 'tree_hole');
  }

  Future<String> replyAsCounselor(
    List<ChatMessage> history, {
    required String therapistName,
  }) {
    return _invoke(history, mode: 'counseling', therapistName: therapistName);
  }

  Future<String> _invoke(
    List<ChatMessage> history, {
    required String mode,
    String? therapistName,
  }) async {
    final messages = history.map((message) => message.toApi()).toList();
    Object? lastError;

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await Supabase.instance.client.functions
            .invoke(
              'kimi-chat',
              body: {
                'mode': mode,
                'therapistName': therapistName,
                'messages': messages,
              },
            )
            .timeout(const Duration(seconds: 45));

        if (response.status == 200) {
          final data = response.data;
          final content = data is Map && data['content'] is String
              ? data['content'] as String
              : '';
          if (content.trim().isNotEmpty) return content.trim();
          lastError = const FormatException('Empty AI response');
        } else {
          lastError = StateError('AI response status ${response.status}');
          if (response.status < 500 && response.status != 429) break;
        }
      } on TimeoutException catch (error) {
        lastError = error;
      } catch (error) {
        lastError = error;
      }

      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 650 * (attempt + 1)));
      }
    }

    // Keep the underlying error out of the UI and logs: it can contain
    // provider details that do not help the user recover.
    assert(lastError != null);
    throw KimiException(
      mode == 'counseling'
          ? 'The counseling connection paused. Your message is still here — tap Retry to continue.'
          : 'The Tree Hole connection paused. Your message is still here — tap Retry to continue.',
    );
  }
}
