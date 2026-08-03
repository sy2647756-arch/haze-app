import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CcRecord {
  CcRecord({
    String? situation,
    String? thought,
    required this.distortions,
    this.evidenceChoices = const [],
    String evidenceNotes = '',
    String? evidence,
    this.alternativeChoices = const [],
    this.alternativeNotes = '',
    this.emotionIntensity = 0,
    String? balancedThought,
    String? newThought,
    this.explanation = '',
    this.confidenceNote = '',
    this.nextAction = '',
    required this.createdAt,
  }) : situation = (situation ?? thought ?? '').trim(),
       evidenceNotes = evidenceNotes.isNotEmpty
           ? evidenceNotes.trim()
           : (evidence ?? '').trim(),
       balancedThought = (balancedThought ?? newThought ?? '').trim();

  final String situation;
  final List<String> distortions;
  final List<String> evidenceChoices;
  final String evidenceNotes;
  final List<String> alternativeChoices;
  final String alternativeNotes;
  final int emotionIntensity;
  final String balancedThought;
  final String explanation;
  final String confidenceNote;
  final String nextAction;
  final DateTime createdAt;

  // Backward-compatible names used by the original history UI and tests.
  String get thought => situation;
  String get evidence => evidenceNotes;
  String get newThought => balancedThought;

  Map<String, dynamic> toJson() => {
    'version': 2,
    'situation': situation,
    'thought': situation,
    'distortions': distortions,
    'evidenceChoices': evidenceChoices,
    'evidenceNotes': evidenceNotes,
    'evidence': evidenceNotes,
    'alternativeChoices': alternativeChoices,
    'alternativeNotes': alternativeNotes,
    'emotionIntensity': emotionIntensity,
    'balancedThought': balancedThought,
    'newThought': balancedThought,
    'explanation': explanation,
    'confidenceNote': confidenceNote,
    'nextAction': nextAction,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CcRecord.fromJson(Map<String, dynamic> json) => CcRecord(
    situation: json['situation'] as String? ?? json['thought'] as String? ?? '',
    distortions:
        (json['distortions'] as List?)?.map((value) => '$value').toList() ??
        const [],
    evidenceChoices:
        (json['evidenceChoices'] as List?)?.map((value) => '$value').toList() ??
        const [],
    evidenceNotes:
        json['evidenceNotes'] as String? ?? json['evidence'] as String? ?? '',
    alternativeChoices:
        (json['alternativeChoices'] as List?)
            ?.map((value) => '$value')
            .toList() ??
        const [],
    alternativeNotes: json['alternativeNotes'] as String? ?? '',
    emotionIntensity: (json['emotionIntensity'] as num?)?.round() ?? 0,
    balancedThought:
        json['balancedThought'] as String? ??
        json['newThought'] as String? ??
        '',
    explanation: json['explanation'] as String? ?? '',
    confidenceNote: json['confidenceNote'] as String? ?? '',
    nextAction: json['nextAction'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class CcRepo {
  static const _key = 'cc_records';

  /// Report pages listen to this so a completed correction appears instantly.
  static final changes = ValueNotifier<int>(0);

  static Future<List<CcRecord>> all() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key) ?? const [];
    final records = <CcRecord>[];
    for (final item in raw) {
      try {
        records.add(
          CcRecord.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } catch (_) {
        // Ignore a damaged legacy entry instead of breaking the whole report.
      }
    }
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  static Future<void> add(CcRecord record) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key) ?? <String>[];
    raw.insert(0, jsonEncode(record.toJson()));
    await preferences.setStringList(_key, raw);
    changes.value++;
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
    changes.value++;
  }
}
