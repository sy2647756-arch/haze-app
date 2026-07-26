import 'package:supabase_flutter/supabase_flutter.dart';

/// AI Tree Hole 的对话服务。
///
/// 现在**不再在前端持有 Kimi key**：前端调 Supabase Edge Function `kimi-chat`，
/// 由它在服务端用 secret 里的 key 去请求 Kimi(Moonshot)。这样既藏住了 key，
/// 也绕开了浏览器直连 Kimi 的 CORS 问题。函数默认要求合法的 Supabase JWT，
/// 匿名登录用户即可调用。
class KimiConfig {
  /// AI Tree Hole 的人设/系统提示（非机密，放前端即可）。
  static const String systemPrompt =
      "You are the AI Tree Hole inside Haze, a gentle emotional-wellbeing app. "
      "People come here to vent about relationships and feelings and to feel heard. "
      "Reply with warmth and brevity (2-4 short sentences). First validate the "
      "emotion, then gently offer a small reframe or a CBT-informed observation "
      "when it fits — for example softly naming a cognitive distortion such as "
      "'catastrophizing' or 'mind-reading' — and optionally one tiny grounding "
      "suggestion. Never diagnose and never give medical advice. If someone hints "
      "at self-harm or crisis, gently encourage them to reach out to someone they "
      "trust or a local helpline. Write in warm, simple English.";
}

/// 一条对话消息。
class ChatMessage {
  ChatMessage({required this.fromUser, required this.text});

  /// true = 用户发的；false = AI（Kimi）回的。
  final bool fromUser;
  final String text;

  Map<String, String> toApi() =>
      {'role': fromUser ? 'user' : 'assistant', 'content': text};

  Map<String, dynamic> toJson() => {'u': fromUser, 't': text};
  factory ChatMessage.fromJson(Map<String, dynamic> j) =>
      ChatMessage(fromUser: j['u'] as bool, text: j['t'] as String);
}

/// 调用出错时抛出。
class KimiException implements Exception {
  KimiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 通过 Edge Function 跟 Kimi 说话。把整段对话历史传进来，返回 AI 的回复文本。
class KimiService {
  const KimiService();

  Future<String> reply(List<ChatMessage> history) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': KimiConfig.systemPrompt},
      ...history.map((m) => m.toApi()),
    ];

    FunctionResponse res;
    try {
      res = await Supabase.instance.client.functions
          .invoke('kimi-chat', body: {'messages': messages})
          .timeout(const Duration(seconds: 40));
    } catch (e) {
      // 未登录 / 网络失败 / 函数未部署，都走这里。
      throw KimiException(
          "Couldn't reach the Tree Hole right now. Check your connection and "
          "try again.");
    }

    if (res.status != 200) {
      throw KimiException('The Tree Hole is unavailable (error ${res.status}).');
    }

    final data = res.data;
    final content =
        (data is Map && data['content'] is String) ? data['content'] as String : '';
    if (content.trim().isEmpty) {
      throw KimiException('Got an unexpected response. Please try again.');
    }
    return content.trim();
  }
}
