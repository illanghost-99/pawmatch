import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'services/location.dart';
import 'services/network.dart';
import 'services/fcm.dart';
import 'services/push.dart';
import 'services/badge.dart';
import 'services/session.dart';
import 'v2/circle_models.dart';

class AppState extends ChangeNotifier {
  UserRole role = UserRole.owner;
  final Set<String> interests = {};
  bool onboarded = false;
  bool signedIn = false;
  bool sessionReady = false;
  bool chatsReady = false;
  bool groupsReady = false;
  String? pendingKind;
  String? pendingPeer;
  String? pendingGroup;
  String _lastNoticeKey = '';
  DateTime? _lastNoticeAt;
  bool gpsOn = false;
  DateTime? premiumUntil;
  int swipesToday = 0;
  DateTime swipeDay = DateTime.now();
  final List<WalkCircle> circles = [];
  String email = '';
  String banNote = '';
  String firstName = '';
  String lastName = '';
  String personalNumber = '';
  String address = '';
  String phone = '';
  bool idConsent = false;
  bool identityPending = false;
  String displayName = 'Max';
  String ownerBio = '';
  String photoUrl = '';
  double lat = 59.3293;
  double lng = 18.0686;
  String locationLabel = 'Stockholm';
  String breedQuery = '';
  int ageMin = 0;
  int ageMax = 15;
  int radiusKm = 250;
  String area = '';
  String intentFilter = 'all';
  String premiumIntent = 'all';
  String sizeFilter = 'all';
  String feedSort = 'forYou';
  List<DogProfile> liveDogs = [];
  List<DogProfile> deck = [];
  bool dogsReady = false;
  final List<MatchThread> matches = [];
  final List<GroupChat> groups = [];
  final List<MatchThread> incoming = [];
  final Set<String> handledPeers = {};
  final List<DogProfile> saved = [];
  DogProfile? lastPassed;
  final Set<String> blocked = {};
  final Set<String> blockedOwners = {};
  final Map<String, DateTime> hiddenUntil = {};
  final List<MyDog> myDogs = [];
  String lastNotice = '';
  String celebrate = '';
  Timer? _inbox;
  final Set<String> _seenLikes = {};
  bool _seenLikesReady = false;

  static const freeSwipesPerDay = 12;

  bool darkMode = false;
  bool discoverable = true;
  final Set<String> _readMessageIds = {};
  bool notifyOn = true;

  bool get isPremium => premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  int get swipesLeft {
    _rollSwipes();
    if (isPremium) return 999;
    return (freeSwipesPerDay - swipesToday).clamp(0, freeSwipesPerDay);
  }

  void _rollSwipes() {
    final n = DateTime.now();
    if (swipeDay.day != n.day || swipeDay.month != n.month) {
      swipeDay = n;
      swipesToday = 0;
    }
  }

  void startLaunchOffer() {
    premiumUntil = DateTime.now().add(const Duration(days: 150));
    notifyListeners();
    Network.markPremium(email, true);
  }

  void addCircle(String name) {
    if (!isPremium) return;
    circles.insert(0, WalkCircle(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name));
    notifyListeners();
  }

  void sendCircle(WalkCircle c, String text) {
    c.messages.add(ChatLine(true, text));
    notifyListeners();
  }

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? displayName : n;
  }

  String get mySex {
    if (myDogs.isEmpty) return '';
    return myDogs.first.sex.toLowerCase();
  }

  String get oppositeSex {
    if (mySex == 'hane') return 'tik';
    if (mySex == 'tik') return 'hane';
    return '';
  }

  int get chatBadge {
    final likes = isPremium ? incoming.length : (incoming.isEmpty ? 0 : 1);
    return likes + matches.where((m) => m.unread > 0).length + groups.where((g) => g.unread > 0).length;
  }

  int get dealBadge => deals.where((t) {
        final d = t.deal;
        return d != null && d.signedByMe.isEmpty && d.signedByOther.isNotEmpty;
      }).length;

  int _iconBadge = -1;

  @override
  void notifyListeners() {
    Network.ownerEmail = email.toLowerCase();
    super.notifyListeners();
    final n = signedIn ? chatBadge : 0;
    if (n == _iconBadge) return;
    _iconBadge = n;
    BadgeCount.set(n);
  }

  List<MatchThread> get deals => matches.where((m) => m.deal != null).toList();

  List<DogProfile> get _pool => [
        for (final d in liveDogs)
          if (d.ownerEmail.contains('@')) d,
      ];

  Future<void> restore() async {
    final s = await Session.read();
    email = s['email'] ?? '';
    firstName = s['firstName'] ?? '';
    lastName = s['lastName'] ?? '';
    phone = s['phone'] ?? '';
    onboarded = s['onboarded'] == 'true';
    idConsent = s['idConsent'] == 'true';
    signedIn = s['signedIn'] == 'true' && email.contains('@');
    sessionReady = true;
    await _loadPrefs();
    if (signedIn) {
      await refreshBan();
      if (banNote.isEmpty) {
        PushService.init();
        _armPush();
        locate();
        syncCloud();
        _watchInbox();
      }
    }
    notifyListeners();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    darkMode = p.getBool('darkMode') ?? false;
    photoUrl = p.getString('photoUrl') ?? photoUrl;
    discoverable = p.getBool('discoverable') ?? true;
    notifyOn = p.getBool('notifyOn') ?? true;
    _readMessageIds.addAll(p.getStringList('readMessages') ?? const []);
    if (email.contains('@')) {
      final seenKey = 'seenLikes:${email.toLowerCase()}';
      _seenLikes
        ..clear()
        ..addAll(p.getStringList(seenKey) ?? const []);
      _seenLikesReady = p.containsKey(seenKey);
    }
    blocked.addAll(p.getStringList('blockedDogs') ?? const []);
    blockedOwners.addAll(p.getStringList('blockedOwners') ?? const []);
    final rawDeals = p.getString('pmDeals');
    if (rawDeals != null && rawDeals.isNotEmpty) {
      final decoded = jsonDecode(rawDeals);
      if (decoded is Map) _dealCache = Map<String, dynamic>.from(decoded);
    }
    _readDogs(p);
    _readHidden(p);
  }

  void _readDogs(SharedPreferences p) {
    if (!email.contains('@')) return;
    final raw = p.getString('pmMyDogs:${email.toLowerCase()}');
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      myDogs
        ..clear()
        ..addAll([
          for (final item in decoded)
            if (item is Map) MyDog.fromJson(Map<String, dynamic>.from(item)),
        ]);
    } catch (e) {
      debugPrint('readDogs $e');
    }
  }

  Future<void> _saveDogs() async {
    if (!email.contains('@')) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('pmMyDogs:${email.toLowerCase()}', jsonEncode([for (final d in myDogs) d.toJson()]));
  }

  void _readHidden(SharedPreferences p) {
    hiddenUntil.clear();
    if (!email.contains('@')) return;
    final raw = p.getString('hiddenUntil:${email.toLowerCase()}');
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final now = DateTime.now();
      for (final e in decoded.entries) {
        final until = DateTime.tryParse('${e.value}');
        if (until != null && until.isAfter(now)) hiddenUntil['${e.key}'] = until;
      }
    } catch (e) {
      debugPrint('readHidden $e');
    }
  }

  void _storeHidden() {
    if (!email.contains('@')) return;
    final now = DateTime.now();
    hiddenUntil.removeWhere((_, until) => !until.isAfter(now));
    final saved = {for (final e in hiddenUntil.entries) e.key: e.value.toIso8601String()};
    SharedPreferences.getInstance().then((p) => p.setString('hiddenUntil:${email.toLowerCase()}', jsonEncode(saved)));
  }

  MyDog _mergeOwn(MyDog? local, MyDog remote) {
    if (local == null) return remote;
    remote.pedigreeDoc = local.pedigreeDoc;
    remote.vaccineDoc = local.vaccineDoc;
    remote.pedigreeStatus = local.pedigreeStatus;
    remote.vaccineStatus = local.vaccineStatus;
    if (local.photos.any((p) {
      final t = p.trim();
      return t.isNotEmpty && !t.startsWith('http') && File(t).existsSync();
    })) {
      remote.photos = List.of(local.photos);
    } else if (remote.photos.isEmpty) {
      remote.photos = List.of(local.photos);
    }
    return remote;
  }

  Future<void> setDarkMode(bool on) async {
    darkMode = on;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('darkMode', on);
  }

  Future<bool> setDiscoverable(bool on) async {
    if (!on && !isPremium) {
      lastNotice = 'Att pausa profilen ingår i Premium.';
      notifyListeners();
      return false;
    }
    discoverable = on;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('discoverable', on);
    await Network.setVisible(email, on);
    return true;
  }

  Future<void> setNotify(bool on) async {
    notifyOn = on;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifyOn', on);
  }

  Future<void> persist() async {
    await Session.write(
      signedIn: signedIn,
      onboarded: onboarded,
      idConsent: idConsent,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  Future<void> refreshBan() async {
    if (!email.contains('@')) {
      banNote = '';
      return;
    }
    banNote = await Network.banStatus(email);
  }

  Future<void> syncCloud() async {
    if (!email.contains('@')) return;
    await refreshBan();
    if (banNote.isNotEmpty) {
      notifyListeners();
      return;
    }
    liveDogs = await Network.liveDogs(email);
    dogsReady = true;
    final remote = await Network.ownerProfile(email);
    final remotePhoto = '${remote?['photo_url'] ?? ''}';
    if (remotePhoto.startsWith('http')) {
      photoUrl = remotePhoto;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photoUrl', photoUrl);
    }
    for (final d in myDogs) {
      await Network.upsertDog(email: email, owner: fullName, dog: d, lat: lat, lng: lng);
    }
    final own = await Network.ownDogs(email);
    if (own != null) {
      final local = {for (final d in myDogs) d.name.toLowerCase(): d};
      final seen = <String>{};
      final merged = <MyDog>[];
      for (final remote in own) {
        final key = remote.name.toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        merged.add(_mergeOwn(local[key], remote));
      }
      for (final entry in local.entries) {
        if (!seen.contains(entry.key)) merged.add(entry.value);
      }
      myDogs
        ..clear()
        ..addAll(merged);
      await _saveDogs();
    }
    if (isPremium) await Network.markPremium(email, true);
    applyFilters();
    await pullInbox();
    await pullChats();
    await pullGroups();
    notifyListeners();
  }

  void _watchInbox() {
    _inbox?.cancel();
    _inbox = Timer.periodic(const Duration(seconds: 2), (_) async {
      await Fcm.keepAlive();
      if (email.contains('@')) {
        final token = Fcm.token;
        await Network.notePush(email, token == null || token.isEmpty ? (Fcm.lastError ?? 'ingen token') : 'token sparad');
      }
      await pullInbox();
      await pullChats();
      await pullGroups();
    });
    Fcm.keepAlive();
    pullInbox();
    pullChats();
    pullGroups();
  }

  Map<String, dynamic> _dogJson(DogProfile d, String peer, {MyDog? mine}) {
    final me = email.toLowerCase();
    final mineName = mine?.name.trim() ?? '';
    final minePhoto = mine == null ? '' : _dogPhoto(mine);
    final mineId = mineName.isEmpty ? '' : '$me-${mineName.toLowerCase()}';
    return {
      'name': d.name,
      'breed': d.breed,
      'owner': d.owner,
      'id': d.id,
      'owner_email': peer,
      'photo': d.photoUrl,
      'from_name': fullName,
      'from_email': me,
      'from_dog': mineName,
      'from_dog_id': mineId,
      'from_photo': minePhoto,
      'dogs': {
        peer: {'name': d.name, 'id': d.id, 'photo': d.photoUrl, 'owner': d.owner},
        if (mineName.isNotEmpty) me: {'name': mineName, 'id': mineId, 'photo': minePhoto, 'owner': fullName},
      },
    };
  }

  String _dogPhoto(MyDog dog) {
    for (final p in dog.photos) {
      final t = p.trim();
      if (t.isNotEmpty) return t;
    }
    return '';
  }

  MyDog? _myMatchedDog(String dogId) {
    if (myDogs.isEmpty) return null;
    if (dogId.isNotEmpty) {
      final id = dogId.toLowerCase();
      for (final d in myDogs) {
        if ('${email.toLowerCase()}-${d.name.toLowerCase()}' == id) return d;
      }
    }
    return myDogs.length == 1 ? myDogs.first : null;
  }

  Future<Map<String, dynamic>> _pairJson(DogProfile theirs, String peer) async {
    final myId = await Network.likedDogId(peer, email);
    return _dogJson(theirs, peer, mine: _myMatchedDog(myId));
  }

  Future<void> _fillPair(Map<String, dynamic> row, String peer) async {
    final json = Map<String, dynamic>.from(row['dog_json'] ?? {});
    final dogs = <String, dynamic>{};
    final raw = json['dogs'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.value is Map) dogs['${e.key}'.toLowerCase()] = e.value;
      }
    }
    final me = email.toLowerCase();
    var changed = false;
    if (dogs[peer] is! Map) {
      final id = await Network.likedDogId(email, peer);
      DogProfile? live;
      for (final d in liveDogs) {
        if (id.isNotEmpty && d.id == id) live = d;
      }
      var name = live?.name ?? '';
      if (name.isEmpty) {
        final prefix = '$peer-';
        if (id.toLowerCase().startsWith(prefix) && id.length > prefix.length) name = id.substring(prefix.length);
      }
      if (name.isEmpty && '${json['owner_email']}'.toLowerCase() == peer) name = '${json['name'] ?? ''}'.trim();
      if (name.isEmpty && '${json['from_email']}'.toLowerCase() == peer) name = '${json['from_dog'] ?? ''}'.trim();
      if (name.isNotEmpty) {
        dogs[peer] = {
          'name': name,
          'id': live?.id ?? id,
          'photo': (live?.photoUrl ?? '').isNotEmpty ? live!.photoUrl : '${json['photo'] ?? ''}',
          'owner': (live?.owner ?? '').isNotEmpty ? live!.owner : '${json['owner'] ?? ''}',
        };
        changed = true;
      }
    }
    if (dogs[me] is! Map) {
      final id = await Network.likedDogId(peer, email);
      final mine = _myMatchedDog(id);
      if (mine != null) {
        dogs[me] = {'name': mine.name, 'id': '$me-${mine.name.toLowerCase()}', 'photo': _dogPhoto(mine), 'owner': fullName};
        changed = true;
      }
    }
    if (!changed) return;
    json['dogs'] = dogs;
    row['dog_json'] = json;
    await Network.saveMatchDogs('${row['id']}', json);
  }

  DogProfile _dogFromMatch(Map<String, dynamic> r, String peer) {
    final json = Map<String, dynamic>.from(r['dog_json'] ?? {});
    final me = email.toLowerCase();
    final mine = <String>{for (final d in myDogs) d.name.trim().toLowerCase()};
    bool own(String name, String id, String key) {
      final n = name.trim().toLowerCase();
      if (n.isNotEmpty && mine.contains(n)) return true;
      if (id.toLowerCase().startsWith('$me-')) return true;
      return key == me;
    }

    final candidates = <Map<String, dynamic>>[];
    void add(String name, String id, String photo, String owner, String key) {
      final title = name.trim();
      if (title.isEmpty) return;
      candidates.add({'name': title, 'id': id, 'photo': photo, 'owner': owner, 'key': key.toLowerCase()});
    }

    final dogs = json['dogs'];
    if (dogs is Map) {
      for (final e in dogs.entries) {
        if (e.value is! Map) continue;
        final v = Map<String, dynamic>.from(e.value as Map);
        add('${v['name'] ?? ''}', '${v['id'] ?? ''}', '${v['photo'] ?? ''}', '${v['owner'] ?? ''}', '${e.key}');
      }
    }
    add('${json['name'] ?? ''}', '${json['id'] ?? ''}', '${json['photo'] ?? ''}', '${json['owner'] ?? ''}', '${json['owner_email'] ?? ''}');
    add('${json['from_dog'] ?? ''}', '${json['from_dog_id'] ?? ''}', '${json['from_photo'] ?? ''}', '${json['from_name'] ?? ''}', '${json['from_email'] ?? ''}');

    Map<String, dynamic> entry = {};
    for (final c in candidates) {
      final id = '${c['id']}';
      final key = '${c['key']}';
      if (key == peer && !own('${c['name']}', id, key)) {
        entry = c;
        break;
      }
    }
    if ('${entry['name'] ?? ''}'.trim().isEmpty) {
      for (final c in candidates) {
        if ('${c['id']}'.toLowerCase().startsWith('$peer-')) {
          entry = c;
          break;
        }
      }
    }
    if ('${entry['name'] ?? ''}'.trim().isEmpty) {
      for (final c in candidates) {
        if (!own('${c['name']}', '${c['id']}', '${c['key']}')) {
          entry = c;
          break;
        }
      }
    }
    final storedId = '${entry['id'] ?? ''}';
    final storedName = '${entry['name'] ?? ''}'.trim();
    final storedKey = storedName.toLowerCase();
    for (final d in liveDogs) {
      if (storedId.isNotEmpty && d.id == storedId && d.ownerEmail.toLowerCase() == peer) return d;
    }
    for (final d in liveDogs) {
      if (d.ownerEmail.toLowerCase() == peer && storedKey.isNotEmpty && d.name.toLowerCase() == storedKey) return d;
    }
    return DogProfile(
      id: storedId.isEmpty ? 'match-$peer' : storedId,
      name: storedName.isEmpty ? 'Hund' : storedName,
      breed: '${json['breed'] ?? ''}',
      age: 1,
      city: '',
      lat: lat,
      lng: lng,
      bio: '',
      owner: '${entry['owner'] ?? ''}'.trim().isEmpty ? peer : '${entry['owner']}',
      tags: const [],
      photoUrl: '${entry['photo'] ?? ''}',
      ownerEmail: peer,
    );
  }

  Future<void> pullChats() async {
    if (!email.contains('@')) return;
    final rows = await Network.myMatches(email);
    if (rows == null) return;
    final me = email.toLowerCase();
    for (final r in rows) {
      final id = '${r['id']}';
      final a = (r['user_a'] as String? ?? '').toLowerCase();
      final b = (r['user_b'] as String? ?? '').toLowerCase();
      final peer = a == me ? b : a;
      final hidden = <String>[
        for (final h in List.from(r['hidden_by'] ?? const [])) h.toString().toLowerCase(),
      ];
      if (hidden.contains(me) && !handledPeers.contains(peer)) {
        matches.removeWhere((m) => m.cloudMatchId == id);
        continue;
      }
      if (hidden.contains(me)) Network.unhideMatch(id, email);
      await _fillPair(r, peer);
      MatchThread? thread;
      for (final m in matches) {
        if (m.cloudMatchId == id || (peer.isNotEmpty && m.peerEmail.toLowerCase() == peer)) {
          thread = m;
          break;
        }
      }
      if (thread == null) {
        thread = MatchThread(_dogFromMatch(r, peer), [], accepted: true, outgoing: false, peerEmail: peer, cloudMatchId: id);
        matches.insert(0, thread);
      } else {
        thread.accepted = true;
        thread.cloudMatchId = id;
        final dog = _dogFromMatch(r, peer);
        if (dog.name.isNotEmpty && dog.name != 'Hund' && dog.name != 'Match') thread.dog = dog;
      }
      attachDeal(thread);
      _takeCloudDeal(thread, r);
      incoming.removeWhere((m) => m.peerEmail.toLowerCase() == peer);
      await refreshChat(thread, countUnread: true);
    }
    chatsReady = true;
    if (matches.any((m) => m.deal != null)) _saveDeals();
    applyFilters();
    notifyListeners();
  }

  Future<void> pullInbox() async {
    if (!email.contains('@')) return;
    final froms = await Network.likersOf(email);
    var changed = false;
    for (final from in froms) {
      if (handledPeers.contains(from)) continue;
      if (matches.any((m) => m.accepted && m.peerEmail.toLowerCase() == from)) continue;
      if (incoming.any((m) => m.peerEmail.toLowerCase() == from)) continue;
      DogProfile? dog;
      for (final d in liveDogs) {
        if (d.ownerEmail.toLowerCase() == from) {
          dog = d;
          break;
        }
      }
      dog ??= DogProfile(
        id: 'like-$from',
        name: 'Hund',
        breed: '',
        age: 1,
        city: '',
        lat: lat,
        lng: lng,
        bio: 'Vill matcha med dig',
        owner: from,
        tags: const [],
        ownerEmail: from,
      );
      incoming.insert(0, MatchThread(dog, [], accepted: false, outgoing: false, peerEmail: from));
      changed = true;
      if (_seenLikes.add(from) && _seenLikesReady) {
        if (notifyOn) PushService.notifyLike(dog.name, peer: from);
        lastNotice = '${dog.owner} vill matcha med dig';
        _storeSeenLikes();
      }
    }
    if (!_seenLikesReady) {
      _seenLikesReady = true;
      _storeSeenLikes();
    }
    if (changed) notifyListeners();
  }

  void _storeSeenLikes() {
    if (!email.contains('@')) return;
    final key = 'seenLikes:${email.toLowerCase()}';
    final list = _seenLikes.toList();
    SharedPreferences.getInstance().then((p) => p.setStringList(key, list));
  }

  Future<void> refreshChat(MatchThread t, {bool countUnread = false, bool markSeen = false}) async {
    if (t.cloudMatchId.isEmpty) return;
    if (markSeen) await Network.markSeen(t.cloudMatchId, email);
    final lines = await Network.messages(t.cloudMatchId, email);
    if (lines == null) return;
    final prev = t.messages.map((m) => m.id).toSet();
    final pending = t.messages.where((m) => m.id.isEmpty && m.fromMe).toList();
    if (countUnread) {
      final unseen = lines.where((m) => !m.fromMe && m.id.isNotEmpty && !m.recalled && !m.seen && !_readMessageIds.contains(m.id)).length;
      if (prev.isEmpty) {
        t.unread = unseen;
      } else {
        final fresh = lines.where((m) => !m.fromMe && m.id.isNotEmpty && !prev.contains(m.id) && !m.recalled && !m.seen && !_readMessageIds.contains(m.id)).length;
        if (fresh > 0) {
          t.unread += fresh;
        }
      }
    } else if (markSeen) {
      t.unread = 0;
      _rememberRead(lines.map((m) => m.id));
    }
    t.messages
      ..clear()
      ..addAll(lines);
    for (final p in pending) {
      if (!lines.any((m) => m.fromMe && m.text == p.text)) t.messages.add(p);
    }
    notifyListeners();
  }

  Future<void> deleteThread(MatchThread t) async {
    matches.remove(t);
    incoming.remove(t);
    notifyListeners();
    if (t.cloudMatchId.isNotEmpty) await Network.hideMatch(t.cloudMatchId, email);
  }

  Future<void> recall(MatchThread t, ChatLine line) async {
    if (!line.fromMe || line.id.isEmpty) return;
    await Network.recallMessage(line.id, email);
    await refreshChat(t);
  }

  Future<bool> locate() async {
    final pos = await Locator.current();
    if (pos == null) {
      gpsOn = false;
      notifyListeners();
      return false;
    }
    lat = pos.$1;
    lng = pos.$2;
    gpsOn = true;
    if (locationLabel.isEmpty || locationLabel == 'Stockholm') {
      locationLabel = 'Min plats';
    }
    applyFilters();
    return true;
  }

  Future<void> signIn(String e, {bool keepIdentity = false}) async {
    final next = e.trim();
    final changed = email.toLowerCase() != next.toLowerCase();
    email = next;
    signedIn = true;
    if (changed) {
      firstName = '';
      lastName = '';
      ownerBio = '';
      photoUrl = '';
      displayName = '';
      personalNumber = '';
      address = '';
      phone = '';
      if (!keepIdentity) idConsent = false;
      onboarded = false;
      identityPending = false;
      myDogs.clear();
      matches.clear();
      incoming.clear();
      groups.clear();
      saved.clear();
      liveDogs.clear();
      interests.clear();
      handledPeers.clear();
      _readMessageIds.clear();
      _seenLikes.clear();
      _seenLikesReady = false;
      celebrate = '';
      lastNotice = '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('photoUrl');
      await prefs.remove('readMessages');
    }
    myDogs.clear();
    final p = await SharedPreferences.getInstance();
    _readDogs(p);
    _readHidden(p);
    await _takeExisting();
    final seenKey = 'seenLikes:${email.toLowerCase()}';
    _seenLikes
      ..clear()
      ..addAll(p.getStringList(seenKey) ?? const []);
    _seenLikesReady = p.containsKey(seenKey);
    PushService.init();
    _armPush();
    persist();
    locate();
    syncCloud();
    _watchInbox();
    notifyListeners();
  }

  Future<void> _takeExisting() async {
    if (!email.contains('@')) return;
    final remote = await Network.ownerProfile(email);
    final own = await Network.ownDogs(email);
    final first = '${remote?['first_name'] ?? ''}'.trim();
    final last = '${remote?['last_name'] ?? ''}'.trim();
    final hasName = first.isNotEmpty || last.isNotEmpty;
    final hasDogs = own != null && own.isNotEmpty;
    if (!hasName && !hasDogs) return;
    if (hasName) {
      firstName = first;
      lastName = last;
      displayName = fullName;
    }
    final bio = '${remote?['bio'] ?? ''}'.trim();
    final city = '${remote?['city'] ?? ''}'.trim();
    if (bio.isNotEmpty) ownerBio = bio;
    if (city.isNotEmpty) locationLabel = city;
    final photo = '${remote?['photo_url'] ?? ''}';
    if (photo.startsWith('http')) photoUrl = photo;
    idConsent = true;
    if (hasDogs) {
      onboarded = true;
      if (myDogs.isEmpty) {
        myDogs.addAll(own);
        await _saveDogs();
      }
    }
  }

  void saveIdentity({
    required String first,
    required String last,
    required String pnr,
    required String addr,
    required String tel,
    required String mail,
  }) {
    firstName = first;
    lastName = last;
    personalNumber = pnr;
    address = addr;
    phone = tel;
    email = mail.isEmpty ? email : mail;
    displayName = fullName;
    idConsent = true;
    identityPending = true;
    persist();
    Network.saveOwner(email: email, first: firstName, last: lastName, bio: ownerBio, city: locationLabel, photo: photoUrl);
    notifyListeners();
  }

  Future<void> saveProfile({
    required String first,
    required String last,
    required String bio,
    required String city,
    required String photo,
  }) async {
    firstName = first;
    lastName = last;
    ownerBio = bio;
    locationLabel = city.isEmpty ? locationLabel : city;
    var url = photo;
    if (url.isNotEmpty && !url.startsWith('http')) {
      final uploaded = await Network.uploadOwnerPhoto(email, url);
      if (uploaded != null) url = uploaded;
    }
    photoUrl = url;
    displayName = fullName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('photoUrl', photoUrl);
    persist();
    await Network.saveOwner(email: email, first: firstName, last: lastName, bio: ownerBio, city: locationLabel, photo: photoUrl);
    notifyListeners();
  }

  void clearCelebrate() {
    if (celebrate.isEmpty) return;
    celebrate = '';
    notifyListeners();
  }

  void signOut() {
    _inbox?.cancel();
    signedIn = false;
    myDogs.clear();
    liveDogs.clear();
    persist();
    Network.signOut();
    notifyListeners();
  }

  Future<void> eraseAccount() async {
    final who = email;
    _inbox?.cancel();
    if (who.contains('@')) {
      await Network.deleteAuth();
      await Network.deleteOwn(who);
    }
    email = '';
    firstName = '';
    lastName = '';
    ownerBio = '';
    photoUrl = '';
    signedIn = false;
    onboarded = false;
    idConsent = false;
    myDogs.clear();
    matches.clear();
    incoming.clear();
    groups.clear();
    saved.clear();
    interests.clear();
    handledPeers.clear();
    _readMessageIds.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('photoUrl');
    await prefs.remove('readMessages');
    await prefs.remove('pmDeals');
    await _saveDogs();
    await persist();
    notifyListeners();
  }

  void toggleInterest(String id) {
    if (!interests.add(id)) interests.remove(id);
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    applyFilters();
    persist();
    locate();
    syncCloud();
    notifyListeners();
  }

  bool _sameDog(DogProfile a, DogProfile b) {
    if (a.id.isNotEmpty && a.id == b.id) return true;
    final ae = a.ownerEmail.toLowerCase();
    final be = b.ownerEmail.toLowerCase();
    return ae.isNotEmpty && ae == be && a.name.toLowerCase() == b.name.toLowerCase();
  }

  bool _keptMatch(DogProfile d) {
    final owner = d.ownerEmail.toLowerCase();
    final name = d.name.toLowerCase();
    for (final m in matches) {
      if (!m.accepted) continue;
      final same = _sameDog(m.dog, d) ||
          (owner.isNotEmpty &&
              m.peerEmail.toLowerCase() == owner &&
              (m.dog.id == d.id || m.dog.name.toLowerCase() == name || liveDogs.where((x) => x.ownerEmail.toLowerCase() == owner).length <= 1));
      if (!same) continue;
      var latest = m.createdAt;
      for (final line in m.messages) {
        final at = line.createdAt;
        if (at != null && at.isAfter(latest)) latest = at;
      }
      if (DateTime.now().difference(latest).inDays < 14) return true;
    }
    return false;
  }

  bool get canAddAnotherDog => isPremium || myDogs.isEmpty;

  bool addMyDog(MyDog d) {
    if (!canAddAnotherDog) {
      lastNotice = 'Gratis ger en hund. Premium kan lägga till fler.';
      notifyListeners();
      return false;
    }
    myDogs.add(d);
    _saveDogs();
    Network.upsertDog(email: email, owner: fullName, dog: d, lat: lat, lng: lng);
    applyFilters();
    return true;
  }

  void updateMyDog(int index, MyDog d) {
    if (index < 0 || index >= myDogs.length) return;
    final previous = myDogs[index].name;
    myDogs[index] = d;
    if (previous.toLowerCase() != d.name.toLowerCase()) {
      Network.deleteDog(email: email, name: previous);
    }
    _saveDogs();
    Network.upsertDog(email: email, owner: fullName, dog: d, lat: lat, lng: lng);
    applyFilters();
  }

  void removeMyDog(int index) {
    if (index < 0 || index >= myDogs.length) return;
    final name = myDogs[index].name;
    myDogs.removeAt(index);
    Network.deleteDog(email: email, name: name);
    _saveDogs();
    applyFilters();
  }

  void bump() {
    notifyListeners();
    _saveDeals();
  }

  Map<String, dynamic> _dealCache = {};

  void attachDeal(MatchThread t) {
    if (t.deal != null) return;
    final raw = _dealCache[t.cloudMatchId] ?? _dealCache[t.peerEmail.toLowerCase()];
    if (raw is Map) {
      t.deal = BreedingDeal.fromJson(Map<String, dynamic>.from(raw));
    }
  }

  Future<void> _saveDeals() async {
    final map = <String, dynamic>{};
    for (final m in matches) {
      final deal = m.deal;
      if (deal == null) continue;
      final payload = deal.toJson();
      if (m.cloudMatchId.isNotEmpty) map[m.cloudMatchId] = payload;
      if (m.peerEmail.contains('@')) map[m.peerEmail.toLowerCase()] = payload;
    }
    _dealCache = map;
    final p = await SharedPreferences.getInstance();
    await p.setString('pmDeals', jsonEncode(map));
  }

  BreedingDeal _dealForMe(Map<String, dynamic> raw) {
    final author = '${raw['author'] ?? ''}'.toLowerCase();
    if (!author.contains('@')) return BreedingDeal.fromJson(raw);
    final mine = author == email.toLowerCase() ? raw['signA'] : raw['signB'];
    final other = author == email.toLowerCase() ? raw['signB'] : raw['signA'];
    final view = Map<String, dynamic>.from(raw);
    view['me'] = mine is Map ? '${mine['name'] ?? ''}' : '';
    view['other'] = other is Map ? '${other['name'] ?? ''}' : '';
    view['sig'] = mine is Map ? mine['sig'] : const [];
    view['sigB'] = other is Map ? other['sig'] : const [];
    return BreedingDeal.fromJson(view);
  }

  void _takeCloudDeal(MatchThread t, Map<String, dynamic> row) {
    final json = row['dog_json'];
    if (json is! Map) return;
    if (json['dealGone'] == true) {
      t.deal = null;
      return;
    }
    if (json['deal'] is! Map) return;
    final next = _dealForMe(Map<String, dynamic>.from(json['deal'] as Map));
    final prev = t.deal;
    if (prev != null) {
      if (prev.signedByMe.isNotEmpty && next.signedByMe.isEmpty) {
        next.signedByMe = prev.signedByMe;
        next.signature = prev.signature;
      }
      if (prev.signedByOther.isNotEmpty && next.signedByOther.isEmpty) {
        next.signedByOther = prev.signedByOther;
        next.signatureOther = prev.signatureOther;
      }
      if (next.addrA.isEmpty && prev.addrA.isNotEmpty) next.addrA = prev.addrA;
      if (next.phoneA.isEmpty && prev.phoneA.isNotEmpty) next.phoneA = prev.phoneA;
      if (next.pnrA.isEmpty && prev.pnrA.isNotEmpty) next.pnrA = prev.pnrA;
      if (next.addrB.isEmpty && prev.addrB.isNotEmpty) next.addrB = prev.addrB;
      if (next.phoneB.isEmpty && prev.phoneB.isNotEmpty) next.phoneB = prev.phoneB;
      if (next.pnrB.isEmpty && prev.pnrB.isNotEmpty) next.pnrB = prev.pnrB;
    }
    t.deal = next;
  }

  Map<String, dynamic> _packSign(String name, List<List<SigPoint>> sig) => {
        'name': name,
        'sig': [
          for (final stroke in sig) [for (final p in stroke) [p.x, p.y]],
        ],
      };

  Map<String, dynamic> _sharedDeal(BreedingDeal d, Map<String, dynamic>? remote) {
    final prior = remote ?? {};
    final author = '${prior['author'] ?? ''}'.toLowerCase().contains('@') ? '${prior['author']}'.toLowerCase() : email.toLowerCase();
    final mine = _packSign(d.signedByMe, d.signature);
    final iAmA = author == email.toLowerCase();
    final signA = iAmA ? mine : (prior['signA'] is Map ? Map<String, dynamic>.from(prior['signA'] as Map) : {'name': '', 'sig': []});
    final signB = iAmA ? (prior['signB'] is Map ? Map<String, dynamic>.from(prior['signB'] as Map) : {'name': '', 'sig': []}) : mine;
    String keep(String local, String key) => local.trim().isNotEmpty ? local.trim() : '${prior[key] ?? ''}'.trim();
    return {
      'author': author,
      'price': d.pricePerPuppy,
      'pups': d.expectedPups,
      'place': d.place,
      'notes': d.notes,
      'a': d.partyA,
      'b': d.partyB,
      'body': d.body,
      'addrA': keep(d.addrA, 'addrA'),
      'phoneA': keep(d.phoneA, 'phoneA'),
      'pnrA': keep(d.pnrA, 'pnrA'),
      'addrB': keep(d.addrB, 'addrB'),
      'phoneB': keep(d.phoneB, 'phoneB'),
      'pnrB': keep(d.pnrB, 'pnrB'),
      'signA': signA,
      'signB': signB,
    };
  }

  Future<void> publishDeal(MatchThread t, {required bool tell}) async {
    final deal = t.deal;
    final peer = t.peerEmail.trim().toLowerCase();
    if (deal == null || !peer.contains('@') || !email.contains('@')) return;
    if (t.cloudMatchId.isEmpty) {
      final id = await Network.ensureMatch(a: email, b: peer, dogJson: await _pairJson(t.dog, peer));
      if (id == null || id.isEmpty) return;
      t.cloudMatchId = id;
    }
    final remote = await Network.matchDeal(t.cloudMatchId);
    await Network.saveDeal(t.cloudMatchId, _sharedDeal(deal, remote));
    await _saveDeals();
    if (!tell) return;
    final done = deal.fullySigned;
    await Network.ping(
      peer,
      done ? 'Avtalet är signerat' : 'Avtal att signera',
      done ? '$fullName har signerat. Avtalet är klart och kan laddas ner.' : '$fullName har signerat avelsavtalet. Öppna och signera.',
      kind: 'deal',
      peer: email,
    );
  }

  Future<void> deleteDeal(MatchThread t) async {
    final peer = t.peerEmail.trim().toLowerCase();
    final id = t.cloudMatchId;
    t.deal = null;
    notifyListeners();
    await _saveDeals();
    if (id.isNotEmpty) await Network.clearDeal(id);
    if (peer.contains('@') && peer != email.toLowerCase()) {
      await Network.ping(peer, 'Avtal raderat', '$fullName har raderat avelsavtalet.', kind: 'deal', peer: email);
    }
  }

  void markRead(MatchThread t) {
    t.unread = 0;
    _rememberRead(t.messages.map((m) => m.id));
    notifyListeners();
  }

  void _rememberRead(Iterable<String> ids) {
    var changed = false;
    for (final id in ids) {
      if (id.isEmpty) continue;
      if (_readMessageIds.add(id)) changed = true;
    }
    if (!changed) return;
    if (_readMessageIds.length > 4000) {
      final keep = _readMessageIds.toList().sublist(_readMessageIds.length - 4000);
      _readMessageIds
        ..clear()
        ..addAll(keep);
    }
    SharedPreferences.getInstance().then((p) => p.setStringList('readMessages', _readMessageIds.toList()));
  }

  bool wantsBreeding(DogProfile d) => d.intent == 'puppies' || d.availableForBreeding;

  bool canNegotiate(MatchThread t) => t.accepted && (wantsBreeding(t.dog) || myDogs.any((d) => d.availableForBreeding));

  double kmTo(DogProfile d) {
    const r = 6371.0;
    final p1 = lat * pi / 180;
    final p2 = d.lat * pi / 180;
    final dp = (d.lat - lat) * pi / 180;
    final dl = (d.lng - lng) * pi / 180;
    final a = sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  int score(DogProfile d) {
    var s = 0;
    final km = kmTo(d);
    final placed = d.lat.abs() > 0.01 || d.lng.abs() > 0.01;
    if (placed) {
      final span = radiusKm <= 0 ? 250.0 : radiusKm.toDouble();
      s += (30 * (1 - (km / span).clamp(0, 1))).round();
    } else {
      s += 8;
    }

    final friends = myDogs.isEmpty || myDogs.any((m) => m.availableForFriends);
    final breeding = myDogs.any((m) => m.availableForBreeding) || intentFilter == 'puppies';
    final dogFriends = d.intent != 'puppies' || d.availableForFriends;
    final dogBreeding = wantsBreeding(d);
    if (friends && dogFriends) s += 14;
    if (breeding && dogBreeding) s += 16;
    if (friends && !dogFriends && !breeding) s -= 8;

    final sameBreed = myDogs.any((m) => m.breed.trim().isNotEmpty && m.breed.toLowerCase() == d.breed.toLowerCase());
    if (sameBreed) {
      s += breeding && dogBreeding ? 20 : 12;
    } else if (_sameSize(d)) {
      s += 6;
    }

    if (myDogs.isNotEmpty && d.age > 0) {
      var best = 99;
      for (final m in myDogs) {
        final diff = (m.age - d.age).abs();
        if (diff < best) best = diff;
      }
      if (best <= 1) {
        s += 12;
      } else if (best <= 3) {
        s += 8;
      } else if (best <= 6) {
        s += 4;
      }
      if (d.age <= 1 && myDogs.any((m) => m.age <= 1)) s += 4;
    }

    if (breeding && dogBreeding && d.sex.isNotEmpty && myDogs.any((m) => m.sex.isNotEmpty)) {
      s += _opposite(d) ? 15 : -18;
    }
    if (breeding && dogBreeding && d.neutered) s -= 16;
    if (breeding && dogBreeding) s += d.vaccinated ? 4 : -4;

    if (d.weightKg > 0 && myDogs.any((m) => m.weightKg > 0)) {
      var closest = 999.0;
      for (final m in myDogs.where((m) => m.weightKg > 0)) {
        final gap = (m.weightKg - d.weightKg).abs() / m.weightKg;
        if (gap < closest) closest = gap;
      }
      if (closest <= 0.2) {
        s += 8;
      } else if (closest <= 0.5) {
        s += 4;
      }
    }

    var tags = 0;
    for (final tag in d.tags) {
      if (interests.contains(tag)) tags += 4;
    }
    if (tags > 12) tags = 12;
    s += tags;
    if (d.ownerVerified) s += 3;
    if (d.dogVerified) s += 3;
    return s;
  }

  bool _opposite(DogProfile d) {
    final sex = d.sex.toLowerCase();
    if (sex.isEmpty) return false;
    return myDogs.any((m) => m.sex.isNotEmpty && m.sex.toLowerCase() != sex);
  }

  bool _sameSize(DogProfile d) {
    final theirs = _size(d.breed, d.weightKg);
    if (theirs.isEmpty) return false;
    return myDogs.any((m) => _size(m.breed, m.weightKg) == theirs);
  }

  String _size(String breed, double kg) {
    final b = breed.toLowerCase();
    const groups = {
      'liten': ['chihuahua', 'pomeranian', 'yorkshire', 'maltes', 'papillon', 'dvärg', 'toy'],
      'mellan': ['tax', 'beagle', 'cocker', 'fransk', 'mops', 'shih', 'cavalier', 'russell', 'schnauzer', 'staff', 'bulldog', 'whippet', 'sheltie'],
      'stor': ['labrador', 'golden', 'schäfer', 'schafer', 'rottweil', 'boxer', 'dobermann', 'husky', 'collie', 'tollare', 'springer'],
      'mycket stor': ['grand danois', 'bernhard', 'newfoundland', 'mastiff', 'leonberg', 'dogge'],
    };
    for (final entry in groups.entries) {
      if (entry.value.any(b.contains)) return entry.key;
    }
    if (kg <= 0) return '';
    if (kg < 10) return 'liten';
    if (kg < 22) return 'mellan';
    if (kg < 40) return 'stor';
    return 'mycket stor';
  }

  String matchReason(DogProfile d) {
    final bits = <String>[];
    final placed = d.lat.abs() > 0.01 || d.lng.abs() > 0.01;
    final km = kmTo(d);
    if (placed && km < 15) bits.add('Nära dig');
    final sameBreed = myDogs.any((m) => m.breed.trim().isNotEmpty && m.breed.toLowerCase() == d.breed.toLowerCase());
    if (sameBreed) bits.add('Samma ras');
    else if (_sameSize(d)) bits.add('Liknande storlek');
    final breeding = myDogs.any((m) => m.availableForBreeding) || intentFilter == 'puppies';
    if (breeding && wantsBreeding(d) && _opposite(d) && !d.neutered) bits.add('Passar för avel');
    else if (d.intent != 'puppies' || d.availableForFriends) bits.add('Hundvän');
    if (myDogs.isNotEmpty && d.age > 0 && myDogs.any((m) => (m.age - d.age).abs() <= 2)) bits.add('Samma ålder');
    if (d.dogVerified || d.ownerVerified) bits.add('Verifierad');
    if (bits.isEmpty) return 'Förslag för dig';
    return bits.take(2).join(' · ');
  }

  void _rank(List<DogProfile> list) {
    if (feedSort == 'nearest') {
      list.sort((a, b) => kmTo(a).compareTo(kmTo(b)));
      return;
    }
    list.sort((a, b) {
      final byScore = score(b).compareTo(score(a));
      if (byScore != 0) return byScore;
      return kmTo(a).compareTo(kmTo(b));
    });
    if (feedSort == 'forYou') _liftNearbyPremium(list);
  }

  void _liftNearbyPremium(List<DogProfile> list) {
    const nearKm = 40.0;
    final top = <DogProfile>[];
    final rest = <DogProfile>[];
    for (final d in list) {
      if (d.ownerPremium && kmTo(d) <= nearKm) {
        top.add(d);
      } else {
        rest.add(d);
      }
    }
    list
      ..clear()
      ..addAll(top)
      ..addAll(rest);
  }

  bool _isHidden(DogProfile d) {
    final until = hiddenUntil[d.id];
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      hiddenUntil.remove(d.id);
      matches.removeWhere((m) => m.dog.id == d.id && !m.accepted);
      return false;
    }
    return true;
  }

  List<DogProfile> get forYou {
    final list = filtered.toList();
    _rank(list);
    return list;
  }

  Iterable<DogProfile> get filtered sync* {
    final want = intentFilter == 'puppies' ? oppositeSex : '';
    for (final d in _pool) {
      if (blocked.contains(d.id)) continue;
      if (d.ownerEmail.isNotEmpty && blockedOwners.contains(d.ownerEmail.toLowerCase())) continue;
      if (_isHidden(d)) continue;
      if (_keptMatch(d)) continue;
      if (want.isNotEmpty && d.sex.isNotEmpty && d.sex.toLowerCase() != want) continue;
      if (intentFilter == 'puppies' && d.neutered) continue;
      if (d.age < ageMin || d.age > ageMax) continue;
      if (breedQuery.isNotEmpty && !d.breed.toLowerCase().contains(breedQuery.toLowerCase())) continue;
      if (area.isNotEmpty && !d.city.toLowerCase().contains(area.toLowerCase())) continue;
      if (intentFilter != 'all' && d.intent != intentFilter) continue;
      if (isPremium && premiumIntent == 'puppies' && d.intent != 'puppies') continue;
      if (isPremium && premiumIntent == 'friends' && d.intent == 'puppies') continue;
      if (isPremium && sizeFilter != 'all' && d.sizeBand.isNotEmpty && d.sizeBand != sizeFilter) continue;
      if (kmTo(d) > radiusKm) continue;
      yield d;
    }
  }

  void applyFilters() {
    deck = filtered.toList();
    _rank(deck);
    notifyListeners();
  }

  void setFeedSort(String v) {
    feedSort = v;
    intentFilter = (v == 'friends' || v == 'puppies') ? v : 'all';
    applyFilters();
  }

  bool swipe(DogProfile d, {required bool like}) {
    _rollSwipes();
    if (!isPremium && swipesToday >= freeSwipesPerDay) {
      lastNotice = 'Dagens swipes är slut. Premium ger obegränsat.';
      notifyListeners();
      return false;
    }
    swipesToday += 1;
    hiddenUntil[d.id] = DateTime.now().add(const Duration(days: 7));
    _storeHidden();
    deck.removeWhere((x) => x.id == d.id);
    if (!like) {
      lastPassed = d;
    } else if (lastPassed?.id == d.id) {
      lastPassed = null;
    }
    if (like) {
      final thread = MatchThread(d, [], accepted: false, outgoing: true, peerEmail: d.ownerEmail);
      matches.insert(0, thread);
      lastNotice = 'Förfrågan skickad till ${d.owner} som äger ${d.name}.';
      _cloudLike(thread, d);
    }
    notifyListeners();
    return true;
  }

  void openFromNotice(Map<String, String> data) {
    var kind = (data['kind'] ?? '').trim();
    var peer = (data['peer'] ?? '').trim().toLowerCase();
    var group = (data['group'] ?? '').trim();
    final route = (data['payload'] ?? '').split('|');
    if (kind.isEmpty && route.isNotEmpty) kind = route.first.trim();
    if (peer.isEmpty && route.length > 1) peer = route[1].trim().toLowerCase();
    if (group.isEmpty && route.length > 2) group = route[2].trim();
    if (kind.isEmpty) kind = group.isNotEmpty ? 'group' : 'chat';
    final key = '$kind|$peer|$group';
    final now = DateTime.now();
    if (key == _lastNoticeKey && _lastNoticeAt != null && now.difference(_lastNoticeAt!) < const Duration(seconds: 2)) return;
    _lastNoticeKey = key;
    _lastNoticeAt = now;
    pendingKind = kind;
    pendingPeer = peer;
    pendingGroup = group;
    notifyListeners();
  }

  void clearNotice() {
    pendingKind = null;
    pendingPeer = null;
    pendingGroup = null;
  }

  bool undoPass() {
    final d = lastPassed;
    if (!isPremium || d == null) return false;
    lastPassed = null;
    hiddenUntil.remove(d.id);
    _storeHidden();
    if (swipesToday > 0) swipesToday -= 1;
    deck.removeWhere((x) => x.id == d.id);
    deck.insert(0, d);
    lastNotice = '${d.name} är tillbaka.';
    notifyListeners();
    return true;
  }

  Future<void> _openCloud(MatchThread thread, DogProfile d, String peer) async {
    final id = await Network.ensureMatch(a: email, b: peer, dogJson: await _pairJson(d, peer));
    if (id == null || id.isEmpty) return;
    thread.cloudMatchId = id;
    thread.accepted = true;
    final existing = await Network.messages(id, email);
    if (existing != null && existing.isEmpty) {
      await Network.sendMessage(id, email, 'Ni matchade — nu kan ni chatta.');
    }
    await refreshChat(thread);
  }

  Future<void> _cloudLike(MatchThread thread, DogProfile d) async {
    final peer = d.ownerEmail;
    if (!email.contains('@') || !peer.contains('@')) return;
    final mutual = await Network.like(fromEmail: email, toEmail: peer, dogId: d.id);
    await Network.ping(
      peer,
      mutual ? 'Ny matchning' : 'Någon vill matcha',
      mutual ? 'Ni matchade. Öppna chatten.' : '$fullName vill matcha med ${d.name}.',
      kind: mutual ? 'matched' : 'match',
      peer: email,
    );
    if (!mutual) return;
    await _openCloud(thread, d, peer);
    lastNotice = '${d.owner} matchade också!';
    celebrate = d.name;
    notifyListeners();
  }

  void simulateAccept(MatchThread t) {
    t.accepted = true;
    t.unread += 1;
    lastNotice = '${t.dog.owner} godkände matchningen';
    notifyListeners();
  }

  void acceptIncoming(MatchThread t) {
    final peer = t.peerEmail.toLowerCase();
    t.accepted = true;
    t.unread = 0;
    if (peer.isNotEmpty) handledPeers.add(peer);
    incoming.removeWhere((m) => m.peerEmail.toLowerCase() == peer);
    if (!matches.any((m) => m.dog.id == t.dog.id && m.accepted)) {
      matches.insert(0, t);
    }
    celebrate = t.dog.name;
    notifyListeners();
    if (!peer.contains('@')) return;
    Network.forgetLike(fromEmail: peer, toEmail: email);
    Network.like(fromEmail: email, toEmail: peer, dogId: t.dog.id).then((_) async {
      await Network.ping(peer, 'Ny matchning', '$fullName godkände matchningen. Öppna chatten.', kind: 'matched', peer: email);
      final id = await Network.ensureMatch(a: email, b: peer, dogJson: await _pairJson(t.dog, peer));
      if (id == null || id.isEmpty) return;
      await Network.unhideMatch(id, email);
      t.cloudMatchId = id;
      t.accepted = true;
      final existing = await Network.messages(id, email);
      if (existing != null && existing.isEmpty) {
        await Network.sendMessage(id, email, 'Ni matchade — nu kan ni chatta.');
      }
      await refreshChat(t);
    });
  }

  void declineIncoming(MatchThread t) {
    final peer = t.peerEmail.toLowerCase();
    if (peer.isNotEmpty) handledPeers.add(peer);
    incoming.removeWhere((m) => m.peerEmail.toLowerCase() == peer);
    hiddenUntil[t.dog.id] = DateTime.now().add(const Duration(days: 7));
    _storeHidden();
    notifyListeners();
    if (peer.contains('@')) Network.forgetLike(fromEmail: peer, toEmail: email);
  }

  bool saveDog(DogProfile d) {
    if (saved.any((x) => x.id == d.id)) {
      saved.removeWhere((x) => x.id == d.id);
      notifyListeners();
      return true;
    }
    if (!isPremium && saved.length >= 5) {
      lastNotice = 'Gratis kan spara 5 hundar. Premium sparar obegränsat.';
      notifyListeners();
      return false;
    }
    saved.insert(0, d);
    notifyListeners();
    return true;
  }

  bool isSaved(DogProfile d) => saved.any((x) => x.id == d.id);

  Future<void> send(MatchThread t, String text) async {
    final body = text.trim();
    if (!t.accepted || body.isEmpty) return;
    t.messages.add(ChatLine(true, body, createdAt: DateTime.now()));
    notifyListeners();
    if (t.cloudMatchId.isEmpty && t.peerEmail.contains('@')) {
      await _openCloud(t, t.dog, t.peerEmail);
    }
    if (t.cloudMatchId.isEmpty) return;
    await Network.sendMessage(t.cloudMatchId, email, body);
    if (t.peerEmail.contains('@') && t.peerEmail.toLowerCase() != email.toLowerCase()) {
      final who = fullName.trim().isEmpty ? 'Någon' : fullName.trim();
      await Network.pingChat(t.peerEmail, email, '$who: ${chatPreview(body)}', peer: email);
    }
    await refreshChat(t);
  }

  Future<bool> sendPhotos(MatchThread t, List<String> paths) async {
    if (!t.accepted) return false;
    final urls = <String>[];
    for (final path in paths.take(5)) {
      if (path.isEmpty) continue;
      final url = await Network.uploadChatPhoto(path);
      if (url != null && url.startsWith('http')) urls.add(url);
    }
    if (urls.isEmpty) return false;
    await send(t, '$chatPhotoMark${urls.join('||')}');
    return true;
  }

  Future<void> pullGroups() async {
    if (!email.contains('@')) return;
    final rows = await Network.myGroups(email);
    if (rows == null) return;
    final me = email.toLowerCase();
    final keep = <String>{};
    for (final r in rows) {
      final id = '${r['id']}';
      keep.add(id);
      final members = <GroupMember>[
        for (final m in List.from(r['members'] ?? const []))
          if ('${m['email'] ?? ''}'.contains('@'))
            GroupMember(
              '${m['email']}'.toLowerCase(),
              () {
                final raw = m['display_name'];
                final text = raw == null ? '' : '$raw'.trim();
                return text.isEmpty ? '${m['email']}' : text;
              }(),
            ),
      ];
      GroupChat? group;
      for (final g in groups) {
        if (g.id == id) {
          group = g;
          break;
        }
      }
      if (group == null) {
        group = GroupChat(
          id: id,
          name: '${r['name'] ?? 'Grupp'}',
          ownerEmail: '${r['owner_email']}'.toLowerCase(),
          members: members,
        );
        groups.insert(0, group);
      } else {
        group.name = '${r['name'] ?? group.name}';
        group.members
          ..clear()
          ..addAll(members);
      }
      if (!members.any((m) => m.email == me)) continue;
      await refreshGroup(group, countUnread: true);
    }
    groups.removeWhere((g) => !keep.contains(g.id) || !g.members.any((m) => m.email == me));
    groupsReady = true;
    notifyListeners();
  }

  Future<void> refreshGroup(GroupChat g, {bool countUnread = false}) async {
    final names = {for (final m in g.members) m.email: m.name};
    final lines = await Network.groupMessages(g.id, email, names);
    if (lines == null) return;
    final prev = g.messages.map((m) => m.id).toSet();
    final pending = g.messages.where((m) => m.id.isEmpty && m.fromMe).toList();
    if (countUnread) {
      final fresh = lines.where((m) => !m.fromMe && m.id.isNotEmpty && !prev.contains(m.id) && !m.recalled).length;
      if (fresh > 0 && prev.isNotEmpty) {
        g.unread += fresh;
        if (notifyOn) PushService.notifyGroup(g.name);
      }
    }
    g.messages
      ..clear()
      ..addAll(lines);
    for (final p in pending) {
      if (!lines.any((m) => m.fromMe && m.text == p.text)) g.messages.add(p);
    }
    notifyListeners();
  }

  void markGroupRead(GroupChat g) {
    g.unread = 0;
    notifyListeners();
  }

  List<GroupMember> get chatPartners {
    final seen = <String>{};
    final out = <GroupMember>[];
    for (final m in matches) {
      if (!m.accepted || !m.peerEmail.contains('@')) continue;
      final mail = m.peerEmail.toLowerCase();
      if (!seen.add(mail)) continue;
      final owner = m.dog.owner.trim();
      final name = owner.isNotEmpty && !owner.contains('@')
          ? owner
          : (m.dog.name.trim().isEmpty ? mail : m.dog.name.trim());
      out.add(GroupMember(mail, name));
    }
    return out;
  }

  Future<bool> createGroup(String name, List<GroupMember> people) async {
    if (!isPremium || !email.contains('@')) return false;
    final title = name.trim();
    if (title.isEmpty || people.length < 2) return false;
    final id = await Network.createGroup(name: title, ownerEmail: email, ownerName: fullName, members: people);
    if (id == null) return false;
    for (final person in people) {
      await Network.ping(person.email, 'Grupp', '$fullName bjöd in dig till gruppen $title.', kind: 'group', peer: email, group: id);
    }
    await pullGroups();
    return true;
  }

  Future<void> sendGroup(GroupChat g, String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    if (!g.members.any((m) => m.email == email.toLowerCase())) return;
    g.messages.add(ChatLine(true, body, senderName: fullName));
    notifyListeners();
    await Network.sendGroupMessage(g.id, email, body);
    final who = fullName.trim().isEmpty ? 'Någon' : fullName.trim();
    for (final m in g.members) {
      if (m.email == email.toLowerCase()) continue;
      await Network.ping(m.email, 'Grupp', '$who i ${g.name}: ${chatPreview(body)}', kind: 'group', peer: email, group: g.id);
    }
    await refreshGroup(g);
  }

  Future<bool> sendGroupPhotos(GroupChat g, List<String> paths) async {
    final urls = <String>[];
    for (final path in paths.take(5)) {
      if (path.isEmpty) continue;
      final url = await Network.uploadChatPhoto(path);
      if (url != null && url.startsWith('http')) urls.add(url);
    }
    if (urls.isEmpty) return false;
    await sendGroup(g, '$chatPhotoMark${urls.join('||')}');
    return true;
  }

  Future<void> addGroupMember(GroupChat g, GroupMember member) async {
    if (g.ownerEmail != email.toLowerCase()) return;
    if (g.members.any((m) => m.email == member.email.toLowerCase())) return;
    await Network.addGroupMember(g.id, member);
    await Network.sendGroupMessage(g.id, email, '${member.name} lades till i gruppen.');
    await Network.ping(member.email, 'Grupp', '$fullName bjöd in dig till gruppen ${g.name}.', kind: 'group', peer: email, group: g.id);
    await pullGroups();
  }

  Future<void> removeGroupMember(GroupChat g, GroupMember member) async {
    if (g.ownerEmail != email.toLowerCase()) return;
    if (member.email == g.ownerEmail) return;
    await Network.removeGroupMember(g.id, member.email);
    await Network.sendGroupMessage(g.id, email, '${member.name} togs bort från gruppen.');
    await pullGroups();
  }

  Future<void> deleteGroup(GroupChat g) async {
    if (g.ownerEmail != email.toLowerCase()) return;
    groups.remove(g);
    notifyListeners();
    await Network.deleteGroup(g.id);
  }

  void _armPush() {
    if (!email.contains('@')) return;
    Fcm.onToken = (token) {
      Network.saveDevice(email, token);
    };
    Fcm.flush();
  }

  Future<void> blockPeer(DogProfile d) async {
    blocked.add(d.id);
    final owner = d.ownerEmail.toLowerCase();
    if (owner.contains('@')) blockedOwners.add(owner);
    bool same(MatchThread m) => m.dog.id == d.id || (owner.contains('@') && m.peerEmail.toLowerCase() == owner);
    matches.removeWhere(same);
    incoming.removeWhere(same);
    saved.removeWhere((m) => m.id == d.id || (owner.contains('@') && m.ownerEmail.toLowerCase() == owner));
    deck.removeWhere((m) => m.id == d.id || (owner.contains('@') && m.ownerEmail.toLowerCase() == owner));
    lastNotice = 'Personen är blockerad och syns inte igen.';
    applyFilters();
    final p = await SharedPreferences.getInstance();
    await p.setStringList('blockedDogs', blocked.toList());
    await p.setStringList('blockedOwners', blockedOwners.toList());
  }

  void block(DogProfile d) {
    blockPeer(d);
  }
}
