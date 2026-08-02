import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppNavigationBus {
  static final requestedTab = ValueNotifier<int?>(null);

  static void openTab(int index) {
    requestedTab.value = index;
  }
}

class AppUsageStore {
  static const _firstUseKey = 'haze_first_use_date_v1';

  static Future<DateTime> firstUseDate({DateTime? fallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = DateTime.tryParse(prefs.getString(_firstUseKey) ?? '');
    if (saved != null) return DateTime(saved.year, saved.month, saved.day);
    final date = fallback ?? DateTime.now();
    final normalized = DateTime(date.year, date.month, date.day);
    await prefs.setString(_firstUseKey, normalized.toIso8601String());
    return normalized;
  }

  static Future<int> dayNumber(DateTime date, {DateTime? fallback}) async {
    final first = await firstUseDate(fallback: fallback);
    final selected = DateTime(date.year, date.month, date.day);
    final value = selected.difference(first).inDays + 1;
    return value < 1 ? 1 : value;
  }
}

class SubscriptionStore {
  static const _key = 'haze_vip_subscribed_v1';

  static Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> setSubscribed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class CognitiveBiasStore {
  static const _key = 'haze_cognitive_bias_scores_v1';

  static const leftOnRead = 'Left-on-Read';
  static const mindReading = 'Mind-Reading';
  static const selfWorth = 'Self-Worth';

  static String? categoryForTitle(String title) {
    if (title.contains('Left-on-Read')) return leftOnRead;
    if (title.contains('Mind-Reading')) return mindReading;
    if (title.contains('Self-Worth')) return selfWorth;
    return null;
  }

  static Future<Map<String, double>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  static Future<void> saveResult(String title, List<int> answers) async {
    final category = categoryForTitle(title);
    if (category == null || answers.isEmpty) return;
    // 中间选项通常是较客观、健康的判断；两侧选项代表更强的认知偏差。
    final risk = answers.fold<double>(
      0,
      (total, answer) => total + (answer == 1 ? 0.5 : 1.0),
    );
    final normalized = risk / answers.length;
    final scores = await load();
    scores[category] = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(scores));
  }
}
