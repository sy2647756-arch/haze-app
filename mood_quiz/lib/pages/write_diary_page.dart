import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/diary_repository.dart';
import '../models/diary.dart';
import '../models/weather.dart';
import '../widgets/mood_mascot.dart';
import '../widgets/mood_ruler_slider.dart';

/// 写 / 编辑日记页。按 Figma 9:278（内容态）+ 9:222（面板态）像素还原。
/// 设计画布 393×852，整体等比缩放适配屏幕。
class WriteDiaryPage extends StatefulWidget {
  const WriteDiaryPage({
    super.key,
    required this.repo,
    required this.date,
    this.existing,
  });

  final DiaryRepository repo;
  final DateTime date;
  final Diary? existing;

  @override
  State<WriteDiaryPage> createState() => _WriteDiaryPageState();
}

class _WriteDiaryPageState extends State<WriteDiaryPage> {
  static const double dw = 393;

  Weather? _weather; // 已确认的天气
  Weather _panelWeather = Weather.hazy; // 面板内滑块当前值
  bool _touched = false; // 是否碰过滑块
  bool _panelOpen = false;
  int _dayNumber = 1;

  late final TextEditingController _content =
      TextEditingController(text: widget.existing?.content ?? '');

  bool get _isBackfill =>
      Diary.dayOf(widget.date) != Diary.dayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    _weather = widget.existing?.weather;
    _panelWeather = widget.existing?.weather ?? Weather.hazy;
    _touched = widget.existing != null;
    _loadDayNumber();
    // 进页自动弹出面板
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _panelOpen = true);
    });
  }

  Future<void> _loadDayNumber() async {
    final all = await widget.repo.getAll();
    if (all.isEmpty) return;
    final earliest = all.first.date; // getAll 已按日期升序
    final n = Diary.dayOf(widget.date).difference(Diary.dayOf(earliest)).inDays + 1;
    if (mounted) setState(() => _dayNumber = n < 1 ? 1 : n);
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  void _confirmMood() {
    if (!_touched) return;
    setState(() {
      _weather = _panelWeather;
      _panelOpen = false;
    });
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what — coming soon'), duration: const Duration(seconds: 1)),
    );
  }

  /// 点图片按钮弹出 Photo / Video / Cancel 选择框（还原 Figma Frame 9）。
  Future<void> _openMediaSheet() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MediaSheet(),
    );
    if (choice != null && choice != 'cancel') _comingSoon(choice);
  }

  Future<void> _post() async {
    final w = _weather;
    if (w == null) return;
    await widget.repo.upsert(Diary(
      date: widget.date,
      weather: w,
      content: _content.text.trim(),
      isBackfilled: _isBackfill || (widget.existing?.isBackfilled ?? false),
      createdAt: widget.existing?.createdAt,
    ));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    // 直接填满统一画框（393×852）；顶层 _PhoneFrame 负责整体缩放。
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5D3),
      body: Stack(children: [
        _base(),
        if (_panelOpen) _panel(),
      ]),
    );
  }

  // ---------- 基础内容态（9:278） ----------
  Widget _base() {
    return Stack(
      children: [
        // 背景渐变
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFBE4D4), Color(0xFFFFF5D3)],
              ),
            ),
          ),
        ),
        // 白卡
        Positioned(
          left: 25,
          top: 111,
          child: Container(
            width: 343,
            height: 591,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // 顶栏：返回 / 标题 / Post
        Positioned(
          left: 18,
          top: 55,
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left, size: 28, color: Color(0xFF333333)),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 64,
          child: Center(
            child: Text('Diary',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
          ),
        ),
        Positioned(
          left: 308,
          top: 59,
          child: GestureDetector(
            onTap: _weather == null ? null : _post,
            child: Container(
              width: 60,
              height: 33,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _weather == null
                    ? const Color(0xFFFFE229).withValues(alpha: 0.4)
                    : const Color(0xFFFFE229),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text('Post',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFC640A3))),
            ),
          ),
        ),
        // 日期
        Positioned(
          left: 43,
          top: 138,
          child: Text(DateFormat('yyyy.MM.dd').format(widget.date),
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333))),
        ),
        // 时间 + Day N
        Positioned(
          left: 46,
          top: 176,
          child: Text(
              '${DateFormat('HH:mm').format(widget.existing?.createdAt ?? DateTime.now())} Day $_dayNumber',
              style: TextStyle(
                  fontSize: 14, color: const Color(0xFF333333).withValues(alpha: 0.6))),
        ),
        // 右上角天气图标 + Switch mood
        Positioned(
          left: 259,
          top: 118,
          child: GestureDetector(
            onTap: () => setState(() => _panelOpen = true),
            child: Column(
              children: [
                SizedBox(
                  width: 84,
                  height: 60,
                  child: _weather != null
                      ? Image.asset(_weather!.iconAsset, fit: BoxFit.contain)
                      : const Icon(Icons.wb_cloudy_outlined,
                          size: 40, color: Color(0x66333333)),
                ),
                const SizedBox(height: 6),
                Text('Switch mood',
                    style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF333333).withValues(alpha: 0.6))),
              ],
            ),
          ),
        ),
        // 内容输入
        Positioned(
          left: 46,
          top: 220,
          width: 300,
          height: 260,
          child: TextField(
            controller: _content,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Write down all your thoughts here.',
              hintStyle: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF333333).withValues(alpha: 0.3)),
            ),
          ),
        ),
        // 图片占位
        Positioned(
          left: 46,
          top: 533,
          child: GestureDetector(
            onTap: _openMediaSheet,
            child: Container(
              width: 106,
              height: 106,
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.image_outlined,
                  size: 40, color: Colors.grey.shade400),
            ),
          ),
        ),
        // 地点占位
        Positioned(
          left: 46,
          top: 654,
          child: GestureDetector(
            onTap: () => _comingSoon('Location'),
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 12, color: Color(0xFFCFCFCF)),
                  SizedBox(width: 4),
                  Text('Your location',
                      style: TextStyle(fontSize: 10, color: Color(0xFFCFCFCF))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- 面板态（9:222） ----------
  Widget _panel() {
    return Stack(
      children: [
        // 遮罩
        Positioned.fill(
          child: GestureDetector(
            onTap: _touched ? _confirmMood : null,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        // 面板
        Positioned(
          left: 0,
          top: 257,
          child: SizedBox(
            width: dw,
            height: 595,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(37)),
              child: Stack(
                children: [
                  // 面板背景：随天气的柔和渐变（真实地景艺术由同事的场景组件替换）
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.lerp(_panelWeather.color, Colors.white, 0.35)!,
                            Color.lerp(_panelWeather.color, Colors.white, 0.85)!,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 标题
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 35,
                    child: Center(
                      child: Text('How do you feel overall?',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                  // 返回
                  Positioned(
                    left: 12,
                    top: 28,
                    child: IconButton(
                      onPressed: _touched ? _confirmMood : () => setState(() => _panelOpen = false),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                  ),
                  // 对勾确认（触碰后点亮）
                  Positioned(
                    right: 16,
                    top: 30,
                    child: GestureDetector(
                      onTap: _touched ? _confirmMood : null,
                      child: Container(
                        width: 40,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _touched
                              ? const Color(0xFFFFE229)
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(Icons.check, size: 18, color: Colors.black87),
                      ),
                    ),
                  ),
                  // 吉祥物（占位组件，随档位变化；动画由同事替换）
                  Positioned(
                    left: 110,
                    top: 142,
                    width: 171,
                    height: 311,
                    child: MoodMascotPlaceholder(weather: _panelWeather),
                  ),
                  // 当前心情天气文字（随滑块实时更新）
                  Positioned(
                    left: 0,
                    top: 458,
                    width: dw,
                    child: Center(
                      child: Text(
                        _panelWeather.label,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _panelWeather.color,
                        ),
                      ),
                    ),
                  ),
                  // 尺子滑块
                  Positioned(
                    left: 0,
                    top: 503,
                    child: MoodRulerSlider(
                      weather: _panelWeather,
                      onChanged: (w) => setState(() {
                        _panelWeather = w;
                        _touched = true;
                      }),
                    ),
                  ),
                  // Awful / Great
                  Positioned(
                    left: 25,
                    top: 533,
                    child: const Text('Awful',
                        style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  ),
                  Positioned(
                    right: 25,
                    top: 533,
                    child: const Text('Great',
                        style: TextStyle(fontSize: 14, color: Color(0xFF333333))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Photo / Video / Cancel 选择框（还原 Figma Frame 9，83:955）。
/// 注：Figma 原文案 "Vedio"/"Cancle" 为拼写错误，此处用正确拼写。
class _MediaSheet extends StatelessWidget {
  const _MediaSheet();

  static const _label = TextStyle(
      fontSize: 20, color: Color(0xB3000000), fontWeight: FontWeight.w400);

  Widget _row(BuildContext c, String text, String value) {
    return InkWell(
      onTap: () => Navigator.of(c).pop(value),
      child: SizedBox(
        height: 58,
        child: Center(child: Text(text, style: _label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo / Video 一组
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _row(context, 'Photo', 'Photo'),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFEAEAEA)),
                  _row(context, 'Video', 'Video'),
                ],
              ),
            ),
            const SizedBox(height: 5),
            // Cancel 一组
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SizedBox(
                height: 60,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop('cancel'),
                  child: const Center(child: Text('Cancel', style: _label)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
