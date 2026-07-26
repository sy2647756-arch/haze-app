import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import 'sub_page.dart';

/// My 页，像素还原 Figma 70:1234。
/// 头像 + VIP + 昵称 + 心情签名 + 徽章条 + Privacy/Notifications/Setting 菜单。
class MyPage extends StatelessWidget {
  const MyPage({super.key, this.onBack});

  /// 左上角返回：回到 Weather mood 首页。
  final VoidCallback? onBack;

  // 资料暂为设计稿占位，待账户模块接入后替换为真实 profile。
  static const _name = 'Maddy';
  static const _signature = 'happy &  Sunny';

  static const _menu = ['Privacy', 'Notifications', 'Setting'];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景插画
        Positioned.fill(
          child: Image.asset('assets/my/bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFFEAF1FF))),
        ),
        // 返回
        Positioned(
          left: 18,
          top: 60,
          child: GestureDetector(
            onTap: onBack,
            child: Icon(Icons.chevron_left,
                size: 28, color: Colors.black.withValues(alpha: 0.7)),
          ),
        ),
        // 头像卡
        Positioned(
          left: 153,
          top: 100,
          child: Container(
            width: 89,
            height: 89,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset('assets/my/avatar.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(Icons.person_outline,
                      size: 40, color: Colors.black26)),
            ),
          ),
        ),
        // VIP 徽标（点击进入订阅页）
        Positioned(
          left: 210,
          top: 173,
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubPage())),
            child: Container(
              width: 64,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFC640A3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('VIP',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFE229))),
            ),
          ),
        ),
        // 昵称
        const Positioned(
          left: 0,
          top: 205,
          width: 393,
          child: Center(
            child: Text(_name,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333))),
          ),
        ),
        // 心情签名
        Positioned(
          left: 0,
          top: 237,
          width: 393,
          child: Center(
            child: Text(_signature,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withValues(alpha: 0.5))),
          ),
        ),
        // 徽章条
        _badgeStrip(),
        // 菜单卡
        _menuCard(context),
      ],
    );
  }

  Widget _badgeStrip() {
    // 5 枚徽章的 x 坐标（对齐 Figma）
    const xs = [38.5, 105.0, 173.0, 238.0, 306.0];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 蓝色底条
        Positioned(
          left: 25,
          top: 289,
          child: Container(
            width: 343,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFB7D0FF),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 4,
                    offset: Offset(0, 4)),
              ],
            ),
          ),
        ),
        // 徽章图标
        for (var i = 0; i < xs.length; i++)
          Positioned(
            left: xs[i],
            top: 299,
            child: SizedBox(
              width: 46,
              height: 41,
              child: Image.asset('assets/my/badge${i + 1}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          ),
        // 黄色 Badge 标签（压在左上角）
        Positioned(
          left: 33.65,
          top: 262.45,
          child: Container(
            width: 67,
            height: 31.55,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE229),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Badge',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC640A3))),
          ),
        ),
      ],
    );
  }

  /// 账户行：显示登录状态，匿名时点了绑定 Google。
  Widget _accountRow(BuildContext context) {
    final bound = AuthService.isBound;
    final anon = AuthService.isAnonymous;
    final label = bound ? 'Account' : 'Sign in with Google';
    final trailing =
        bound ? (AuthService.email ?? 'Signed in') : (anon ? 'Connect' : 'Offline');
    return SizedBox(
      height: 46.74,
      child: InkWell(
        onTap: () async {
          if (bound) return;
          if (!anon) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Cloud not connected — working offline.'),
                duration: Duration(seconds: 2)));
            return;
          }
          try {
            await AuthService.linkGoogle(); // Web 会整页跳转到 Google
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Couldn't start Google sign-in. Try again."),
                  duration: Duration(seconds: 2)));
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black)),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 2,
                child: Text(trailing,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13,
                        color: bound
                            ? const Color(0xFFC640A3)
                            : Colors.black.withValues(alpha: 0.4))),
              ),
              if (!bound)
                Icon(Icons.chevron_right,
                    size: 19, color: Colors.black.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context) {
    return Positioned(
      left: 26,
      top: 362.84,
      child: Container(
        width: 342,
        height: 371.83,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _accountRow(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9.5),
              child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.black.withValues(alpha: 0.06)),
            ),
            for (var i = 0; i < _menu.length; i++) ...[
              SizedBox(
                height: 46.74,
                child: InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${_menu[i]} — coming soon'),
                        duration: const Duration(seconds: 1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 19),
                    child: Row(
                      children: [
                        Text(_menu[i],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black)),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            size: 19,
                            color: Colors.black.withValues(alpha: 0.35)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9.5),
                child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.black.withValues(alpha: 0.06)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
