import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 让内容区在 Web 上也能用鼠标拖动滚动。
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

/// 一个 Quiz 子测试的介绍页数据（Goal / Research / How it works）。
class QuizIntroData {
  const QuizIntroData({
    required this.title,
    required this.goal,
    required this.research,
    required this.steps,
  });

  final String title;
  final String goal;
  final String research;
  final List<String> steps;

  /// Objective Check 下的三个子测试（文案来自 Figma）。
  static const chatCheck = QuizIntroData(
    title: 'Chat Check',
    goal:
        'Objectively measure your digital communication dynamics to stop '
        'overthinking message lengths, reply times, and who texts first.',
    research:
        'Cognitive Behavioral Therapy (CBT) shows that anxiety in relationships '
        'often comes from subjective "mind-reading"—guessing their tone or '
        'intentions behind a screen. By evaluating observable data (like '
        'initiation ratios, reply stability, and spontaneous sharing), you shift '
        'your brain from anxious speculation to objective reality. Recognizing '
        'these concrete patterns interrupts the emotional haze and restores your '
        'peace of mind.',
    steps: [
      'Answer 6 concise questions about your recent texting habits and reply '
          'frequency.',
      'Get an objective reality check on your communication balance and effort '
          'ratio.',
      'Receive tailored CBT groundings to ease your "left-on-read" anxiety and '
          'navigate your next text without the burden.',
    ],
  );

  static const depthBoundaryRadar = QuizIntroData(
    title: 'Depth & Boundary Radar',
    goal:
        'Map the true depth of your emotional connection and evaluate if your '
        'personal boundaries are being respected or compromised.',
    research:
        'Healthy relationships rely on a balance between mutual vulnerability and '
        'clear emotional boundaries. When you constantly suppress your needs or '
        'carry the emotional labor alone, it breeds chronic anxiety and '
        'resentment. Objectively mapping these dynamics helps you recognize '
        'unequal effort, protect your energy, and establish safe boundaries '
        'without guilt.',
    steps: [
      'Answer 6 concise questions about topic depth, emotional support, and '
          'compromise ratios.',
      'Unlock your Radar chart to visualize the balance of effort and emotional '
          'distance between you two.',
      'Gain actionable boundary tips to communicate your bottom line gracefully '
          'and stop over-compromising.',
    ],
  );

  static const realWorldSignal = QuizIntroData(
    title: 'Real-World Signal Capture',
    goal:
        'Step away from screen filters to evaluate their real-world actions, '
        'effort, and consistency, reducing confusion from mixed signals.',
    research:
        'Relationship psychology indicates that over-analyzing text messages '
        'often blinds us to how someone actually behaves in real life. When '
        'sweet words online do not match offline actions, it creates cognitive '
        'dissonance and severe self-doubt. By tracking concrete real-world '
        'investments—like planning dates, dedicating quality time, and social '
        'integration—you ground yourself in facts and break free from the inner '
        'haze.',
    steps: [
      'Answer 6 concise questions about their real-life initiative, time '
          'investment, and action consistency.',
      'Capture objective signals to see if their offline effort truly matches '
          'their online words.',
      'Get practical insights to stop making excuses for them and make grounded '
          'decisions about your relationship.',
    ],
  );
}

/// Quiz 子测试介绍页（Figma 8:1013 chatcheck overall 等，三页共用模板）。
/// 固定头部（关闭/收藏/面包屑/标题/插画）+ 可滚动 Goal/Research/How it works
/// + 固定底部 Start quiz。
class QuizIntroPage extends StatefulWidget {
  const QuizIntroPage({super.key, required this.data});
  final QuizIntroData data;

  @override
  State<QuizIntroPage> createState() => _QuizIntroPageState();
}

class _QuizIntroPageState extends State<QuizIntroPage> {
  bool _bookmarked = false;

  static const _titleColor = Color(0xCC000000); // rgba(0,0,0,0.8)
  static const _body = Color(0xFF333333);
  static const _magenta = Color(0xFFC640A3);

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Scaffold(
      backgroundColor: const Color(0xFFEAFEFD),
      body: Stack(
        children: [
          // 插画（右上）
          Positioned(
            left: 220,
            top: 116,
            width: 158,
            height: 128,
            child: Image.asset('assets/quiz/intro_mascot.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
          // 关闭
          Positioned(
            left: 26,
            top: 59,
            child: _circleBtn(Icons.close, () => Navigator.of(context).maybePop()),
          ),
          // 收藏
          Positioned(
            left: 325,
            top: 59,
            child: _circleBtn(
                _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                () => setState(() => _bookmarked = !_bookmarked)),
          ),
          // 面包屑
          Positioned(
            left: 25,
            top: 150,
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('Objective Check',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _titleColor)),
            ),
          ),
          // 标题
          Positioned(
            left: 32,
            top: 185,
            width: 220,
            child: Text(d.title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _titleColor)),
          ),
          // 可滚动内容
          Positioned(
            left: 25,
            top: 258,
            right: 24,
            bottom: 90,
            child: ScrollConfiguration(
              behavior: _MouseDragScrollBehavior(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _sectionCard(
                    icon: 'assets/quiz/ic_goal.png',
                    title: 'Goal',
                    child: Text(d.goal,
                        style: const TextStyle(
                            fontSize: 14, height: 1.57, color: _body)),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    icon: 'assets/quiz/ic_research.png',
                    title: 'Research',
                    child: Text(d.research,
                        style: const TextStyle(
                            fontSize: 14, height: 1.57, color: _body)),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    iconWidget: const Icon(Icons.info_outline,
                        size: 20, color: Color(0xFF9385C4)),
                    title: 'How it works',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < d.steps.length; i++)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: i < d.steps.length - 1 ? 10 : 0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 20,
                                  child: Text('${i + 1}.',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.57,
                                          color: _body)),
                                ),
                                Expanded(
                                  child: Text(d.steps[i],
                                      style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.57,
                                          color: _body)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // Start quiz（固定底部）
          Positioned(
            left: 35,
            top: 772,
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Quiz questions — coming soon'),
                    duration: Duration(seconds: 1)),
              ),
              child: Container(
                width: 323,
                height: 49,
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
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: Colors.black87),
      ),
    );
  }

  Widget _sectionCard({
    String? icon,
    Widget? iconWidget,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: iconWidget ??
                    Image.asset(icon!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
              const SizedBox(width: 11),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _titleColor)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
