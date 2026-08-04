import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../services/kimi_service.dart';

/// AI Tree Hole 的对话本地存储（一条连续会话；重进自动带出历史）。
class TreeHoleStore {
  static const _key = 'treehole_messages';

  static Future<List<ChatMessage>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? [];
    return raw
        .map((s) => ChatMessage.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(List<ChatMessage> msgs) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      _key,
      msgs.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}

/// 让列表在 Web 上也能用鼠标拖动滚动（Flutter Web 默认只认触摸）。
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

/// AI Tree Hole（Figma 18:1514）。
/// 星空背景的聊天页：用户吐露心事，Kimi 以 CBT 语气温柔回应。
/// 用户气泡靠右+黄色星星头像；AI 气泡靠左+蓝色头像。纯前端调用 Kimi。
class TreeHolePage extends StatefulWidget {
  const TreeHolePage({super.key, this.service, this.importedText});

  /// 可注入（测试用）；默认在 State 里 new 一个真实的。
  final KimiService? service;
  final String? importedText;

  @override
  State<TreeHolePage> createState() => _TreeHolePageState();
}

/// 开场白：无历史时用它起头。
const _greeting =
    "Hey, I'm here. Whatever's weighing on you, "
    "you can let it out. What happened?";

/// 每次调用 Kimi 时，最多回带多少条历史（控制 token / 上下文长度）。
const _kContextWindow = 20;

class _TreeHolePageState extends State<TreeHolePage> {
  late final KimiService _kimi = widget.service ?? KimiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  bool _waiting = false;
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final saved = await TreeHoleStore.load();
    if (!mounted) return;
    final imported = widget.importedText?.trim();
    setState(() {
      _messages
        ..clear()
        ..addAll(
          saved.isEmpty
              ? [ChatMessage(fromUser: false, text: _greeting)]
              : saved,
        );
      if (imported != null &&
          imported.isNotEmpty &&
          !_messages.any(
            (message) => message.fromUser && message.text == imported,
          )) {
        _messages.add(ChatMessage(fromUser: true, text: imported));
      }
    });
    if (saved.isEmpty || imported?.isNotEmpty == true) {
      TreeHoleStore.save(_messages);
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _waiting) return;
    setState(() {
      _messages.add(ChatMessage(fromUser: true, text: text));
      _waiting = true;
      _input.clear();
    });
    TreeHoleStore.save(_messages);
    _scrollToBottom();
    try {
      // 只回带最近若干条，避免上下文越滚越长。
      final context = _messages.length > _kContextWindow
          ? _messages.sublist(_messages.length - _kContextWindow)
          : _messages;
      final answer = await _kimi.reply(context);
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(fromUser: false, text: answer)));
    } on KimiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 7),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => unawaited(_retryLastMessage()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _waiting = false);
        TreeHoleStore.save(_messages);
        _scrollToBottom();
      }
    }
  }

  Future<void> _retryLastMessage() async {
    if (_waiting || _messages.isEmpty || !_messages.last.fromUser) return;
    setState(() => _waiting = true);
    _scrollToBottom();
    try {
      final history = _messages.length > _kContextWindow
          ? _messages.sublist(_messages.length - _kContextWindow)
          : _messages;
      final answer = await _kimi.reply(history);
      if (!mounted) return;
      setState(() => _messages.add(ChatMessage(fromUser: false, text: answer)));
    } on KimiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _waiting = false);
        TreeHoleStore.save(_messages);
        _scrollToBottom();
      }
    }
  }

  Future<void> _toggleListening() async {
    if (_waiting) return;
    if (_speech.isListening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _listening = status == 'listening');
      },
      onError: (_) {
        if (!mounted) return;
        setState(() => _listening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice input could not start. Please allow microphone access.',
            ),
          ),
        );
      },
    );
    if (!available || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is not available here.')),
        );
      }
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        _input.text = result.recognizedWords;
        _input.selection = TextSelection.collapsed(offset: _input.text.length);
      },
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> _clearConversation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear this conversation?'),
        content: const Text(
          'Your chat history in the Tree Hole will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await TreeHoleStore.clear();
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(ChatMessage(fromUser: false, text: _greeting));
    });
    TreeHoleStore.save(_messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 星空背景 + 边缘压暗
          Positioned.fill(
            child: Image.asset(
              'assets/treehole/bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF3B4A8C)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.05),
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF061022).withValues(alpha: 0.0),
                    const Color(0xFF0B1F44).withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
          // 标题
          const Positioned(
            left: 0,
            top: 69,
            width: 393,
            child: Center(
              child: Text(
                'AI Tree Hole & Templates',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // 清空会话（自设计：Figma 无此按钮，放在标题左侧）
          Positioned(
            left: 18,
            top: 66,
            child: GestureDetector(
              onTap: _clearConversation,
              child: Icon(
                Icons.delete_outline,
                size: 24,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          // 关闭按钮（白圆 + X）
          Positioned(
            left: 326,
            top: 61,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 22, color: Colors.black87),
              ),
            ),
          ),
          // 消息列表
          Positioned(
            left: 0,
            top: 110,
            right: 0,
            bottom: 90,
            child: ScrollConfiguration(
              behavior: _MouseDragScrollBehavior(),
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
                itemCount: _messages.length + (_waiting ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i >= _messages.length) return const _TypingBubble();
                  return _Bubble(message: _messages[i]);
                },
              ),
            ),
          ),
          // 输入栏
          Positioned(
            left: 25,
            top: 750,
            child: _InputBar(
              controller: _input,
              enabled: !_waiting,
              onSend: _send,
              listening: _listening,
              onMic: _toggleListening,
            ),
          ),
        ],
      ),
    );
  }
}

/// 一条消息气泡 + 外侧头像。
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final avatar = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Image.asset(
        message.fromUser
            ? 'assets/treehole/avatar_user.png'
            : 'assets/treehole/avatar_ai.png',
        width: 48,
        height: 48,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
      ),
    );

    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: message.fromUser ? const Color(0xFFFFF9C9) : Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          message.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.47,
            color: Color(0xCC000000),
          ), // rgba(0,0,0,0.8)
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.fromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: message.fromUser ? [bubble, avatar] : [avatar, bubble],
      ),
    );
  }
}

/// AI 正在输入的三点动画气泡。
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Image.asset(
              'assets/treehole/avatar_ai.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox(width: 48, height: 48),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_c.value - i * 0.2) % 1.0;
                    final o = 0.3 + 0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 5 : 0),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8E95FD).withValues(alpha: o),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部输入栏：铅笔图标 + 输入框 + 发送/麦克风。
class _InputBar extends StatefulWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.listening,
    required this.onMic,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final bool listening;
  final VoidCallback onMic;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    return Container(
      width: 343,
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 18,
            color: Colors.black.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: widget.enabled,
              onSubmitted: (_) => widget.onSend(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              cursorColor: const Color(0xFF8E95FD),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Type here',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: !widget.enabled
                ? null
                : hasText
                ? widget.onSend
                : widget.onMic,
            child: Icon(
              hasText ? Icons.send_rounded : Icons.mic_none_rounded,
              size: 22,
              color: widget.listening
                  ? const Color(0xFFC640A3)
                  : hasText
                  ? const Color(0xFF8E95FD)
                  : Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
