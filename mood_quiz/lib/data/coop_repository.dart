import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Co-op（双人）分享的数据层。
///
/// v1 无后端：发起者的答案**编码进链接**里传给被邀请者（[CoopPayload.encode]）。
/// 所有页面只依赖 [CoopRepository] 接口，以后接 Supabase 只需换一个实现，
/// 把「链接带答案」换成「链接带 id、答案存云端」，UI/算法都不用动。
abstract class CoopRepository {
  Future<String?> getName();
  Future<void> setName(String name);

  /// 被邀请者做完后，本地存一份结果，重进还能看到。
  Future<void> saveResult(CoopResult result);
  Future<CoopResult?> getResult();
}

/// 编码进分享链接的载荷：板块 + 发起者名字 + 发起者的答案下标。
class CoopPayload {
  const CoopPayload(
      {required this.section, required this.name, required this.answers});

  final String section; // 板块 id，如 'ph'
  final String name; // 发起者显示名
  final List<int> answers; // 每题所选选项下标

  String encode() {
    final json = jsonEncode({'s': section, 'n': name, 'a': answers});
    return base64Url.encode(utf8.encode(json));
  }

  static CoopPayload? decode(String data) {
    try {
      final json =
          jsonDecode(utf8.decode(base64Url.decode(data))) as Map<String, dynamic>;
      return CoopPayload(
        section: json['s'] as String,
        name: (json['n'] as String?) ?? '',
        answers: (json['a'] as List).map((e) => e as int).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// 被邀请者算完后的完整结果（本地保存 + 结果页用）。
class CoopResult {
  const CoopResult({
    required this.section,
    required this.myName,
    required this.myAnswers,
    required this.partnerName,
    required this.partnerAnswers,
  });

  final String section;
  final String myName;
  final List<int> myAnswers;
  final String partnerName;
  final List<int> partnerAnswers;

  /// 契合度：两人选了同一个选项的题数 ÷ 总题数。
  int get matchCount {
    var n = 0;
    for (var i = 0; i < myAnswers.length && i < partnerAnswers.length; i++) {
      if (myAnswers[i] == partnerAnswers[i]) n++;
    }
    return n;
  }

  int get total => myAnswers.length;
  int get percent => total == 0 ? 0 : (matchCount * 100 / total).round();

  Map<String, dynamic> toJson() => {
        's': section,
        'mn': myName,
        'ma': myAnswers,
        'pn': partnerName,
        'pa': partnerAnswers,
      };

  factory CoopResult.fromJson(Map<String, dynamic> j) => CoopResult(
        section: j['s'] as String,
        myName: j['mn'] as String,
        myAnswers: (j['ma'] as List).map((e) => e as int).toList(),
        partnerName: j['pn'] as String,
        partnerAnswers: (j['pa'] as List).map((e) => e as int).toList(),
      );
}

/// v1 实现：名字与结果存 shared_preferences；链接靠 [CoopPayload] 自带答案。
class LocalCoopRepository implements CoopRepository {
  static const _nameKey = 'coop_name';
  static const _resultKey = 'coop_result';

  @override
  Future<String?> getName() async {
    final p = await SharedPreferences.getInstance();
    final n = p.getString(_nameKey);
    return (n == null || n.isEmpty) ? null : n;
  }

  @override
  Future<void> setName(String name) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_nameKey, name.trim());
  }

  @override
  Future<void> saveResult(CoopResult result) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_resultKey, jsonEncode(result.toJson()));
  }

  @override
  Future<CoopResult?> getResult() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_resultKey);
    if (s == null) return null;
    return CoopResult.fromJson(jsonDecode(s) as Map<String, dynamic>);
  }
}

/// 把编码串拼成一条完整分享链接（保持当前 origin + 路径，换成哈希路由）。
String buildCoopLink(String encoded) {
  final base = Uri.base;
  final root = '${base.origin}${base.path}';
  return '$root#/coop?d=$encoded';
}
