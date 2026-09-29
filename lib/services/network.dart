import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'cloud.dart';

class Network {
  static SupabaseClient? get _c {
    if (!Cloud.ready) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> upsertDog({
    required String email,
    required String owner,
    required MyDog dog,
    required double lat,
    required double lng,
  }) async {
    final c = _c;
    if (c == null || !email.contains('@')) return;
    final id = '${email.toLowerCase()}-${dog.name.toLowerCase()}';
    try {
      await c.from('pm_dogs').upsert({
        'id': id,
        'owner_email': email.toLowerCase(),
        'owner_name': owner,
        'name': dog.name,
        'breed': dog.breed,
        'sex': dog.sex,
        'age': dog.age,
        'city': dog.city,
        'intent': dog.availableForBreeding ? 'puppies' : 'friends',
        'bio': dog.bio,
        'photos': dog.photos,
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('upsertDog $e');
    }
  }

  static Future<List<DogProfile>> liveDogs(String myEmail) async {
    final c = _c;
    if (c == null) return [];
    try {
      final rows = await c.from('pm_dogs').select();
      final mine = myEmail.toLowerCase();
      return [
        for (final r in rows)
          if ((r['owner_email'] as String? ?? '').toLowerCase() != mine)
            DogProfile(
              id: r['id'] as String? ?? '',
              name: r['name'] as String? ?? '',
              breed: r['breed'] as String? ?? '',
              age: (r['age'] as num?)?.toInt() ?? 1,
              city: r['city'] as String? ?? '',
              lat: (r['lat'] as num?)?.toDouble() ?? 59.33,
              lng: (r['lng'] as num?)?.toDouble() ?? 18.07,
              bio: r['bio'] as String? ?? '',
              owner: r['owner_name'] as String? ?? 'Ägare',
              tags: const ['friends'],
              photos: List<String>.from(r['photos'] ?? const []),
              photoUrl: (List<String>.from(r['photos'] ?? const [])).isEmpty
                  ? ''
                  : List<String>.from(r['photos']).first,
              sex: r['sex'] as String? ?? '',
              intent: r['intent'] as String? ?? 'friends',
              availableForBreeding: (r['intent'] as String? ?? '') == 'puppies',
            ),
      ];
    } catch (e) {
      debugPrint('liveDogs $e');
      return [];
    }
  }

  static Future<bool> like({required String fromEmail, required String toEmail, required String dogId}) async {
    final c = _c;
    if (c == null) return false;
    try {
      await c.from('pm_likes').upsert({
        'from_email': fromEmail.toLowerCase(),
        'to_email': toEmail.toLowerCase(),
        'dog_id': dogId,
      }, onConflict: 'from_email,to_email,dog_id');
      final back = await c
          .from('pm_likes')
          .select()
          .eq('from_email', toEmail.toLowerCase())
          .eq('to_email', fromEmail.toLowerCase());
      return back.isNotEmpty;
    } catch (e) {
      debugPrint('like $e');
      return false;
    }
  }

  static Future<String?> ensureMatch({
    required String a,
    required String b,
    required Map<String, dynamic> dogJson,
  }) async {
    final c = _c;
    if (c == null) return null;
    try {
      final existing = await c.from('pm_matches').select().or(
            'and(user_a.eq.${a.toLowerCase()},user_b.eq.${b.toLowerCase()}),and(user_a.eq.${b.toLowerCase()},user_b.eq.${a.toLowerCase()})',
          );
      if (existing.isNotEmpty) return existing.first['id'] as String?;
      final row = await c.from('pm_matches').insert({
        'user_a': a.toLowerCase(),
        'user_b': b.toLowerCase(),
        'dog_json': dogJson,
        'accepted': true,
      }).select().single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('ensureMatch $e');
      return null;
    }
  }

  static Future<void> sendMessage(String matchId, String sender, String text) async {
    final c = _c;
    if (c == null || matchId.isEmpty) return;
    try {
      await c.from('pm_messages').insert({
        'match_id': matchId,
        'sender': sender.toLowerCase(),
        'text': text,
      });
    } catch (e) {
      debugPrint('sendMessage $e');
    }
  }

  static Future<List<ChatLine>> messages(String matchId, String me) async {
    final c = _c;
    if (c == null || matchId.isEmpty) return [];
    try {
      final rows = await c.from('pm_messages').select().eq('match_id', matchId).order('created_at');
      return [
        for (final r in rows)
          ChatLine((r['sender'] as String? ?? '').toLowerCase() == me.toLowerCase(), r['text'] as String? ?? ''),
      ];
    } catch (e) {
      debugPrint('messages $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> myMatches(String email) async {
    final c = _c;
    if (c == null) return [];
    try {
      final a = await c.from('pm_matches').select().eq('user_a', email.toLowerCase());
      final b = await c.from('pm_matches').select().eq('user_b', email.toLowerCase());
      return [...a, ...b];
    } catch (e) {
      debugPrint('myMatches $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> incomingLikes(String email) async {
    final c = _c;
    if (c == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
        await c.from('pm_likes').select().eq('to_email', email.toLowerCase()),
      );
    } catch (e) {
      debugPrint('incomingLikes $e');
      return [];
    }
  }
}
