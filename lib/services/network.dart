import 'dart:io';

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

  static Future<String?> uploadPhoto(String path) async {
    if (path.startsWith('http')) return path;
    final c = _c;
    if (c == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      final name = 'dogs/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await c.storage.from('dog-photos').uploadBinary(
            name,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return c.storage.from('dog-photos').getPublicUrl(name);
    } catch (e) {
      debugPrint('uploadPhoto $e');
      return null;
    }
  }

  static Future<List<String>> publicPhotos(List<String> photos) async {
    final out = <String>[];
    for (final p in photos) {
      final url = await uploadPhoto(p);
      if (url != null && url.startsWith('http')) out.add(url);
    }
    return out;
  }

  static bool _flag(dynamic v) => v == true;

  static DogProfile dogFromRow(Map<String, dynamic> r) {
    final photos = <String>[
      for (final p in List<String>.from(r['photos'] ?? const []))
        if (p.startsWith('http')) p,
    ];
    final vaccinated = _flag(r['vaccinated']);
    final pedigree = _flag(r['has_pedigree']);
    return DogProfile(
      id: r['id'] as String? ?? '',
      name: r['name'] as String? ?? '',
      breed: r['breed'] as String? ?? '',
      age: (r['age'] as num?)?.toInt() ?? 1,
      city: r['city'] as String? ?? '',
      lat: (r['lat'] as num?)?.toDouble() ?? 59.33,
      lng: (r['lng'] as num?)?.toDouble() ?? 18.07,
      bio: r['bio'] as String? ?? '',
      owner: r['owner_name'] as String? ?? 'Ägare',
      ownerEmail: r['owner_email'] as String? ?? '',
      tags: const ['friends'],
      photos: photos,
      photoUrl: photos.isEmpty ? '' : photos.first,
      sex: r['sex'] as String? ?? '',
      weightKg: (r['weight_kg'] as num?)?.toDouble() ?? 0,
      intent: r['intent'] as String? ?? 'friends',
      availableForBreeding: (r['intent'] as String? ?? '') == 'puppies',
      chipped: _flag(r['chipped']),
      vaccinated: vaccinated,
      dewormed: _flag(r['dewormed']),
      neutered: _flag(r['neutered']),
      hasPedigree: pedigree,
      hasAllergies: _flag(r['has_allergies']),
      allergyNote: r['allergy_note'] as String? ?? '',
      healthNote: r['health_note'] as String? ?? '',
      vaccineNote: r['vaccine_note'] as String? ?? '',
      pedigreeNote: r['pedigree_note'] as String? ?? '',
      vaccineStatus: vaccinated ? ReviewStatus.approved : ReviewStatus.none,
      pedigreeStatus: pedigree ? ReviewStatus.approved : ReviewStatus.none,
    );
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
      final urls = await publicPhotos(dog.photos);
      if (urls.isNotEmpty) dog.photos = urls;
      await c.from('pm_dogs').upsert({
        'id': id,
        'owner_email': email.toLowerCase(),
        'owner_name': owner,
        'name': dog.name,
        'breed': dog.breed,
        'sex': dog.sex,
        'age': dog.age,
        'weight_kg': dog.weightKg,
        'city': dog.city,
        'intent': dog.availableForBreeding ? 'puppies' : 'friends',
        'bio': dog.bio,
        'photos': urls,
        'lat': lat,
        'lng': lng,
        'chipped': dog.chipped,
        'vaccinated': dog.vaccinated,
        'dewormed': dog.dewormed,
        'neutered': dog.neutered,
        'has_pedigree': dog.hasPedigree,
        'has_allergies': dog.hasAllergies,
        'allergy_note': dog.allergyNote,
        'health_note': dog.healthNote,
        'vaccine_note': dog.vaccineNote,
        'pedigree_note': dog.pedigreeNote,
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
          if ((r['owner_email'] as String? ?? '').toLowerCase() != mine) dogFromRow(Map<String, dynamic>.from(r as Map)),
      ];
    } catch (e) {
      debugPrint('liveDogs $e');
      return [];
    }
  }

  static Future<List<String>> likersOf(String email) async {
    final c = _c;
    if (c == null || !email.contains('@')) return [];
    try {
      final rows = await c.from('pm_likes').select('from_email').eq('to_email', email.toLowerCase());
      return [
        for (final r in rows)
          if (((r['from_email'] as String?) ?? '').contains('@')) (r['from_email'] as String).toLowerCase(),
      ];
    } catch (e) {
      debugPrint('likersOf $e');
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
      });
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
    final aa = a.toLowerCase();
    final bb = b.toLowerCase();
    try {
      final one = await c.from('pm_matches').select().eq('user_a', aa).eq('user_b', bb);
      if (one.isNotEmpty) return one.first['id'] as String?;
      final two = await c.from('pm_matches').select().eq('user_a', bb).eq('user_b', aa);
      if (two.isNotEmpty) return two.first['id'] as String?;
      final row = await c.from('pm_matches').insert({
        'user_a': aa,
        'user_b': bb,
        'dog_json': dogJson,
        'accepted': true,
      }).select().single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('ensureMatch $e');
      return null;
    }
  }

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

  static DateTime? _when(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse('$raw')?.toLocal();
  }

  static bool _systemText(String text) {
    return text.startsWith('Ni matchade') || text.startsWith('Gruppen är skapad') || text.endsWith('lades till i gruppen.') || text.endsWith('togs bort från gruppen.');
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
            id: '${r['id']}',
            recalled: r['recalled'] == true,
            createdAt: _when(r['created_at']),
            seen: r['seen_at'] != null,
            system: _systemText(r['text'] as String? ?? ''),
          ),
      ];
    } catch (e) {
      debugPrint('messages $e');
      return null;
    }
  }

  static Future<void> markSeen(String matchId, String me) async {
    final c = _c;
    if (c == null || matchId.isEmpty || !me.contains('@')) return;
    try {
      await c.from('pm_messages').update({'seen_at': DateTime.now().toUtc().toIso8601String()}).eq('match_id', matchId).neq('sender', me.toLowerCase()).isFilter('seen_at', null);
    } catch (e) {
      debugPrint('markSeen $e');
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

  static Future<void> saveDevice(String email, String token) async {
    final c = _c;
    if (c == null || !email.contains('@') || token.isEmpty) return;
    try {
      await c.from('pm_devices').upsert({
        'token': token,
        'email': email.toLowerCase(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('saveDevice $e');
    }
  }

  static String _lastPushNote = '';

  static Future<void> notePush(String email, String note) async {
    final c = _c;
    final text = note.trim();
    if (c == null || !email.contains('@') || text.isEmpty || text == _lastPushNote) return;
    _lastPushNote = text;
    try {
      await c.from('pm_push_log').insert({'email': email.toLowerCase(), 'note': text.length > 280 ? text.substring(0, 280) : text});
    } catch (e) {
      debugPrint('notePush $e');
    }
  }

  static Future<void> ping(String toEmail, String title, String body) async {
    final c = _c;
    final to = toEmail.trim().toLowerCase();
    final text = body.trim();
    if (c == null || !to.contains('@') || text.isEmpty) return;
    try {
      await c.functions.invoke('notify', body: {
        'to_email': to,
        'title': title,
        'body': text.length > 140 ? '${text.substring(0, 137)}...' : text,
      });
    } catch (e) {
      debugPrint('ping $e');
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

  static Future<List<Map<String, dynamic>>?> myGroups(String email) async {
    final c = _c;
    if (c == null || !email.contains('@')) return null;
    try {
      final mine = await c.from('pm_group_members').select('group_id').eq('email', email.toLowerCase());
      final ids = <String>[
        for (final r in mine)
          if ('${r['group_id']}'.isNotEmpty) '${r['group_id']}',
      ];
      if (ids.isEmpty) return [];
      final groups = await c.from('pm_groups').select().inFilter('id', ids);
      final members = await c.from('pm_group_members').select().inFilter('group_id', ids);
      return [
        for (final g in groups)
          {
            ...Map<String, dynamic>.from(g as Map),
            'members': [
              for (final m in members)
                if ('${m['group_id']}' == '${g['id']}') Map<String, dynamic>.from(m as Map),
            ],
          },
      ];
    } catch (e) {
      debugPrint('myGroups $e');
      return null;
    }
  }

  static Future<String?> createGroup({
    required String name,
    required String ownerEmail,
    required String ownerName,
    required List<GroupMember> members,
  }) async {
    final c = _c;
    if (c == null) return null;
    try {
      final row = await c.from('pm_groups').insert({
        'name': name,
        'owner_email': ownerEmail.toLowerCase(),
      }).select('id').single();
      final id = '${row['id']}';
      await c.from('pm_group_members').insert([
        {'group_id': id, 'email': ownerEmail.toLowerCase(), 'display_name': ownerName},
        for (final m in members) {'group_id': id, 'email': m.email.toLowerCase(), 'display_name': m.name},
      ]);
      await c.from('pm_group_messages').insert({
        'group_id': id,
        'sender': ownerEmail.toLowerCase(),
        'text': 'Gruppen är skapad. Nu kan ni planera promenaden.',
      });
      return id;
    } catch (e) {
      debugPrint('createGroup $e');
      return null;
    }
  }

  static Future<List<ChatLine>?> groupMessages(String groupId, String me, Map<String, String> names) async {
    final c = _c;
    if (c == null || groupId.isEmpty) return null;
    try {
      final rows = await c.from('pm_group_messages').select().eq('group_id', groupId).order('created_at');
      return [
        for (final r in rows)
          ChatLine(
            (r['sender'] as String? ?? '').toLowerCase() == me.toLowerCase(),
            r['text'] as String? ?? '',
            id: '${r['id']}',
            recalled: r['recalled'] == true,
            senderName: names[(r['sender'] as String? ?? '').toLowerCase()] ?? '',
            createdAt: _when(r['created_at']),
            system: _systemText(r['text'] as String? ?? ''),
          ),
      ];
    } catch (e) {
      debugPrint('groupMessages $e');
      return null;
    }
  }

  static Future<void> sendGroupMessage(String groupId, String sender, String text) async {
    final c = _c;
    if (c == null || groupId.isEmpty) return;
    try {
      await c.from('pm_group_messages').insert({
        'group_id': groupId,
        'sender': sender.toLowerCase(),
        'text': text,
      });
    } catch (e) {
      debugPrint('sendGroupMessage $e');
    }
  }

  static Future<void> addGroupMember(String groupId, GroupMember member) async {
    final c = _c;
    if (c == null || groupId.isEmpty) return;
    try {
      await c.from('pm_group_members').upsert({
        'group_id': groupId,
        'email': member.email.toLowerCase(),
        'display_name': member.name,
      });
    } catch (e) {
      debugPrint('addGroupMember $e');
    }
  }

  static Future<void> removeGroupMember(String groupId, String email) async {
    final c = _c;
    if (c == null || groupId.isEmpty) return;
    try {
      await c.from('pm_group_members').delete().eq('group_id', groupId).eq('email', email.toLowerCase());
    } catch (e) {
      debugPrint('removeGroupMember $e');
    }
  }

  static Future<void> deleteGroup(String groupId) async {
    final c = _c;
    if (c == null || groupId.isEmpty) return;
    try {
      await c.from('pm_groups').delete().eq('id', groupId);
    } catch (e) {
      debugPrint('deleteGroup $e');
    }
  }
}
