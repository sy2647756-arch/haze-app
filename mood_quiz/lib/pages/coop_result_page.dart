import 'package:flutter/material.dart';
import '../data/coop_repository.dart';
import '../widgets/share_sheet.dart';
import 'quiz_intro_page.dart';
import 'quiz_questions_page.dart';

/// 按 id 取 Co-op 板块（分享链接里带 id）。
QuizIntroData? coopSectionById(String id) {
  switch (id) {
    case 'ph':
      return QuizIntroData.preferencesHabits;
  }
  return null;
}

const _magenta = Color(0xFFC640A3);
const _green = Color(0xFF90C86D);
const _titleColor = Color(0xCC000000);
const _youBox = Color(0xFFE5F0FF);
const _partnerBox = Color(0xFFFFF9D4);

/// 让被邀请者填名字（简易输入弹窗）；返回 null = 取消。
Future<String?> promptDisplayName(BuildContext context,
    {String title = 'Your name'}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(hintText: 'How should we call you?'),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('OK')),
      ],
    ),
  );
}

/// Relationship Checkup 结果页（Figma 8:1485）。
/// - 发起者答完：等待态（还没有对方数据），带分享按钮。
/// - 被邀请者答完：完整匹配（契合度 + 双方星星 + 逐题对比）。
class CoopResultPage extends StatefulWidget {
  const CoopResultPage._({
    required this.data,
    required this.myAnswers,
    this.myName,
    this.partnerName,
    this.partnerAnswers,
  });

  factory CoopResultPage.initiator(
          {required QuizIntroData data, required List<int> myAnswers}) =>
      CoopResultPage._(data: data, myAnswers: myAnswers);

  factory CoopResultPage.invited(
          {required QuizIntroData data, required CoopResult result}) =>
      CoopResultPage._(
        data: data,
        myAnswers: result.myAnswers,
        myName: result.myName,
        partnerName: result.partnerName,
        partnerAnswers: result.partnerAnswers,
      );

  final QuizIntroData data;
  final List<int> myAnswers;
  final String? myName;
  final String? partnerName;
  final List<int>? partnerAnswers;

  bool get waiting => partnerAnswers == null;

  @override
  State<CoopResultPage> createState() => _CoopResultPageState();
}

class _CoopResultPageState extends State<CoopResultPage> {
  final _repo = LocalCoopRepository();
  String? _myName;

  @override
  void initState() {
    super.initState();
    _myName = widget.myName;
    if (_myName == null) {
      _repo.getName().then((n) {
        if (mounted) setState(() => _myName = n);
      });
    }
  }

  int get _matchCount {
    final p = widget.partnerAnswers;
    if (p == null) return 0;
    var n = 0;
    for (var i = 0; i < widget.myAnswers.length && i < p.length; i++) {
      if (widget.myAnswers[i] == p[i]) n++;
    }
    return n;
  }

  Future<void> _share() async {
    var name = _myName ?? await _repo.getName();
    if (name == null || name.isEmpty) {
      if (!mounted) return;
      name = await promptDisplayName(context, title: 'Your name');
      if (name == null || name.isEmpty) return;
      await _repo.setName(name);
      if (mounted) setState(() => _myName = name);
    }
    final payload = CoopPayload(
      section: widget.data.sectionId,
      name: name,
      answers: widget.myAnswers,
    ).encode();
    if (!mounted) return;
    showShareSheet(context, link: buildCoopLink(payload));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 头部装饰（Figma 整帧上部烘焙图，含 Quiz/Relationship Checkup 标题+图标）
          Positioned(
            left: 0,
            top: 0,
            width: 393,
            height: 262,
            child: Image.asset('assets/quiz/rc_header.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Color(0xFFEDEAF6))),
          ),
          // 关闭热区（右上角 X）
          Positioned(
            left: 326,
            top: 64,
            width: 44,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          // 分享热区（上箭头图标）
          Positioned(
            left: 276,
            top: 64,
            width: 40,
            height: 44,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _share,
            ),
          ),
          // 正文
          Positioned(
            left: 0,
            top: 262,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Results',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _titleColor)),
                  const SizedBox(height: 14),
                  Text(_summary(),
                      style: const TextStyle(
                          fontSize: 15, height: 1.5, color: _titleColor)),
                  const SizedBox(height: 26),
                  _stars(),
                  const SizedBox(height: 26),
                  if (widget.waiting) ..._waitingBody() else ..._comparisonBody(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _summary() {
    if (widget.waiting) {
      return 'Waiting for your partner to take the quiz. Share the link below '
          'to invite them — you\'ll see how your answers compare once they finish.';
    }
    final pct = (_matchCount * 100 / widget.myAnswers.length).round();
    return 'You and ${widget.partnerName} matched on $_matchCount of '
        '${widget.myAnswers.length} ($pct%). This represents the objective '
        'balance of effort and emotional investment in your current connection.';
  }

  Widget _stars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _star('assets/quiz/star_you.png', 'assets/treehole/avatar_ai.png',
            _myName ?? 'You'),
        _star('assets/quiz/star_partner.png',
            'assets/treehole/avatar_user.png', widget.partnerName ?? 'Waiting…'),
      ],
    );
  }

  Widget _star(String starAsset, String iconAsset, String name) {
    return Column(
      children: [
        Image.asset(starAsset,
            width: 118,
            height: 118,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox(width: 118, height: 118)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconAsset,
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox(width: 20)),
            const SizedBox(width: 5),
            Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _titleColor)),
          ],
        ),
      ],
    );
  }

  List<Widget> _waitingBody() {
    return [
      GestureDetector(
        onTap: _share,
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: const Color(0xFFFFE229),
              borderRadius: BorderRadius.circular(24.5)),
          child: const Text('Invite your partner',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600, color: _magenta)),
        ),
      ),
      const SizedBox(height: 14),
      const Text(
          'View Comparison unlocks once your partner completes the quiz.',
          style: TextStyle(fontSize: 13, color: Colors.black45)),
    ];
  }

  List<Widget> _comparisonBody() {
    return [
      const Text('View Comparison',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: _titleColor)),
      const SizedBox(height: 16),
      for (var i = 0; i < widget.data.questions.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child: _comparisonCard(i),
        ),
    ];
  }

  Widget _comparisonCard(int i) {
    final q = widget.data.questions[i];
    final my = widget.myAnswers[i];
    final their = widget.partnerAnswers![i];
    final agree = my == their;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${i + 1}.',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _titleColor)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(q.text,
                    style: const TextStyle(fontSize: 15, color: _titleColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _answerBox(
                    _youBox,
                    'assets/treehole/avatar_ai.png',
                    'You answered:',
                    q.options[my],
                    agree),
              ),
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: agree ? _green : const Color(0xFFF26D6D)),
                child: Icon(agree ? Icons.check : Icons.close,
                    size: 18, color: Colors.white),
              ),
              Expanded(
                child: _answerBox(
                    _partnerBox,
                    'assets/treehole/avatar_user.png',
                    '${widget.partnerName} answered:',
                    q.options[their],
                    agree),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerBox(
      Color bg, String icon, String who, String option, bool agree) {
    return Container(
      height: 79,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(icon,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(width: 16)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _titleColor)),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: agree ? _green : _magenta),
            ),
            child: Text(option,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: _titleColor)),
          ),
        ],
      ),
    );
  }
}

/// 被邀请者从链接进入的整段流程：填名字 → 答同一套题 → 看匹配结果。
class InvitedQuizFlow extends StatefulWidget {
  const InvitedQuizFlow({super.key, required this.payload});
  final CoopPayload payload;

  @override
  State<InvitedQuizFlow> createState() => _InvitedQuizFlowState();
}

class _InvitedQuizFlowState extends State<InvitedQuizFlow> {
  final _repo = LocalCoopRepository();
  final _ctrl = TextEditingController();
  QuizIntroData? _section;
  bool _named = false;

  @override
  void initState() {
    super.initState();
    _section = coopSectionById(widget.payload.section);
    _repo.getName().then((n) {
      if (n != null && n.isNotEmpty && mounted) _ctrl.text = n;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    await _repo.setName(name);
    if (mounted) setState(() => _named = true);
  }

  Future<void> _onComplete(List<int> myAnswers) async {
    final name = _ctrl.text.trim();
    final result = CoopResult(
      section: widget.payload.section,
      myName: name,
      myAnswers: myAnswers,
      partnerName: widget.payload.name,
      partnerAnswers: widget.payload.answers,
    );
    await _repo.saveResult(result);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) =>
            CoopResultPage.invited(data: _section!, result: result)));
  }

  @override
  Widget build(BuildContext context) {
    final section = _section;
    if (section == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFEAFEFD),
        body: Center(child: Text('This invite link is invalid.')),
      );
    }
    if (_named) {
      return QuizQuestionsPage(data: section, onComplete: _onComplete);
    }
    // 填名字页
    return Scaffold(
      backgroundColor: const Color(0xFFEAFEFD),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${widget.payload.name} invited you',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54)),
            const SizedBox(height: 8),
            Text('to compare your ${section.title}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _titleColor)),
            const SizedBox(height: 40),
            TextField(
              controller: _ctrl,
              textAlign: TextAlign.center,
              maxLength: 20,
              onSubmitted: (_) => _start(),
              decoration: InputDecoration(
                hintText: 'Your name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _start,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFE229),
                    borderRadius: BorderRadius.circular(24.5)),
                child: const Text('Start quiz',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _magenta)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
