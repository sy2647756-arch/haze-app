import 'package:flutter/material.dart';
import 'data/diary_repository.dart';
import 'pages/home_page.dart';
import 'pages/report_page.dart';
import 'widgets/app_bottom_nav.dart';

/// 全局手机画框尺寸（Figma 设计画布）。所有页面都渲染在这个尺寸内，
/// 由顶层 [_PhoneFrame] 统一等比缩放，保证每一页大小一致。
const double kFrameW = 393, kFrameH = 852;

void main() {
  runApp(const MoodQuizApp());
}

class MoodQuizApp extends StatelessWidget {
  const MoodQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC640A3)),
        useMaterial3: true,
      ),
      // 关键：把每一个路由（含 push 出来的写日记页）都包进统一画框。
      builder: (context, child) => _PhoneFrame(child: child ?? const SizedBox()),
      home: const RootShell(),
    );
  }
}

/// 统一手机画框：固定 393×852 逻辑尺寸，等比缩放居中，两侧留白。
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE9E0D2),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: kFrameW,
            height: kFrameH,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(kFrameW, kFrameH),
                devicePixelRatio: 1,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// 底部 4 Tab 骨架：Weather mood / Healing / Report / My。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final DiaryRepository _repo = LocalDiaryRepository();
  int _index = 0;

  final _homeKey = GlobalKey<HomePageState>();
  final _reportKey = GlobalKey<ReportPageState>();

  late final List<Widget> _pages = [
    HomePage(key: _homeKey, repo: _repo, onOpenReport: () => _select(2)),
    const _ComingSoonPage(title: 'Healing'),
    ReportPage(key: _reportKey, repo: _repo),
    const _ComingSoonPage(title: 'My'),
  ];

  void _select(int i) {
    setState(() => _index = i);
    if (i == 0) _homeKey.currentState?.reload();
    if (i == 2) _reportKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    // 填满画框：内容区在上，底部导航固定高度 82。
    // Scaffold 提供 Material / ScaffoldMessenger 祖先（导航 InkWell、SnackBar 需要）。
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: ClipRect(
              child: IndexedStack(index: _index, children: _pages),
            ),
          ),
          AppBottomNav(currentIndex: _index, onTap: _select),
        ],
      ),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3E9FB), Color(0xFFFFF5D3)],
        ),
      ),
      child: Center(
        child: Text('$title — coming soon',
            style: const TextStyle(fontSize: 18, color: Colors.black54)),
      ),
    );
  }
}
