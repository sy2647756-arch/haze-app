import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/coop_repository.dart';
import 'data/app_state_store.dart';
import 'data/diary_repository.dart';
import 'data/supabase_config.dart';
import 'data/supabase_diary_repository.dart';
import 'pages/coop_result_page.dart';
import 'pages/healing_page.dart';
import 'pages/what_if_page.dart';
import 'pages/home_page.dart';
import 'pages/my_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/report_page.dart';
import 'widgets/app_bottom_nav.dart';

/// 全局手机画框尺寸（Figma 设计画布）。所有页面都渲染在这个尺寸内，
/// 由顶层 [_PhoneFrame] 统一等比缩放，保证每一页大小一致。
const double kFrameW = 393, kFrameH = 852;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 默认本地存储；能连上 Supabase 就换成云端（并首次迁移本地日记）。
  DiaryRepository repo = LocalDiaryRepository();
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      await auth.signInAnonymously().timeout(const Duration(seconds: 12));
    }
    if (auth.currentSession != null) {
      final cloud = SupabaseDiaryRepository();
      await migrateLocalDiariesIfNeeded(cloud);
      repo = cloud;
    }
  } catch (e) {
    // 连不上 Supabase（网络/被墙/未配置）→ 回退本地，App 照常可用。
    debugPrint('Supabase unavailable, falling back to local storage: $e');
  }

  runApp(MoodQuizApp(repo: repo));
}

class MoodQuizApp extends StatelessWidget {
  const MoodQuizApp({super.key, required this.repo});

  final DiaryRepository repo;

  /// 从启动 URL 的哈希取出某个路由的 `d` 参数（形如 "/coop?d=xxxx"）。
  static String? _fragData(String route) {
    final frag = Uri.base.fragment;
    if (!frag.contains(route)) return null;
    final qi = frag.indexOf('?');
    if (qi < 0) return null;
    return Uri.splitQueryString(frag.substring(qi + 1))['d'];
  }

  /// 决定首屏：What-If 留言链接 / Co-op 邀请链接 / 正常首页。
  Widget _home() {
    final wif = _fragData('whatif');
    if (wif != null) {
      final p = WhatIfPayload.decode(wif);
      final s = p == null ? null : WhatIfScenario.byId(p.scenario);
      if (p != null && s != null) {
        return WhatIfPage(
          scenario: s,
          invited: true,
          initialMessages: p.messages,
          sessionToken: p.sessionToken,
        );
      }
    }
    final coop = _fragData('coop');
    if (coop != null) {
      final p = CoopPayload.decode(coop);
      if (p != null) return InvitedQuizFlow(payload: p);
    }
    return OnboardingGate(child: RootShell(repo: repo));
  }

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
      builder: (context, child) =>
          _PhoneFrame(child: child ?? const SizedBox()),
      home: _home(),
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
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: kIsWeb
              ? Container(
                  width: kFrameW + 22,
                  height: kFrameH + 22,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101114),
                    borderRadius: BorderRadius.circular(54),
                    border: Border.all(
                      color: const Color(0xFF686B70),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 22,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Stack(
                      children: [
                        _logicalScreen(child),
                        const Positioned(
                          top: 12,
                          left: 151,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),
                                ),
                              ),
                              child: SizedBox(width: 91, height: 29),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  width: kFrameW,
                  height: kFrameH,
                  child: _logicalScreen(child),
                ),
        ),
      ),
    );
  }

  Widget _logicalScreen(Widget child) {
    return SizedBox(
      width: kFrameW,
      height: kFrameH,
      child: MediaQuery(
        data: const MediaQueryData(
          size: Size(kFrameW, kFrameH),
          devicePixelRatio: 1,
        ),
        child: child,
      ),
    );
  }
}

/// 底部 4 Tab 骨架：Weather mood / Healing / Report / My。
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.repo});

  final DiaryRepository repo;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  DiaryRepository get _repo => widget.repo;
  int _index = 0;

  final _homeKey = GlobalKey<HomePageState>();
  final _reportKey = GlobalKey<ReportPageState>();

  late final List<Widget> _pages = [
    HomePage(key: _homeKey, repo: _repo, onOpenReport: () => _select(2)),
    HealingPage(onBack: _goHome),
    ReportPage(key: _reportKey, repo: _repo, onBack: _goHome),
    MyPage(onBack: _goHome),
  ];

  @override
  void initState() {
    super.initState();
    AppNavigationBus.requestedTab.addListener(_handleTabRequest);
  }

  @override
  void dispose() {
    AppNavigationBus.requestedTab.removeListener(_handleTabRequest);
    super.dispose();
  }

  void _handleTabRequest() {
    final requested = AppNavigationBus.requestedTab.value;
    if (requested == null) return;
    AppNavigationBus.requestedTab.value = null;
    _select(requested);
  }

  /// 各页左上角返回 -> 回到 Weather mood 首页。
  void _goHome() => _select(0);

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
