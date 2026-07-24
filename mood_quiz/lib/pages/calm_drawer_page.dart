import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 让滚轮在 Web 上也能用鼠标拖动（Flutter 默认只认触摸）。
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

/// 12h Calm Drawer 子功能（Figma 119:2490 系列）。
/// 写下情绪 → 设定时长 → 上锁 → 冷却倒计时 → 到期后可查看 / 编辑 / 复制。

// ============ 数据模型 + 本地存储 ============

class CalmEntry {
  CalmEntry({required this.content, required this.lockedAt, required this.lockUntil});
  final String content;
  final DateTime lockedAt;
  final DateTime lockUntil;

  bool get isCooling => DateTime.now().isBefore(lockUntil);
  Duration get remaining {
    final d = lockUntil.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  Map<String, dynamic> toJson() => {
        'content': content,
        'lockedAt': lockedAt.toIso8601String(),
        'lockUntil': lockUntil.toIso8601String(),
      };
  factory CalmEntry.fromJson(Map<String, dynamic> j) => CalmEntry(
        content: j['content'] as String,
        lockedAt: DateTime.parse(j['lockedAt'] as String),
        lockUntil: DateTime.parse(j['lockUntil'] as String),
      );
}

class CalmRepo {
  static const _curKey = 'calm_current';
  static const _histKey = 'calm_history';

  static Future<CalmEntry?> current() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_curKey);
    if (s == null) return null;
    return CalmEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }

  static Future<void> setCurrent(CalmEntry? e) async {
    final p = await SharedPreferences.getInstance();
    if (e == null) {
      await p.remove(_curKey);
    } else {
      await p.setString(_curKey, jsonEncode(e.toJson()));
    }
  }

  static Future<List<CalmEntry>> history() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_histKey) ?? [];
    return raw
        .map((s) => CalmEntry.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  static Future<void> archive(CalmEntry e) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_histKey) ?? [];
    raw.insert(0, jsonEncode(e.toJson()));
    await p.setStringList(_histKey, raw);
  }
}

// 共享样式
const _accent = Color(0xFF8E95FD);
const _yellow = Color(0xFFFCF9A8);

Widget _starryBg() => Positioned.fill(
      child: Image.asset('assets/calm/bg.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF20223F))),
    );

Widget _pillButton(String text, VoidCallback onTap,
    {double width = 294, Color color = _accent}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: width,
      height: 52,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(23.5)),
      child: Text(text,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
}

String _hms(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

// ============ 入口：根据是否有活动抽屉分流 ============

class CalmDrawerPage extends StatefulWidget {
  const CalmDrawerPage({super.key});

  @override
  State<CalmDrawerPage> createState() => _CalmDrawerPageState();
}

class _CalmDrawerPageState extends State<CalmDrawerPage> {
  CalmEntry? _current;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await CalmRepo.current();
    if (mounted) {
      setState(() {
        _current = c;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ColoredBox(color: Color(0xFF20223F));
    }
    final cur = _current;
    if (cur == null) return _WriteScreen(onLocked: _load);
    // 冷却中 -> 倒计时入口；已解锁（到期或 Skip）-> 直接看内容
    return cur.isCooling
        ? _CoolingDownScreen(entry: cur, onChanged: _load)
        : _ThoughtsScreen(entry: cur, onChanged: _load, unlocked: true);
  }
}

// ============ ① 写内容 ============

class _WriteScreen extends StatefulWidget {
  const _WriteScreen({required this.onLocked});
  final VoidCallback onLocked;

  @override
  State<_WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<_WriteScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_ctrl.text.trim().isEmpty) return;
    final locked = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => _SetLockScreen(content: _ctrl.text.trim()),
    ));
    if (locked == true) widget.onLocked();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _starryBg(),
          Positioned(
            left: 18,
            top: 66,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close, size: 24, color: Colors.white),
            ),
          ),
          const Positioned(
            left: 0,
            top: 69,
            width: 393,
            child: Center(
              child: Text('12h Calm Drawer',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          // 锁图标（小）
          Positioned(
            left: 0,
            top: 120,
            width: 393,
            child: Center(
              child: Image.asset('assets/calm/lock.png',
                  height: 80,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.lock, size: 60, color: _yellow)),
            ),
          ),
          const Positioned(
            left: 40,
            top: 210,
            width: 313,
            child: Text('Let time hold your emotions\nfor the moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          // 输入框（磨砂卡）
          Positioned(
            left: 40,
            top: 300,
            child: Container(
              width: 313,
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 15, color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'What do you want to say, right now?',
                  hintStyle:
                      TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 60,
            width: 393,
            child: Center(child: _pillButton('Next', _next, width: 313)),
          ),
        ],
      ),
    );
  }
}

// ============ ② 设定锁定时长 ============

class _SetLockScreen extends StatefulWidget {
  const _SetLockScreen({required this.content});
  final String content;

  @override
  State<_SetLockScreen> createState() => _SetLockScreenState();
}

class _SetLockScreenState extends State<_SetLockScreen> {
  int _hours = 12;
  int _minutes = 0;
  static const _presets = [1, 6, 12, 24];

  Duration get _dur => Duration(hours: _hours, minutes: _minutes);

  Future<void> _startLock() async {
    if (_dur.inMinutes < 1) return; // 至少 1 分钟
    final now = DateTime.now();
    final entry = CalmEntry(
      content: widget.content,
      lockedAt: now,
      lockUntil: now.add(_dur),
    );
    await CalmRepo.setCurrent(entry);
    if (!mounted) return;
    // 进入 Start Lock 展示页；Home 返回后一路 pop 回入口
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _StartLockScreen(entry: entry),
    ));
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _wheel(int count, int value, ValueChanged<int> onChanged) {
    return SizedBox(
      width: 62,
      height: 140,
      child: ScrollConfiguration(
        behavior: _MouseDragScrollBehavior(),
        child: ListWheelScrollView.useDelegate(
          controller: FixedExtentScrollController(initialItem: value),
          itemExtent: 40,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: count,
            builder: (_, i) => Center(
              child: Text(i.toString().padLeft(2, '0'),
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9))),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _starryBg(),
          Positioned(
            left: 18,
            top: 70,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(Icons.chevron_left,
                  size: 28, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          Positioned(
            left: 335,
            top: 68,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close, size: 22, color: Colors.white),
            ),
          ),
          const Positioned(
            left: 0,
            top: 130,
            width: 393,
            child: Center(
              child: Text('Set Lock Duration',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            left: 0,
            top: 168,
            width: 393,
            child: Center(
              child: Text('When the timer expires, Star will alert you',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8))),
            ),
          ),
          // 预设快捷（点选整点小时）
          Positioned(
            left: 0,
            top: 250,
            width: 393,
            child: Center(
              child: Wrap(
                spacing: 12,
                children: [
                  for (final h in _presets)
                    GestureDetector(
                      onTap: () =>
                          setState(() { _hours = h; _minutes = 0; }),
                      child: Container(
                        width: 62,
                        height: 62,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_hours == h && _minutes == 0)
                              ? _accent
                              : Colors.white.withValues(alpha: 0.15),
                          border: Border.all(
                              color: (_hours == h && _minutes == 0)
                                  ? _yellow
                                  : Colors.white.withValues(alpha: 0.3),
                              width: 2),
                        ),
                        child: Text('${h}h',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 手动选择：HH : MM 滚轮
          Positioned(
            left: 0,
            top: 350,
            width: 393,
            child: Center(
              child: Text('Or set it manually',
                  style: TextStyle(
                      fontSize: 13, color: Colors.white.withValues(alpha: 0.6))),
            ),
          ),
          Positioned(
            left: 0,
            top: 390,
            width: 393,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _wheel(24, _hours, (v) => setState(() => _hours = v)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(':',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                  _wheel(60, _minutes, (v) => setState(() => _minutes = v)),
                ],
              ),
            ),
          ),
          // 当前选择（h m）
          Positioned(
            left: 0,
            top: 545,
            width: 393,
            child: Center(
              child: Text(
                  '${_hours}h ${_minutes.toString().padLeft(2, '0')}m',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _yellow)),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 60,
            width: 393,
            child: Center(
                child: _pillButton('Start Lock', _startLock, width: 348)),
          ),
        ],
      ),
    );
  }
}

// ============ ③ 开始锁定（大锁 + 倒计时） ============

class _StartLockScreen extends StatefulWidget {
  const _StartLockScreen({required this.entry});
  final CalmEntry entry;

  @override
  State<_StartLockScreen> createState() => _StartLockScreenState();
}

class _StartLockScreenState extends State<_StartLockScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _starryBg(),
          Positioned(
            left: 335,
            top: 68,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close, size: 22, color: Colors.white),
            ),
          ),
          const Positioned(
            left: 0,
            top: 138,
            width: 393,
            child: Center(
              child: Text('Start Lock',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            left: 0,
            top: 171,
            width: 393,
            child: Center(
              child: Text('Your content is safely stored.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9))),
            ),
          ),
          Positioned(
            left: 0,
            top: 230,
            width: 393,
            child: Center(
              child: Image.asset('assets/calm/lock.png',
                  height: 195,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.lock, size: 140, color: _yellow)),
            ),
          ),
          Positioned(
            left: 0,
            top: 455,
            width: 393,
            child: Center(
              child: Text('Time Remaining',
                  style: TextStyle(
                      fontSize: 15, color: Colors.white.withValues(alpha: 0.9))),
            ),
          ),
          Positioned(
            left: 0,
            top: 505,
            width: 393,
            child: Center(
              child: Text(_hms(widget.entry.remaining),
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: _yellow)),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 40,
            width: 393,
            child: Center(
              child: _pillButton(
                  'Home', () => Navigator.of(context).maybePop(),
                  width: 348),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ ④ 冷却态入口 ============

class _CoolingDownScreen extends StatefulWidget {
  const _CoolingDownScreen({required this.entry, required this.onChanged});
  final CalmEntry entry;
  final VoidCallback onChanged;

  @override
  State<_CoolingDownScreen> createState() => _CoolingDownScreenState();
}

class _CoolingDownScreenState extends State<_CoolingDownScreen> {
  late Timer _timer;
  List<CalmEntry> _history = [];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    CalmRepo.history().then((h) {
      if (mounted) setState(() => _history = h);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _openContent() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ThoughtsScreen(entry: widget.entry, onChanged: widget.onChanged),
    ));
    widget.onChanged();
  }

  Future<void> _skip() async {
    // 提前结束冷却：解锁但保留内容（返回后仍能看到原文）
    await CalmRepo.setCurrent(CalmEntry(
      content: widget.entry.content,
      lockedAt: widget.entry.lockedAt,
      lockUntil: DateTime.now(),
    ));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _starryBg(),
          Positioned(
            left: 29,
            top: 68,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.close, size: 24, color: Colors.white),
            ),
          ),
          const Positioned(
            left: 0,
            top: 69,
            width: 393,
            child: Center(
              child: Text('12h Calm Drawer',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const Positioned(
            left: 26,
            top: 118,
            width: 280,
            child: Text("I'll keep this between us",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
          // Cooling Down 卡
          Positioned(
            left: 25,
            top: 182,
            child: Container(
              width: 344,
              height: 363,
              padding: const EdgeInsets.symmetric(horizontal: 25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF4E7BF0).withValues(alpha: 0.6),
                    const Color(0xFFABA4F7).withValues(alpha: 0.6),
                    const Color(0xFF494FA3).withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text('Cooling Down',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 52),
                  Center(
                    child: Text(_hms(widget.entry.remaining),
                        style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w600,
                            color: _yellow)),
                  ),
                  const SizedBox(height: 32),
                  Center(child: _pillButton('My Content', _openContent)),
                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: _skip,
                      child: Text('Skip Cooldown',
                          style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.5))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // History 卡
          Positioned(
            left: 25,
            top: 573,
            child: Container(
              width: 343,
              height: 122,
              padding: const EdgeInsets.fromLTRB(30, 22, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('History',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('${_history.length} Records',
                      style: const TextStyle(fontSize: 15, color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============ ⑤ 查看想法（Cancel / Edit / Copy） ============

class _ThoughtsScreen extends StatefulWidget {
  const _ThoughtsScreen(
      {required this.entry, required this.onChanged, this.unlocked = false});
  final CalmEntry entry;
  final VoidCallback onChanged;

  /// true = 抽屉已解锁（到期或 Skip），作为入口主屏显示，可开新抽屉。
  final bool unlocked;

  @override
  State<_ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends State<_ThoughtsScreen> {
  late String _content = widget.entry.content;
  bool _editing = false;
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.entry.content);

  Future<void> _save() async {
    final updated = CalmEntry(
      content: _ctrl.text.trim(),
      lockedAt: widget.entry.lockedAt,
      lockUntil: widget.entry.lockUntil,
    );
    await CalmRepo.setCurrent(updated);
    if (mounted) {
      setState(() {
        _content = updated.content;
        _editing = false;
      });
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedStr =
        'Locked at ${DateFormat('HH:mm, dd/MM/yyyy').format(widget.entry.lockedAt)}';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _starryBg(),
          Positioned(
            left: 18,
            top: 70,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Icon(Icons.chevron_left,
                  size: 28, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
          const Positioned(
            left: 0,
            top: 69,
            width: 393,
            child: Center(
              child: Text('Your Thoughts',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          Positioned(
            left: 0,
            top: 104,
            width: 393,
            child: Center(
              child: Text(
                  widget.unlocked
                      ? 'Unlocked · this is what you set aside'
                      : 'Safely stored',
                  style: TextStyle(
                      fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
            ),
          ),
          // 内容卡
          Positioned(
            left: 40,
            top: 150,
            child: Container(
              width: 313,
              height: 300,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _editing
                        ? TextField(
                            controller: _ctrl,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(
                                fontSize: 15, color: Color(0xFF444444)),
                            decoration: const InputDecoration(
                                isCollapsed: true, border: InputBorder.none),
                          )
                        : SingleChildScrollView(
                            child: Text(_content,
                                style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Color(0xFF444444))),
                          ),
                  ),
                  Text(lockedStr,
                      style: TextStyle(
                          fontSize: 11,
                          color: const Color(0xFF444444).withValues(alpha: 0.5))),
                ],
              ),
            ),
          ),
          // Cancel / Edit / Copy
          Positioned(
            left: 0,
            bottom: 60,
            width: 393,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _smallPill('Cancel', () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 12),
                  _smallPill(_editing ? 'Save' : 'Edit', () {
                    if (_editing) {
                      _save();
                    } else {
                      setState(() => _editing = true);
                    }
                  }),
                  const SizedBox(width: 12),
                  _smallPill('Copy', () async {
                    await Clipboard.setData(ClipboardData(text: _content));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Copied'),
                          duration: Duration(seconds: 1)));
                    }
                  }),
                ],
              ),
            ),
          ),
          // 解锁态：开一个新抽屉（归档当前 -> 回到写内容）
          if (widget.unlocked)
            Positioned(
              left: 0,
              bottom: 22,
              width: 393,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    await CalmRepo.archive(widget.entry);
                    await CalmRepo.setCurrent(null);
                    if (context.mounted) Navigator.of(context).maybePop();
                    widget.onChanged();
                  },
                  child: Text('Start a new drawer',
                      style: TextStyle(
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          color: Colors.white.withValues(alpha: 0.7))),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _smallPill(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        height: 44,
        alignment: Alignment.center,
        decoration:
            BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(22)),
        child: Text(text,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
