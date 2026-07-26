/// Supabase 连接配置。
///
/// URL 与 anon/publishable key 都是**公开安全**的（靠数据库 RLS 保护），
/// 可以直接提交进公开仓库。真正的机密（service_role key、Kimi key）永远只
/// 存服务端（Supabase secrets / Edge Function 环境变量），前端不接触。
class SupabaseConfig {
  static const String url = 'https://okppwnyithpwqckxdpzf.supabase.co';
  static const String anonKey = 'sb_publishable_lR83Yp7zvpxRiX-rQPAKqA_NPnycHSx';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
