import 'dart:convert';
import 'package:http/http.dart' as http;

/// ============================================================
/// Kimi (Moonshot AI) 接入配置
/// ============================================================
/// AI Tree Hole 用的对话模型。Moonshot 的接口与 OpenAI 兼容。
///
/// ★★★★★  你要填的东西在这里（KimiConfig.apiKey）  ★★★★★
///
/// 填 API Key 有两种方式，二选一：
///
///  方式 A（推荐，不会把 key 写进代码/推到公开仓库）：
///     运行 / 构建时用 --dart-define 传进来，例如：
///       flutter run -d web-server --web-port 8977 --web-hostname 127.0.0.1 \
///         --no-web-resources-cdn --dart-define=KIMI_API_KEY=sk-你的key
///
///  方式 B（图省事，仅本地测试用）：
///     把下面 `_pastedApiKey` 的空字符串换成你的 key。
///     ⚠️ 本仓库是**公开**的且 push 会自动部署——用方式 B 时**千万别把带 key 的
///        改动 commit/push 上去**，否则 key 会公开泄露。
///
/// ⚠️ 安全提醒（很重要）：这是纯前端 Web App，任何写死/传进来的 key 最终都会
///    出现在浏览器能看到的 JS 里，用户可通过网络面板抓到。正式上线前应该把
///    调用放到后端代理（例如你们计划中的 Supabase Edge Function），前端只调
///    自己的后端。到时把 [KimiConfig.baseUrl] 指向你的代理即可，其余代码不用动。
class KimiConfig {
  /// 方式 B：把 key 粘到这对引号中间（仅本地测试，勿提交）。
  static const String _pastedApiKey = '';

  /// 方式 A：通过 --dart-define=KIMI_API_KEY=... 传入。
  /// 注意：括号里是环境变量的“名字”，不要把 key 填在这里。key 在启动命令里传。
  static const String _envApiKey =
      String.fromEnvironment('KIMI_API_KEY', defaultValue: '');

  /// 最终使用的 key：优先环境变量，其次粘贴的。
  static String get apiKey => _envApiKey.isNotEmpty ? _envApiKey : _pastedApiKey;

  static bool get isConfigured => apiKey.isNotEmpty;

  /// 接口地址。国内站用 api.moonshot.cn（key 来自 platform.moonshot.cn）；
  /// 海外站用 api.moonshot.ai（key 来自 platform.moonshot.ai）。两站 key 不通用！
  /// 将来接后端代理时，把这里换成你自己的代理地址即可。
  static const String baseUrl =
      'https://api.moonshot.cn/v1/chat/completions';

  /// 模型 id（国内站）。moonshot-v1-8k 每个账号都有；也可换 'kimi-latest'、
  /// 'moonshot-v1-32k'、'moonshot-v1-128k'（更长上下文）。
  static const String model = 'moonshot-v1-8k';

  /// AI Tree Hole 的人设/系统提示（英文，海外用户）。
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

/// 调用 Kimi 出错时抛出。
class KimiException implements Exception {
  KimiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 负责跟 Kimi 说话。无状态；把整段对话历史传进来，返回 AI 的回复文本。
class KimiService {
  KimiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// [history] 是到目前为止的全部消息（含用户刚发的最后一条）。
  Future<String> reply(List<ChatMessage> history) async {
    if (!KimiConfig.isConfigured) {
      throw KimiException(
          "The AI Tree Hole isn't connected yet. (Add your Kimi API key in "
          "lib/services/kimi_service.dart)");
    }

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': KimiConfig.systemPrompt},
      ...history.map((m) => m.toApi()),
    ];

    http.Response resp;
    try {
      resp = await _client
          .post(
            Uri.parse(KimiConfig.baseUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${KimiConfig.apiKey}',
            },
            body: jsonEncode({
              'model': KimiConfig.model,
              'messages': messages,
              'temperature': 0.6,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      // 网络失败 / 超时 / 浏览器 CORS 被拦，都会走到这里。
      throw KimiException(
          "Couldn't reach the Tree Hole right now. Check your connection and "
          "try again.");
    }

    if (resp.statusCode != 200) {
      throw KimiException('Kimi error ${resp.statusCode}: ${resp.body}');
    }

    try {
      final data = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final content = (data['choices'] as List).first['message']['content'];
      return (content as String).trim();
    } catch (e) {
      throw KimiException('Got an unexpected response from Kimi.');
    }
  }
}
