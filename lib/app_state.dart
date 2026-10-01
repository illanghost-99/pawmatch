import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/sample_dogs.dart';
import 'models.dart';
import 'services/location.dart';
import 'services/network.dart';
import 'services/fcm.dart';
import 'services/push.dart';
import 'services/session.dart';
import 'v2/circle_models.dart';

class AppState extends ChangeNotifier {
  UserRole role = UserRole.owner;
  final Set<String> interests = {};
  bool onboarded = false;
  bool signedIn = false;
  bool sessionReady = false;
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
  String feedSort = 'forYou';
  List<DogProfile> liveDogs = [];
  List<DogProfile> deck = List.of(sampleDogs);
  final List<MatchThread> matches = [];
  final List<GroupChat> groups = [];
  final List<MatchThread> incoming = [];
  final Set<String> handledPeers = {};
  final List<DogProfile> saved = [];
  final Set<String> blocked = {};
  final Map<String, DateTime> hiddenUntil = {};
  final List<MyDog> myDogs = [];
  String lastNotice = '';
  String celebrate = '';
  Timer? _inbox;
  final Set<String> _seenLikes = {};

  static const freeSwipesPerDay = 12;

  bool darkMode = false;
  bool discoverable = true;
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

  int get chatBadge => incoming.length + matches.where((m) => m.unread > 0).length + groups.where((g) => g.unread > 0).length;

  List<MatchThread> get deals => matches.where((m) => m.deal != null).toList();

  List<DogProfile> get _pool => liveDogs.isEmpty ? sampleDogs : [...liveDogs, ...sampleDogs];

  Future<void> restore() async {
    final s = await Session.read();
    email = s['email'] ?? '';
    firstName = s['firstName'] ?? '';
    lastName = s['lastName'] ?? '';
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
  }

  Future<void> setDarkMode(bool on) async {
    darkMode = on;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('darkMode', on);
  }

  Future<void> setDiscoverable(bool on) async {
    discoverable = on;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool('discoverable', on);
    await Network.setVisible(email, on);
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

  Map<String, dynamic> _dogJson(DogProfile d, String peer) => {
        'name': d.name,
        'breed': d.breed,
        'owner': d.owner,
        'id': d.id,
        'owner_email': peer,
        'from_name': fullName,
        'from_email': email.toLowerCase(),
        'from_dog': myDogs.isEmpty ? fullName : myDogs.first.name,
      };

  DogProfile _dogFromMatch(Map<String, dynamic> r, String peer) {
    for (final d in liveDogs) {
      if (d.ownerEmail.toLowerCase() == peer) return d;
    }
    final json = Map<String, dynamic>.from(r['dog_json'] ?? {});
    final me = email.toLowerCase();
    final ownerEmail = (json['owner_email'] as String? ?? '').toLowerCase();
    final mine = ownerEmail == me;
    return DogProfile(
      id: (json['id'] as String?) ?? 'match-$peer',
      name: mine ? (json['from_dog'] as String? ?? json['from_name'] as String? ?? 'Match') : (json['name'] as String? ?? 'Hund'),
      breed: mine ? '' : (json['breed'] as String? ?? ''),
      age: 1,
      city: '',
      lat: lat,
      lng: lng,
      bio: '',
      owner: mine ? (json['from_name'] as String? ?? peer) : (json['owner'] as String? ?? peer),
      tags: const [],
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
      }
      incoming.removeWhere((m) => m.peerEmail.toLowerCase() == peer);
      await refreshChat(thread, countUnread: true);
    }
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
      if (_seenLikes.add(from)) {
        if (notifyOn) PushService.notifyMatch(dog.name);
        lastNotice = '${dog.owner} vill matcha med dig';
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> refreshChat(MatchThread t, {bool countUnread = false, bool markSeen = false}) async {
    if (t.cloudMatchId.isEmpty) return;
    if (markSeen) await Network.markSeen(t.cloudMatchId, email);
    final lines = await Network.messages(t.cloudMatchId, email);
    if (lines == null) return;
    final prev = t.messages.map((m) => m.id).toSet();
    final pending = t.messages.where((m) => m.id.isEmpty && m.fromMe).toList();
    if (countUnread) {
      final fresh = lines.where((m) => !m.fromMe && m.id.isNotEmpty && !prev.contains(m.id) && !m.recalled).length;
      if (fresh > 0 && prev.isNotEmpty) {
        final who = t.dog.owner.trim().isEmpty ? 'Någon' : t.dog.owner.trim();
        if (notifyOn) PushService.notifyMessage(who);
      }
      t.unread += fresh;
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

  void signIn(String e) {
    email = e;
    signedIn = true;
    PushService.init();
    _armPush();
    persist();
    locate();
    syncCloud();
    _watchInbox();
    notifyListeners();
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
    signedIn = false;
    persist();
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

  void addMyDog(MyDog d) {
    myDogs.add(d);
    if (notifyOn) PushService.notifyLive(d.name);
    Network.upsertDog(email: email, owner: fullName, dog: d, lat: lat, lng: lng);
    applyFilters();
  }

  void updateMyDog(int index, MyDog d) {
    if (index < 0 || index >= myDogs.length) return;
    myDogs[index] = d;
    Network.upsertDog(email: email, owner: fullName, dog: d, lat: lat, lng: lng);
    applyFilters();
  }

  void removeMyDog(int index) {
    if (index < 0 || index >= myDogs.length) return;
    myDogs.removeAt(index);
    applyFilters();
  }

  void bump() => notifyListeners();

  void markRead(MatchThread t) {
    t.unread = 0;
    notifyListeners();
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
      if (_isHidden(d)) continue;
      if (want.isNotEmpty && d.sex.isNotEmpty && d.sex.toLowerCase() != want) continue;
      if (intentFilter == 'puppies' && d.neutered) continue;
      if (d.age < ageMin || d.age > ageMax) continue;
      if (breedQuery.isNotEmpty && !d.breed.toLowerCase().contains(breedQuery.toLowerCase())) continue;
      if (area.isNotEmpty && !d.city.toLowerCase().contains(area.toLowerCase())) continue;
      if (intentFilter != 'all' && d.intent != intentFilter) continue;
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
    deck.removeWhere((x) => x.id == d.id);
    if (like) {
      final thread = MatchThread(d, [], accepted: false, outgoing: true, peerEmail: d.ownerEmail);
      matches.insert(0, thread);
      lastNotice = 'Förfrågan skickad till ${d.owner} som äger ${d.name}.';
      _cloudLike(thread, d);
    }
    notifyListeners();
    return true;
  }

  Future<void> _openCloud(MatchThread thread, DogProfile d, String peer) async {
    final id = await Network.ensureMatch(a: email, b: peer, dogJson: _dogJson(d, peer));
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
      mutual ? 'Ny match' : 'Någon gillar din hund',
      mutual ? 'Ni matchade. Öppna chatten i PawMatch.' : '$fullName vill matcha med ${d.name}.',
    );
    if (!mutual) return;
    await _openCloud(thread, d, peer);
    lastNotice = '${d.owner} matchade också!';
    celebrate = d.name;
    if (notifyOn) PushService.notifyMatch(d.name);
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
    if (notifyOn) PushService.notifyMatch(t.dog.name);
    celebrate = t.dog.name;
    notifyListeners();
    if (!peer.contains('@')) return;
    Network.forgetLike(fromEmail: peer, toEmail: email);
    Network.like(fromEmail: email, toEmail: peer, dogId: t.dog.id).then((_) async {
      await Network.ping(peer, 'Ny match', '$fullName godkände matchningen.');
      final id = await Network.ensureMatch(a: email, b: peer, dogJson: _dogJson(t.dog, peer));
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
    notifyListeners();
    if (peer.contains('@')) Network.forgetLike(fromEmail: peer, toEmail: email);
  }

  void saveDog(DogProfile d) {
    if (saved.any((x) => x.id == d.id)) {
      saved.removeWhere((x) => x.id == d.id);
    } else {
      saved.insert(0, d);
    }
    notifyListeners();
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
    if (t.peerEmail.contains('@')) {
      final who = fullName.trim().isEmpty ? 'Någon' : fullName.trim();
      await Network.ping(t.peerEmail, 'Nytt meddelande', '$who: $body');
    }
    await refreshChat(t);
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
        if (notifyOn) PushService.notifyMessage(g.name);
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
      await Network.ping(person.email, title, '$fullName bjöd in dig till gruppen.');
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
      await Network.ping(m.email, g.name, '$who: $body');
    }
    await refreshGroup(g);
  }

  Future<void> addGroupMember(GroupChat g, GroupMember member) async {
    if (g.ownerEmail != email.toLowerCase()) return;
    if (g.members.any((m) => m.email == member.email.toLowerCase())) return;
    await Network.addGroupMember(g.id, member);
    await Network.sendGroupMessage(g.id, email, '${member.name} lades till i gruppen.');
    await Network.ping(member.email, g.name, '$fullName bjöd in dig till gruppen.');
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

  void block(DogProfile d) {
    blocked.add(d.id);
    matches.removeWhere((m) => m.dog.id == d.id);
    incoming.removeWhere((m) => m.dog.id == d.id);
    saved.removeWhere((m) => m.id == d.id);
    applyFilters();
  }
}
