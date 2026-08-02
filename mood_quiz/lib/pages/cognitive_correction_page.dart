import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一条已完成的认知矫正记录（本地存储；后续可迁 Supabase cognitive_records 表）。
class CcRecord {
  CcRecord({
    required this.thought,
    required this.distortions,
    required this.evidence,
    required this.newThought,
    required this.createdAt,
  });
  final String thought;
  final List<String> distortions;
  final String evidence;
  final String newThought;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'thought': thought,
    'distortions': distortions,
    'evidence': evidence,
    'newThought': newThought,
    'createdAt': createdAt.toIso8601String(),
  };
  factory CcRecord.fromJson(Map<String, dynamic> j) => CcRecord(
    thought: j['thought'] as String? ?? '',
    distortions:
        (j['distortions'] as List?)?.map((e) => e as String).toList() ?? [],
    evidence: j['evidence'] as String? ?? '',
    newThought: j['newThought'] as String? ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class CcRepo {
  static const _key = 'cc_records';

  static Future<List<CcRecord>> all() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? [];
    return raw
        .map((s) => CcRecord.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> add(CcRecord r) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_key) ?? [];
    raw.insert(0, jsonEncode(r.toJson()));
    await p.setStringList(_key, raw);
  }
}

/// Cognitive Correction 子功能（CBT 认知矫正，Figma APP_Haze CC 系列，18:1631/1648/1453/1436/1686）。
/// 5 步：写困扰 → 选认知偏差 → 现实检验 → 重构思维 → 完成。
class CognitiveCorrectionPage extends StatefulWidget {
  const CognitiveCorrectionPage({super.key});

  @override
  State<CognitiveCorrectionPage> createState() =>
      _CognitiveCorrectionPageState();
}

class _CognitiveCorrectionPageState extends State<CognitiveCorrectionPage> {
  static const _magenta = Color(0xFFC640A3);

  int _step = 0; // 0..4

  // 用户数据
  final _thought = TextEditingController();
  final Set<String> _distortions = {};
  final _evidence = TextEditingController();
  final _newThought = TextEditingController();

  // 5 个认知偏差（图标 + 名称 + 描述）
  static const _biases = <(String, String, String)>[
    (
      'assets/cc/mind_reading.png',
      'Mind Reading',
      'Assuming you know what others are thinking',
    ),
    (
      'assets/cc/catastrophizing.png',
      'Catastrophizing',
      'Blowing things out of proportion',
    ),
    (
      'assets/cc/all_or_nothing.png',
      'All-or-Nothing Thinking',
      'Seeing everything in extreme, binary terms',
    ),
    (
      'assets/cc/should.png',
      'Should Statements',
      'Holding rigid rules for yourself and others',
    ),
    ('assets/cc/other.png', 'Other', 'Uncertain or none of the above'),
  ];

  @override
  void dispose() {
    _thought.dispose();
    _evidence.dispose();
    _newThought.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _thought.text.trim().isEmpty) return;
    if (_step == 2 && _evidence.text.trim().isEmpty) return;
    if (_step == 3 && _newThought.text.trim().isEmpty) return;
    setState(() => _step++);
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  bool _saved = false;

  Future<void> _saveRecord() async {
    if (_saved) return; // 防重复保存
    await CcRepo.add(
      CcRecord(
        thought: _thought.text.trim(),
        distortions: _distortions.toList(),
        evidence: _evidence.text.trim(),
        newThought: _newThought.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _saved = true;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved — you can view it in Correction History.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 云朵渐变背景
          Positioned.fill(
            child: Image.asset(
              'assets/cc/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFEAF1FF)),
            ),
          ),
          // 返回
          Positioned(
            left: 18,
            top: 66,
            child: GestureDetector(
              onTap: _back,
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          // 顶部标题
          Positioned(
            left: 0,
            top: 69,
            width: 393,
            child: Center(
              child: Text(
                _titles[_step],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // 第一步右上角：历史记录入口
          if (_step == 0)
            Positioned(
              right: 18,
              top: 64,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CcHistoryPage()),
                ),
                child: Icon(
                  Icons.history,
                  size: 26,
                  color: _magenta.withValues(alpha: 0.85),
                ),
              ),
            ),
          // 完成屏不显示步骤条
          if (_step < 4) _stepIndicator(),
          // 当前步内容
          _content(),
        ],
      ),
    );
  }

  static const _titles = [
    'Cognitive Correction',
    'Select Cognitive Distortions',
    'Reality Testing',
    'Restructure Thinking',
    'Cognitive Correction',
  ];

  // 5 点步骤进度条
  Widget _stepIndicator() {
    return Positioned(
      left: 26,
      top: 120,
      width: 341,
      child: SizedBox(
        height: 31,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 连接线
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: 31,
                    height: 31,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _step ? _magenta : const Color(0xFFECECEC),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: i <= _step ? Colors.white : Colors.black38,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    switch (_step) {
      case 0:
        return _writeDoubts();
      case 1:
        return _selectBias();
      case 2:
        return _realityTesting();
      case 3:
        return _restructure();
      default:
        return _done();
    }
  }

  // 主 CTA 按钮（品红 pill）
  Widget _cta(
    String text,
    VoidCallback onTap, {
    Color textColor = const Color(0xFFFFE229),
  }) {
    return Positioned(
      left: 24,
      top: 751,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 344,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _magenta,
            borderRadius: BorderRadius.circular(23.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, {double top = 164}) => Positioned(
    left: 29,
    top: top,
    width: 306,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: _magenta,
      ),
    ),
  );

  // ---------- ① 写困扰 ----------
  Widget _writeDoubts() {
    return Stack(
      children: [
        _sectionTitle('Write your doubts,\nlet Star sort your thoughts'),
        Positioned(
          left: 24,
          top: 240,
          child: Container(
            width: 345,
            height: 300,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                TextField(
                  controller: _thought,
                  maxLines: null,
                  expands: true,
                  maxLength: 200,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                  ),
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        maxLength,
                        required isFocused,
                      }) => null,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: 'Sum up your troubles in one sentence',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text(
                    '${_thought.text.length} / 200',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _cta('Next', _next),
      ],
    );
  }

  // ---------- ② 选认知偏差 ----------
  Widget _selectBias() {
    return Stack(
      children: [
        _sectionTitle('You may be experiencing the following thinking biases'),
        Positioned(
          left: 24,
          top: 247,
          bottom: 120,
          width: 345,
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _biases.length,
            separatorBuilder: (_, _) => const SizedBox(height: 11),
            itemBuilder: (_, i) {
              final (icon, name, desc) = _biases[i];
              final sel = _distortions.contains(name);
              return GestureDetector(
                onTap: () => setState(
                  () =>
                      sel ? _distortions.remove(name) : _distortions.add(name),
                ),
                child: Container(
                  height: 89,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: sel ? _magenta : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        icon,
                        width: 56,
                        height: 56,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            const SizedBox(width: 56, height: 56),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sel ? _magenta : Colors.transparent,
                          border: Border.all(
                            color: sel
                                ? _magenta
                                : Colors.black.withValues(alpha: 0.25),
                            width: 2,
                          ),
                        ),
                        child: sel
                            ? const Icon(
                                Icons.check,
                                size: 15,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        _cta('Next', _next),
      ],
    );
  }

  // ---------- ③ 现实检验 ----------
  Widget _realityTesting() {
    return Stack(
      children: [
        _sectionTitle('Provide objective evidence for your thoughts'),
        // 星星吉祥物
        Positioned(
          left: 14,
          top: 236,
          child: Image.asset(
            'assets/mascots/sunny.png',
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Text('🌟', style: TextStyle(fontSize: 60)),
          ),
        ),
        // 气泡
        Positioned(
          left: 197,
          top: 275,
          child: Container(
            width: 171,
            height: 89,
            padding: const EdgeInsets.all(10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              "Let's take a look at the facts together~",
              style: TextStyle(fontSize: 13, height: 1.3, color: Colors.black),
            ),
          ),
        ),
        // Your thought
        const Positioned(
          left: 33,
          top: 409,
          child: Text(
            'Your thought:',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          left: 30,
          top: 446,
          child: Container(
            width: 335,
            constraints: const BoxConstraints(minHeight: 86),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7E5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _thought.text.trim(),
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        // Enter counter-evidence
        const Positioned(
          left: 33,
          top: 553,
          child: Text(
            'Enter counter-evidence',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Positioned(
          left: 30,
          top: 595,
          child: Container(
            width: 335,
            height: 144,
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FFD7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _evidence,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Color(0xB3000000),
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Enter facts that support another explanation...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
        _cta('Next', _next),
      ],
    );
  }

  // ---------- ④ 重构思维 ----------
  Widget _restructure() {
    return Stack(
      children: [
        _sectionTitle('Write a healthier interpretation of this thought'),
        Positioned(
          left: 24,
          top: 240,
          child: Container(
            width: 345,
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              controller: _newThought,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Write your healthier interpretation here...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
        _cta('Next', _next),
      ],
    );
  }

  // ---------- ⑤ 完成 ----------
  Widget _done() {
    return Stack(
      children: [
        // Awesome 标题
        const Positioned(
          left: 44,
          top: 93,
          width: 305,
          child: Text(
            'Awesome!\nYou’ve completed the cognitive restructuring exercise',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: _magenta,
            ),
          ),
        ),
        // Original / New Thought 双卡
        _thoughtCard(
          25,
          'Original Thought',
          _thought.text.trim().isEmpty ? '—' : _thought.text.trim(),
        ),
        _thoughtCard(
          201,
          'New Thought',
          _newThought.text.trim().isEmpty ? '—' : _newThought.text.trim(),
        ),
        // 完成插画
        Positioned(
          left: 41,
          top: 440,
          width: 320,
          child: Image.asset(
            'assets/cc/done.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
        // Save / Home
        Positioned(
          left: 24,
          top: 751,
          child: _doneBtn('Save', Colors.white, _saveRecord),
        ),
        Positioned(
          left: 201,
          top: 751,
          child: _doneBtn(
            'Home',
            const Color(0xFFFFE229),
            () => Navigator.of(context).maybePop(),
          ),
        ),
      ],
    );
  }

  Widget _thoughtCard(double left, String title, String body) {
    return Positioned(
      left: left,
      top: 227,
      child: Container(
        width: 167,
        height: 197,
        padding: const EdgeInsets.fromLTRB(16, 21, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  body,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doneBtn(String text, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 169,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _magenta,
          borderRadius: BorderRadius.circular(23.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ============ Cognitive Correction 历史记录 ============

class CcHistoryPage extends StatefulWidget {
  const CcHistoryPage({super.key});

  @override
  State<CcHistoryPage> createState() => _CcHistoryPageState();
}

class _CcHistoryPageState extends State<CcHistoryPage> {
  static const _magenta = Color(0xFFC640A3);
  List<CcRecord>? _records;

  @override
  void initState() {
    super.initState();
    CcRepo.all().then((r) {
      if (mounted) setState(() => _records = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/cc/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFEAF1FF)),
            ),
          ),
          Positioned(
            left: 18,
            top: 66,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(
                Icons.chevron_left,
                size: 28,
                color: Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 69,
            width: 393,
            child: Center(
              child: Text(
                'Correction History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 116,
            bottom: 0,
            child: records == null
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                ? const _EmptyHistory()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _record(records[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _record(CcRecord r) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期 + 偏差标签
          Row(
            children: [
              Text(
                DateFormat('MMM d, yyyy · HH:mm').format(r.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          if (r.distortions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in r.distortions)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _magenta.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      d,
                      style: const TextStyle(fontSize: 11, color: _magenta),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _labeled(
            'Original Thought',
            r.thought.isEmpty ? '—' : r.thought,
            const Color(0xFFFFE7E5),
          ),
          const SizedBox(height: 8),
          _labeled(
            'New Thought',
            r.newThought.isEmpty ? '—' : r.newThought,
            const Color(0xFFF0FFD7),
          ),
        ],
      ),
    );
  }

  Widget _labeled(String label, String body, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🌤️', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 14),
          Text(
            'No records yet',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Completed exercises will appear here.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
