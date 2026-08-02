import 'package:supabase_flutter/supabase_flutter.dart';

class SharedSession {
  const SharedSession({
    required this.token,
    required this.kind,
    required this.contextId,
    required this.initiatorPayload,
    this.initiatorName,
    this.guestName,
    this.guestPayload,
    this.completedAt,
  });

  final String token;
  final String kind;
  final String contextId;
  final String? initiatorName;
  final Map<String, dynamic> initiatorPayload;
  final String? guestName;
  final Map<String, dynamic>? guestPayload;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null && guestPayload != null;

  factory SharedSession.fromJson(Map<String, dynamic> json) => SharedSession(
    token: json['token'] as String,
    kind: json['kind'] as String,
    contextId: json['context_id'] as String,
    initiatorName: json['initiator_name'] as String?,
    initiatorPayload: Map<String, dynamic>.from(
      json['initiator_payload'] as Map,
    ),
    guestName: json['guest_name'] as String?,
    guestPayload: json['guest_payload'] == null
        ? null
        : Map<String, dynamic>.from(json['guest_payload'] as Map),
    completedAt: json['completed_at'] == null
        ? null
        : DateTime.parse(json['completed_at'] as String),
  );
}

/// Shared quiz/What-If sessions. The database functions keep the table private;
/// the unguessable token in the invite link is the only capability clients use.
class SharedSessionRepository {
  SupabaseClient get _client => Supabase.instance.client;

  Future<String> create({
    required String kind,
    required String contextId,
    String? initiatorName,
    required Map<String, dynamic> initiatorPayload,
  }) async {
    final value = await _client.rpc(
      'haze_create_shared_session',
      params: {
        'p_kind': kind,
        'p_context_id': contextId,
        'p_initiator_name': initiatorName,
        'p_initiator_payload': initiatorPayload,
      },
    );
    return value as String;
  }

  Future<SharedSession?> get(String token) async {
    final value = await _client.rpc(
      'haze_get_shared_session',
      params: {'p_token': token},
    );
    if (value is! List || value.isEmpty) return null;
    return SharedSession.fromJson(
      Map<String, dynamic>.from(value.first as Map),
    );
  }

  Future<void> complete({
    required String token,
    String? guestName,
    required Map<String, dynamic> guestPayload,
  }) async {
    await _client.rpc(
      'haze_complete_shared_session',
      params: {
        'p_token': token,
        'p_guest_name': guestName,
        'p_guest_payload': guestPayload,
      },
    );
  }
}
