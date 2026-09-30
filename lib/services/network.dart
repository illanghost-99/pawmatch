  static Future<List<Map<String, dynamic>>?> myMatches(String email) async {
    final c = _c;
    if (c == null || !email.contains('@')) return null;
    final me = email.toLowerCase();
    try {
      final a = await c.from('pm_matches').select().eq('user_a', me);
      final b = await c.from('pm_matches').select().eq('user_b', me);
      return [
        for (final r in [...a, ...b]) Map<String, dynamic>.from(r as Map),
      ];
    } catch (e) {
      debugPrint('myMatches $e');
      return null;
    }
  }

  static Future<String?> sendMessage(String matchId, String sender, String text) async {
    final c = _c;
    if (c == null || matchId.isEmpty) return null;
    try {
      final row = await c.from('pm_messages').insert({
        'match_id': matchId,
        'sender': sender.toLowerCase(),
        'text': text,
      }).select('id').single();
      return row['id'].toString();
    } catch (e) {
      debugPrint('sendMessage $e');
      return null;
    }
  }

  static Future<List<ChatLine>?> messages(String matchId, String me) async {
    final c = _c;
    if (c == null || matchId.isEmpty) return null;
    try {
      final rows = await c.from('pm_messages').select().eq('match_id', matchId).order('created_at');
      return [
        for (final r in rows)
          ChatLine(
            (r['sender'] as String? ?? '').toLowerCase() == me.toLowerCase(),
            r['text'] as String? ?? '',
            id: r['id'].toString(),
            recalled: r['recalled'] == true,
          ),
      ];
    } catch (e) {
      debugPrint('messages $e');
      return null;
    }
  }

  static Future<void> recallMessage(String id, String sender) async {
    final c = _c;
    if (c == null || id.isEmpty) return;
    try {
      await c.from('pm_messages').update({'recalled': true}).eq('id', id).eq('sender', sender.toLowerCase());
    } catch (e) {
      debugPrint('recallMessage $e');
    }
  }

  static Future<void> hideMatch(String matchId, String email) async {
    final c = _c;
    if (c == null || matchId.isEmpty) return;
    final me = email.toLowerCase();
    try {
      final row = await c.from('pm_matches').select('hidden_by').eq('id', matchId).single();
      final hidden = <String>[
        for (final h in List.from(row['hidden_by'] ?? const [])) h.toString().toLowerCase(),
      ];
      if (!hidden.contains(me)) hidden.add(me);
      await c.from('pm_matches').update({'hidden_by': hidden}).eq('id', matchId);
    } catch (e) {
      debugPrint('hideMatch $e');
    }
  }
}
