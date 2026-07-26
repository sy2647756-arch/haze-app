import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 账户：匿名登录 + 延迟绑定 Google。
///
/// 匿名用户 `linkIdentity(Google)` 会挂到**同一个 user_id**，历史日记无缝保留、
/// 无需数据迁移。Web 上会整页跳转到 Google，回来后 Supabase 自动完成绑定。
class AuthService {
  static SupabaseClient get _c => Supabase.instance.client;

  static bool get _hasSupabase {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } catch (_) {
      return false; // Supabase 未初始化（本地回退模式）
    }
  }

  static bool get isAnonymous =>
      _hasSupabase && (_c.auth.currentUser?.isAnonymous ?? false);
  static bool get isBound => _hasSupabase && !isAnonymous;
  static String? get email => _hasSupabase ? _c.auth.currentUser?.email : null;

  static String get _redirectTo {
    final b = Uri.base;
    return '${b.origin}${b.path}';
  }

  /// 绑定 / 登录 Google。
  static Future<void> linkGoogle() async {
    if (isAnonymous) {
      await _c.auth.linkIdentity(OAuthProvider.google, redirectTo: _redirectTo);
    } else {
      await _c.auth
          .signInWithOAuth(OAuthProvider.google, redirectTo: _redirectTo);
    }
  }

  // ---- 软提示（同一会话最多弹一次；「Maybe later」后本会话不再弹）----

  static bool _promptedThisSession = false;

  /// 在触发点调用：匿名且本会话没弹过 → 弹「绑定 Google」引导。
  static void maybePromptBinding(BuildContext context) {
    if (!isAnonymous || _promptedThisSession) return;
    _promptedThisSession = true;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BindSheet(),
    );
  }
}

class _BindSheet extends StatelessWidget {
  const _BindSheet();

  Future<void> _bind(BuildContext context) async {
    Navigator.of(context).pop();
    try {
      await AuthService.linkGoogle(); // Web 会整页跳转
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Couldn't start Google sign-in. Please try again."),
            duration: const Duration(seconds: 2)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Keep your progress safe',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xCC000000))),
          const SizedBox(height: 10),
          const Text(
              'Sign in with Google to back up your diary and see it on any '
              'device. Your history stays exactly as it is.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black54)),
          const SizedBox(height: 22),
          GestureDetector(
            onTap: () => _bind(context),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: const Color(0xFFC640A3),
                  borderRadius: BorderRadius.circular(25)),
              child: const Text('Continue with Google',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe later',
                style: TextStyle(fontSize: 14, color: Colors.black45)),
          ),
        ],
      ),
    );
  }
}
