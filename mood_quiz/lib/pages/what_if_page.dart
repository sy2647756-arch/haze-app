import 'dart:convert';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/shared_session_repository.dart';
import '../widgets/share_sheet.dart';

class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

/// What-If 场景（Co-op）。suggestions 为可点选的快捷回答气泡。
class WhatIfScenario {
  const WhatIfScenario(this.id, this.prompt, this.suggestions);
  final String id;
  final String prompt;
  final List<String> suggestions;

  /// 场景 1 的两个选项来自 Figma；场景 2 Figma 未给选项，为自拟占位。
  static const all = <WhatIfScenario>[
    WhatIfScenario(
      'late_night',
      'Your partner goes out with friends and posts a photo on social media '
          'late at night. You notice an unfamiliar opposite-sex friend '
          'sitting right next to them. What do you do?',
      [
        'Feel a bit insecure, over-analyze their page, but pretend to be okay.',
        'Just drop a like and go to sleep. I trust your boundaries completely.',
      ],
    ),
    WhatIfScenario(
      'plan_change',
      'You both planned an exciting weekend date weeks in advance. Just two '
          'hours before meeting, they cancel because of an urgent, '
          'unavoidable work task. How do you react?',
      [
        "Feel let down and a little resentful, even if I say it's fine.",
        "Understand completely — work happens, we'll reschedule soon.",
      ],
    ),
  ];

  static WhatIfScenario? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// 一条留言。fromInitiator=true 为发起者（右·星星），false 为对方（左·蓝）。
class WhatIfMsg {
  const WhatIfMsg({required this.fromInitiator, required this.text});
  final bool fromInitiator;
  final String text;
  Map<String, dynamic> toJson() => {'i': fromInitiator, 't': text};
  factory WhatIfMsg.fromJson(Map<String, dynamic> j) =>
      WhatIfMsg(fromInitiator: j['i'] as bool, text: j['t'] as String);
}

/// 编码进 What-If 分享链接：场景 id + 到目前为止的留言。
class WhatIfPayload {
  const WhatIfPayload({
    required this.scenario,
    required this.messages,
    this.sessionToken,
  });
  final String scenario;
  final List<WhatIfMsg> messages;
  final String? sessionToken;

  String encode() {
    final json = jsonEncode({
      's': scenario,
      'm': messages.map((m) => m.toJson()).toList(),
      if (sessionToken != null) 'x': sessionToken,
    });
    return base64Url.encode(utf8.encode(json));
  }

  static WhatIfPayload? decode(String data) {
    try {
      final j =
          jsonDecode(utf8.decode(base64Url.decode(data)))
              as Map<String, dynamic>;
      return WhatIfPayload(
        scenario: j['s'] as String,
        messages: (j['m'] as List)
            .map((e) => WhatIfMsg.fromJson(e as Map<String, dynamic>))
            .toList(),
        sessionToken: j['x'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// 本地保存每个场景的留言串（发起者重进还能看到）。
class WhatIfStore {
  static Future<List<WhatIfMsg>> load(String scenario) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList('whatif_$scenario') ?? [];
    return raw
        .map((s) => WhatIfMsg.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(String scenario, List<WhatIfMsg> msgs) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      'whatif_$scenario',
      msgs.map((m) => jsonEncode(m.toJson())).toList(),
    );
  }
}

/// What-If 板块入口：两个场景的选择列表（Figma 无此列表，按 Co-op 视觉自设计）。
class WhatIfListPage extends StatelessWidget {
  const WhatIfListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAFEFD),
      body: Stack(
        children: [
          Positioned(
            left: 18,
            top: 62,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.black.withValues(alpha: 0.75),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 64,
            width: 393,
            child: Center(
              child: Text(
                'What-If Scenarios',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xCC000000),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            top: 120,
            right: 24,
            bottom: 0,
            child: ListView(
              children: [
                for (var i = 0; i < WhatIfScenario.all.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              WhatIfPage(scenario: WhatIfScenario.all[i]),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xFFD2F0EF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE229),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Scenario ${i + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFC640A3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              WhatIfScenario.all[i].prompt,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.4,
                                color: Color(0xCC000000),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What-If 聊天页（Figma 8:1447）。场景以卡片抛出，双方以留言接力作答。
/// 发起者留言在右（星星），对方在左（蓝）。分享链接把留言串带给对方。
class WhatIfPage extends StatefulWidget {
  const WhatIfPage({
    super.key,
    required this.scenario,
    this.invited = false,
    this.initialMessages,
    this.sessionToken,
  });

  final WhatIfScenario scenario;

  /// true = 从分享链接进入（对方视角，留言在左）。
  final bool invited;
  final List<WhatIfMsg>? initialMessages;
  final String? sessionToken;

  @override
  State<WhatIfPage> createState() => _WhatIfPageState();
}

class _WhatIfPageState extends State<WhatIfPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <WhatIfMsg>[];
  final _sessions = SharedSessionRepository();
  Timer? _pollTimer;
  String? _sessionToken;
  bool _completionAnnounced = false;

  /// 我是发起者？（决定我的留言落在左还是右）
  bool get _amInitiator => !widget.invited;

  /// 我是否已经回答过（回答后隐藏推荐气泡）。
  bool get _iHaveAnswered =>
      _messages.any((m) => m.fromInitiator == _amInitiator);

  @override
  void initState() {
    super.initState();
    _sessionToken = widget.sessionToken;
    if (widget.invited) {
      _messages.addAll(widget.initialMessages ?? const []);
    } else {
      WhatIfStore.load(widget.scenario.id).then((m) {
        if (mounted) {
          setState(
            () => _messages
              ..clear()
              ..addAll(m),
          );
        }
      });
    }
    if (!widget.invited && _sessionToken != null) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _post(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add(WhatIfMsg(fromInitiator: _amInitiator, text: t));
      _input.clear();
    });
    WhatIfStore.save(widget.scenario.id, _messages);
    if (widget.invited && _sessionToken != null) {
      _sessions
          .complete(
            token: _sessionToken!,
            guestPayload: {
              'messages': _messages.map((m) => m.toJson()).toList(),
            },
          )
          .catchError((Object error) {
            if (mounted) _showCloudError();
          });
    }
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

  Future<void> _share() async {
    try {
      _sessionToken ??= await _sessions.create(
        kind: 'what_if',
        contextId: widget.scenario.id,
        initiatorPayload: {
          'messages': _messages.map((m) => m.toJson()).toList(),
        },
      );
      _startPolling();
    } catch (_) {
      if (mounted) _showCloudError();
      return;
    }
    if (!mounted) return;
    final payload = WhatIfPayload(
      scenario: widget.scenario.id,
      messages: _messages,
      sessionToken: _sessionToken,
    ).encode();
    showShareSheet(context, link: '${_stripFragment()}#/whatif?d=$payload');
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollForPartner(),
    );
    _pollForPartner();
  }

  Future<void> _pollForPartner() async {
    final token = _sessionToken;
    if (token == null || widget.invited) return;
    try {
      final session = await _sessions.get(token);
      if (!mounted || session == null || !session.isCompleted) return;
      final raw = session.guestPayload?['messages'];
      if (raw is! List) return;
      final incoming = raw
          .map((e) => WhatIfMsg.fromJson(Map<String, dynamic>.from(e as Map)))
          .where((m) => !m.fromInitiator)
          .toList();
      final existing = _messages.where((m) => !m.fromInitiator).length;
      if (incoming.length > existing) {
        setState(() {
          _messages.removeWhere((m) => !m.fromInitiator);
          _messages.addAll(incoming);
        });
        await WhatIfStore.save(widget.scenario.id, _messages);
        if (!mounted) return;
      }
      if (!_completionAnnounced) {
        _completionAnnounced = true;
        _pollTimer?.cancel();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Your partner has completed the scenario - take a look!',
              ),
              duration: Duration(seconds: 5),
            ),
          );
      }
    } catch (_) {
      // Keep polling: a brief connection interruption should self-heal.
    }
  }

  void _showCloudError() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Could not sync this invite. Please try again.'),
        ),
      );
  }

  String _stripFragment() {
    final b = Uri.base;
    return '${b.origin}${b.path}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAFEFD), Color(0xFFFFF7BE)],
          ),
        ),
        child: Stack(
          children: [
            // 返回
            Positioned(
              left: 18,
              top: 68,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(
                  Icons.chevron_left,
                  size: 28,
                  color: Colors.black.withValues(alpha: 0.75),
                ),
              ),
            ),
            // 分享
            Positioned(
              left: 276,
              top: 63,
              child: _circle(Icons.ios_share, _share),
            ),
            // 关闭
            Positioned(
              left: 326,
              top: 63,
              child: _circle(
                Icons.close,
                () => Navigator.of(context).maybePop(),
              ),
            ),
            // 场景卡（含 Quiz 药丸）
            Positioned(left: 25, top: 118, width: 343, child: _scenarioCard()),
            // 留言区
            Positioned(
              left: 0,
              top: 400,
              right: 0,
              bottom: 90,
              child: ScrollConfiguration(
                behavior: _MouseDragScrollBehavior(),
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
                  children: [
                    for (final m in _messages) _bubble(m),
                    if (!_iHaveAnswered) _suggestions(),
                  ],
                ),
              ),
            ),
            // 输入栏
            Positioned(left: 25, top: 750, child: _inputBar()),
          ],
        ),
      ),
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: Colors.black87),
    ),
  );

  Widget _scenarioCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD2F0EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE229),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Quiz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFC640A3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 20, 22),
            child: Text(
              widget.scenario.prompt,
              style: const TextStyle(
                fontSize: 16,
                height: 1.55,
                fontWeight: FontWeight.w700,
                color: Color(0xCC000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(WhatIfMsg m) {
    final right = m.fromInitiator; // 发起者在右
    final avatar = Image.asset(
      right
          ? 'assets/treehole/avatar_user.png'
          : 'assets/treehole/avatar_ai.png',
      width: 47,
      height: 47,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const SizedBox(width: 47, height: 47),
    );
    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          m.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
            color: Color(0xCC000000),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: right
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: right ? [bubble, avatar] : [avatar, bubble],
      ),
    );
  }

  Widget _suggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in widget.scenario.suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _post(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD2F0EF)),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: Color(0x99000000),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      width: 343,
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            size: 18,
            color: Colors.black.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: _post,
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              cursorColor: const Color(0xFFC640A3),
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _post(_input.text),
            child: const Icon(
              Icons.send_rounded,
              size: 22,
              color: Color(0xFFC640A3),
            ),
          ),
        ],
      ),
    );
  }
}
