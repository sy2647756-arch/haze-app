import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'coop_result_page.dart';
import 'quiz_questions_page.dart';

/// 一道题：英文题干 + 3 个英文选项（A/B/C）。
class QuizQuestion {
  const QuizQuestion(this.text, this.options);
  final String text;
  final List<String> options;
}

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
    required this.questions,
    this.breadcrumb = 'Objective Check',
    this.isCoop = false,
    this.sectionId = '',
  });

  final String title;
  final String goal;
  final String research;
  final List<String> steps;
  final List<QuizQuestion> questions;

  /// 顶部面包屑：Solo 为 'Objective Check'，Co-op 为 'Co-op Quiz'。
  final String breadcrumb;

  /// 是否 Co-op（双人分享匹配）板块。
  final bool isCoop;

  /// Co-op 板块 id（编码进分享链接），如 'ph'。
  final String sectionId;

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
    questions: [
      QuizQuestion('Who usually initiates the conversation?',
          ['Mostly me', 'Roughly equal', 'Mostly them']),
      QuizQuestion('How consistent is their reply frequency?', [
        'Consistent daily',
        'Random and unpredictable',
        'Only late at night',
      ]),
      QuizQuestion('How does the length of your messages compare?',
          ['I write much more', 'Balanced and matched', 'They write more']),
      QuizQuestion('How often do they spontaneously share their daily life?',
          ['Rarely or never', 'A few times a week', 'Daily sharing']),
      QuizQuestion(
          "How do you feel about sending a second text if they haven't replied?",
          [
            'Anxious, feeling like a bother',
            'Neutral, just adding info',
            'I never double-text',
          ]),
      QuizQuestion('How do you feel when a conversation ends?', [
        'Left hanging and anxious',
        'Peaceful and secure',
        'Neutral, just normal',
      ]),
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
    questions: [
      QuizQuestion('What is the deepest level of your usual conversations?', [
        'Surface level (hobbies, daily routine)',
        'Personal values and past experiences',
        'Deep fears and emotional vulnerabilities',
      ]),
      QuizQuestion('How do they react when you share negative emotions?', [
        'Changes the subject or acts cold',
        'Listens patiently and supports',
        'I hide my negative feelings',
      ]),
      QuizQuestion('How do they react when you say "no" to something?', [
        'Guilt-trips me or gets angry',
        'Respects it easily',
        "We haven't tested boundaries yet",
      ]),
      QuizQuestion('When there is a disagreement, who usually compromises?',
          ['Always me', 'We meet in the middle', 'Mostly them']),
      QuizQuestion('Do your conversations include planning for the future?',
          ['Actively avoided', 'Mentioned naturally', 'Only I bring it up']),
      QuizQuestion(
          'What is your general energy level after interacting with them?', [
        'Drained and exhausted',
        'Recharged and happy',
        'Confused and uncertain',
      ]),
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
    questions: [
      QuizQuestion(
          'How is their initiative in actually meeting up in real life?', [
        'All talk, no action',
        'Proactive and reliable',
        'I plan 100% of dates',
      ]),
      QuizQuestion('Are they willing to invest their "prime time" in you?', [
        'Only leftover time or late nights',
        'Dedicated weekend or holiday time',
        'Fits my schedule',
      ]),
      QuizQuestion('How balanced is the effort and spending in real life?',
          ['I invest way more', 'Balanced and mutual', 'They invest more']),
      QuizQuestion('Have they introduced you to their real-life social circle?',
          ['Complete secret', 'Introduced to friends', 'Too early to tell']),
      QuizQuestion('How focused are they on you when you meet in person?', [
        'Distracted, always on the phone',
        'Fully present and listening',
        'Only focused on physical intimacy',
      ]),
      QuizQuestion('How consistent are their words with their real-life actions?',
          ['Contradictory', 'Highly consistent', 'Mixed signals']),
    ],
  );

  // ===== Cognitive Bias Test（Solo 第二类）三个子测试 =====

  static const leftOnRead = QuizIntroData(
    breadcrumb: 'Cognitive Bias Test',
    title: 'The "Left-on-Read" Stress Test',
    goal:
        'Measure your emotional resilience and anxiety levels when facing '
        'delayed replies, helping you regain control over your attention.',
    research:
        'Cognitive Behavioral Therapy (CBT) reveals that being "left on read" '
        "triggers our brain's attachment panic and rejection sensitivity. When "
        'waiting for a text, our minds often invent worst-case scenarios, '
        'leading to hyper-vigilance and exhausting internal dialogue. By '
        'recognizing these automatic anxiety loops, you can stop taking delayed '
        'replies personally and self-soothe without compulsive checking.',
    steps: [
      'Answer 6 concise questions about your immediate reactions, thoughts, and '
          'sleep impacts when waiting for a reply.',
      'Evaluate your stress tolerance and uncover the hidden anxiety patterns '
          'behind your urge to double-text.',
      'Unlock CBT grounding tools like the 12h Calm Drawer to quiet your racing '
          'mind and protect your emotional peace.',
    ],
    questions: [
      QuizQuestion(
          'How do you react within the first hour of being left on read?', [
        'Panic and check phone constantly',
        'Notice it, but focus on my own tasks',
        "Don't really care or notice",
      ]),
      QuizQuestion('What is your biggest emotion when waiting for a reply?', [
        'Anxiety and fear of abandonment',
        'Calmness and patience',
        'Irritation and anger',
      ]),
      QuizQuestion(
          "What story do you tell yourself when they don't reply for hours?", [
        '"I must have said something wrong."',
        '"They must be busy with work or life."',
        '"They are playing mind games with me."',
      ]),
      QuizQuestion('What do you feel an urge to do after 4 hours of silence?', [
        'Send a follow-up text to check in',
        'Put phone away and wait naturally',
        'Delete the chat or unsend the message',
      ]),
      QuizQuestion('How does an unanswered text affect your sleep at night?', [
        'I stay up late overthinking',
        'I sleep normally',
        'I wake up early just to check phone',
      ]),
      QuizQuestion('How do you feel when they finally reply with a valid excuse?',
          [
            'Instant relief, but drained from anxiety',
            'Glad to hear from them, totally fine',
            'Still secretly resentful about the delay',
          ]),
    ],
  );

  static const mindReading = QuizIntroData(
    breadcrumb: 'Cognitive Bias Test',
    title: 'Mind-Reading Filter Analysis',
    goal:
        'Identify and clear the subjective filters that cause you to '
        'over-analyze tones, emojis, and hidden meanings in communication.',
    research:
        'In cognitive psychology, "mind-reading" is a distortion where we assume '
        "we know someone else's intentions without direct facts. When "
        'vulnerable, we project our internal insecurities onto their short '
        'replies or silence, often mistaking a neutral tone for coldness or '
        'rejection. Recognizing these cognitive filters allows you to separate '
        'subjective imagination from reality, instantly reducing emotional '
        'overthinking.',
    steps: [
      'Answer 6 concise questions about how you interpret punctuation, emojis, '
          'and social media activity.',
      'Detect cognitive distortions like catastrophic thinking or blaming '
          'yourself for their mood changes.',
      'Receive CBT reframing tips to replace anxious guesswork with clear, '
          'objective communication.',
    ],
    questions: [
      QuizQuestion(
          'How do you interpret a short text like "Okay." with a period?', [
        'They are cold and mad at me',
        'Just a normal, neutral confirmation',
        'They are being passive-aggressive',
      ]),
      QuizQuestion('What do you think when they stop using emojis in a chat?', [
        'They are losing interest in me',
        'They are probably just tired or in a hurry',
        'They are testing my reaction',
      ]),
      QuizQuestion(
          'Do you assume you know why they do or say certain things?', [
        'Yes, and I usually assume the worst',
        'No, I prefer to ask directly or look at facts',
        'Sometimes, depending on my mood',
      ]),
      QuizQuestion(
          "How do you react to their social media activity if they haven't "
          'texted you?',
          [
            'Feel hurt and over-analyze their motives',
            'Understand social media is just casual scrolling',
            'Immediately confront them or post something to retaliate',
          ]),
      QuizQuestion('When their mood seems down, what is your first thought?', [
        '"It\'s definitely my fault."',
        '"They might have had a stressful day."',
        '"They are being difficult on purpose."',
      ]),
      QuizQuestion(
          'How do you view a minor disagreement in the relationship?', [
        '"We are incompatible; it\'s doomed."',
        '"It\'s a normal hurdle we can solve together."',
        '"They must change, or I\'m leaving."',
      ]),
    ],
  );

  static const selfWorth = QuizIntroData(
    breadcrumb: 'Cognitive Bias Test',
    title: 'Self-Worth Detachment Profile',
    goal:
        'Evaluate how much your self-esteem relies on their approval, helping '
        'you detach your personal value from relationship ups and downs.',
    research:
        'Attachment theory shows that enmeshment occurs when our self-worth '
        "becomes entirely entangled with a partner's attention or validation. "
        'This leads to chronic people-pleasing, boundary surrender, and severe '
        'emotional swings based on their daily mood. Building emotional '
        'detachment does not mean loving less; it creates a secure internal '
        'foundation where you remain confident and whole, regardless of '
        'external dynamics.',
    steps: [
      'Answer 6 concise questions about your mood dependency, rejection '
          'sensitivity, and people-pleasing habits.',
      'Map your emotional independence to see if you are sacrificing your '
          'personal identity to keep them happy.',
      'Unlock empowerment strategies to reclaim your self-worth and anchor your '
          'happiness within yourself.',
    ],
    questions: [
      QuizQuestion('How much does their attention dictate your daily mood?', [
        '100%, my happiness depends on them',
        'Minimal, I generate my own happiness',
        'Roughly half, it affects me somewhat',
      ]),
      QuizQuestion(
          'How do you feel about yourself if they reject an invitation?', [
        'I feel worthless and unlovable',
        'I feel disappointed, but my self-worth is intact',
        'I feel embarrassed and swear never to ask again',
      ]),
      QuizQuestion(
          'How often do you suppress your true needs to keep them happy?', [
        'Constantly, I fear losing them',
        'Never, I express my needs assertively',
        'Occasionally, when I want to avoid conflict',
      ]),
      QuizQuestion(
          'How active is your personal life (hobbies, friends) outside this '
          'relationship?',
          [
            'Neglected, I revolve around them',
            'Thriving and independent',
            'Moderate, I balance both relatively well',
          ]),
      QuizQuestion('Where do you get your primary sense of validation?', [
        'From their compliments and approval',
        'From my own achievements and self-love',
        "From external status and others' envy",
      ]),
      QuizQuestion('Who is responsible for managing your emotional anxiety?', [
        'They are; they need to reassure me constantly',
        'I am; I use tools and grounding to self-soothe',
        'Fate; it depends on how the relationship goes',
      ]),
    ],
  );

  /// Co-op：Preferences & Habits（文案来自 Figma 8:1045；6 题来自需求）。
  static const preferencesHabits = QuizIntroData(
    breadcrumb: 'Co-op Quiz',
    isCoop: true,
    sectionId: 'ph',
    title: 'Preferences & Habits',
    goal:
        'Map out your dating communication styles, conflict triggers, and '
        'boundaries early on to prevent future misunderstandings and friction.',
    research:
        'Relationship psychology shows that early friction often comes from '
        'mismatched lifestyle habits and unexpressed needs, rather than a lack '
        'of affection. By openly comparing your communication frequency, social '
        'battery limits, and conflict resolution styles in a gamified setting, '
        'you eliminate guesswork. This transparent groundwork builds mutual '
        'understanding and a safer emotional connection.',
    steps: [
      'Answer 6 concise questions about your texting frequency, recharge habits, '
          'and boundaries.',
      'Compare your results in real-time to spot where your default relationship '
          'styles align or differ.',
      "Get tailored Co-op insights to understand each other's emotional bottom "
          'lines and navigate future disagreements smoothly.',
    ],
    questions: [
      QuizQuestion('What is your ideal texting frequency throughout the day?', [
        'Constant updates and all-day chatting',
        'Regular check-ins, but space for work/life',
        'Low frequency, prefer quality talks or in-person',
      ]),
      QuizQuestion('When an argument occurs, how do you prefer to handle it?', [
        "Resolve it immediately; I can't sleep angry",
        'Take a quiet break first, then talk calmly',
        'Let it slide naturally and forget about it',
      ]),
      QuizQuestion(
          'How do you usually recharge after a stressful, tiring week?', [
        'Solo cave time (gaming, reading, sleeping)',
        'Quality time or venting with my partner',
        'Going out and socializing with friends',
      ]),
      QuizQuestion('Which gesture makes you feel most loved and secure?', [
        'Words of affirmation and frequent praise',
        'Quality time and attentive listening',
        'Physical touch or thoughtful gifts',
      ]),
      QuizQuestion(
          'What is your boundary regarding staying in touch with exes or '
          'casual opposite-sex friends?',
          [
            'Strict distance; total transparency is needed',
            'Normal socializing is fine if boundaries are clear',
            "Very relaxed; I don't interfere with their circle",
          ]),
      QuizQuestion(
          'When you are feeling low or anxious, what do you need most from your '
          'partner?',
          [
            'Just listen and give me a hug; no logic needed',
            'Help me analyze the problem and find solutions',
            'Leave me alone to process it independently',
          ]),
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
            left: d.isCoop ? 283 : 325,
            top: 59,
            child: _circleBtn(
                _bookmarked ? Icons.bookmark : Icons.bookmark_border,
                () => setState(() => _bookmarked = !_bookmarked)),
          ),
          // Co-op：邀请图标
          if (d.isCoop)
            Positioned(
              left: 325,
              top: 59,
              child: _circleBtn(Icons.person_add_alt_1_outlined, () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Finish the quiz to invite your partner'),
                    duration: Duration(seconds: 1)));
              }),
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
              child: Text(d.breadcrumb,
                  style: const TextStyle(
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
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => d.isCoop
                      ? QuizQuestionsPage(
                          data: d,
                          onComplete: (answers) => Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (_) => CoopResultPage.initiator(
                                      data: d, myAnswers: answers))))
                      : QuizQuestionsPage(data: d))),
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
