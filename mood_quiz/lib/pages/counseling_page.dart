import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

/// 咨询师。
class Therapist {
  const Therapist(this.name, this.avatar, this.reviews, this.consultations);
  final String name;
  final String avatar;
  final String reviews;
  final String consultations;

  static const all = <Therapist>[
    Therapist('Max', 'assets/counseling/max.png', '94% Positive Reviews',
        '5000+ Total Consultations'),
    Therapist('Grace', 'assets/counseling/grace.png', '92% Positive Reviews',
        '4000+ Total Consultations'),
    Therapist('Lei', 'assets/counseling/lei.png', '90% Positive Reviews',
        '4500+ Total Consultations'),
    Therapist('Melody', 'assets/counseling/melody.png', '85% Positive Reviews',
        '4000+ Total Consultations'),
    Therapist('Sarah', 'assets/counseling/sarah.png', '85% Positive Reviews',
        '4000+ Total Consultations'),
  ];
}

// 咨询模块统一的暖色渐变背景（Figma 24:1234）。
const _counselingGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFCEE8FF), Color(0xFFFFF8B6), Colors.white],
  stops: [0.0, 0.62, 0.99],
);

const _orange = Color(0xFFFF6F26);
const _magenta = Color(0xFFC640A3);

/// Counseling 咨询师列表页（Figma 24:1234）。UI-only（无支付/后端）。
class CounselingPage extends StatelessWidget {
  const CounselingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _counselingGradient),
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 68,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(Icons.chevron_left,
                    size: 28, color: Colors.black.withValues(alpha: 0.8)),
              ),
            ),
            const Positioned(
              left: 0,
              top: 70,
              width: 393,
              child: Center(
                child: Text('Counseling',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
              ),
            ),
            Positioned(
              left: 16,
              top: 118,
              right: 16,
              bottom: 0,
              child: ScrollConfiguration(
                behavior: _MouseDragScrollBehavior(),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 20),
                  children: [
                    for (final t in Therapist.all)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: _card(context, t),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Therapist t) {
    return Container(
      height: 123,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Row(
            children: [
              ClipOval(
                child: Image.asset(t.avatar,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFFEDEAF6))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    const SizedBox(height: 8),
                    Text(t.reviews,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _orange)),
                    const SizedBox(height: 4),
                    Text(t.consultations,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _orange)),
                  ],
                ),
              ),
              const SizedBox(width: 80), // 给右上 Choose 药丸留位
            ],
          ),
          Positioned(
            right: 0,
            top: 13,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CounselingChatPage(therapist: t))),
              child: Container(
                width: 73,
                height: 27,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFE229),
                    borderRadius: BorderRadius.circular(13)),
                child: const Text('Choose',
                    style: TextStyle(fontSize: 13, color: _magenta)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Counseling 对话页（Figma 27:1414）。UI-only：预置一段示例对话，
/// 输入框本地回显（不接大模型）。左侧头像为咨询师照片，右侧为星星。
class CounselingChatPage extends StatefulWidget {
  const CounselingChatPage({super.key, required this.therapist});
  final Therapist therapist;

  @override
  State<CounselingChatPage> createState() => _CounselingChatPageState();
}

class _CounselingChatPageState extends State<CounselingChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final List<(bool, String)> _messages = [
    (true,
        'They left me on read for over 4 hours. My mind is racing... Did I say something wrong?'),
    (false,
        "I hear your anxiety. Before we assume the worst, let's look at the facts. Has there been any solid evidence today showing they are angry with you, or is your mind filling in the blanks?"),
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    setState(() {
      _messages.add((true, t));
      _input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: _counselingGradient),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              top: 70,
              width: 393,
              child: Center(
                child: Text('Counseling',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
              ),
            ),
            Positioned(
              left: 326,
              top: 63,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 20, color: Colors.black87),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              top: 108,
              width: 393,
              child: Center(
                child: Text('Consultation for reference only; follow your inner guidance.',
                    style: TextStyle(fontSize: 11, color: _magenta)),
              ),
            ),
            Positioned(
              left: 0,
              top: 132,
              right: 0,
              bottom: 90,
              child: ScrollConfiguration(
                behavior: _MouseDragScrollBehavior(),
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  children: [for (final m in _messages) _bubble(m.$1, m.$2)],
                ),
              ),
            ),
            Positioned(left: 25, top: 750, child: _inputBar()),
          ],
        ),
      ),
    );
  }

  Widget _bubble(bool fromUser, String text) {
    final avatar = fromUser
        ? Image.asset('assets/treehole/avatar_user.png',
            width: 47,
            height: 47,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(width: 47, height: 47))
        : ClipOval(
            child: Image.asset(widget.therapist.avatar,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                    width: 44, height: 44, color: const Color(0xFFEDEAF6))));
    final bubble = Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(17)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, height: 1.4, color: Color(0xCC000000))),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            fromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: fromUser ? [bubble, avatar] : [avatar, bubble],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      width: 343,
      height: 49,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: [
          Icon(Icons.edit_outlined,
              size: 18, color: Colors.black.withValues(alpha: 0.55)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _input,
              onSubmitted: _send,
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              cursorColor: _magenta,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Type here',
                hintStyle: TextStyle(
                    fontSize: 14, color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_input.text),
            child: Icon(Icons.mic_none_rounded,
                size: 22, color: Colors.black.withValues(alpha: 0.55)),
          ),
        ],
      ),
    );
  }
}
