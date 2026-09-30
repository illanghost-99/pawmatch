import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
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
  final List<MatchThread> incoming = [];
  final List<DogProfile> saved = [];
  final Set<String> blocked = {};
  final Map<String, DateTime> hiddenUntil = {};
  final List<MyDog> myDogs = [];
  String lastNotice = '';
  Timer? _inbox;
  final Set<String> _seenLikes = {};

  static const freeSwipesPerDay = 12;

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

  int get chatBadge => incoming.length + matches.where((m) => m.unread > 0).length;

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
    if (signedIn) {
      PushService.init();
      _armPush();
      locate();
      syncCloud();
      _watchInbox();
    }
    notifyListeners();
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

  Future<void> syncCloud() async {
    if (!email.contains('@')) return;
    liveDogs = await Network.liveDogs(email);
    for (final d in myDogs) {
      await Network.upsertDog(email: email, owner: fullName, dog: d, lat: lat, lng: lng);
    }
    applyFilters();
    await pullInbox();
    await pullChats();
    notifyListeners();
  }

  void _watchInbox() {
    _inbox?.cancel();
    _inbox = Timer.periodic(const Duration(seconds: 6), (_) async {
      await pullInbox();
      await pullChats();
    });
    pullInbox();
    pullChats();
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
      final hidden = <String>[
        for (final h in List.from(r['hidden_by'] ?? const [])) h.toString().toLowerCase(),
      ];
      if (hidden.contains(me)) {
        matches.removeWhere((m) => m.cloudMatchId == id);
        continue;
      }
      final a = (r['user_a'] as String? ?? '').toLowerCase();
      final b = (r['user_b'] as String? ?? '').toLowerCase();
      final peer = a == me ? b : a;
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
        PushService.notifyMatch(dog.name);
        lastNotice = '${dog.owner} vill matcha med dig';
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> refreshChat(MatchThread t, {bool countUnread = false}) async {
    if (t.cloudMatchId.isEmpty) return;
    final lines = await Network.messages(t.cloudMatchId, email);
    if (lines == null) return;
    final prev = t.messages.map((m) => m.id).toSet();
    final pending = t.messages.where((m) => m.id.isEmpty && m.fromMe).toList();
    if (countUnread) {
      final fresh = lines.where((m) => !m.fromMe && m.id.isNotEmpty && !prev.contains(m.id) && !m.recalled).length;
      if (fresh > 0 && prev.isNotEmpty) {
        final who = t.dog.owner.trim().isEmpty ? 'Någon' : t.dog.owner.trim();
        PushService.notifyMessage(who);
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

  void saveProfile({
    required String first,
    required String last,
    required String bio,
    required String city,
    required String photo,
  }) {
    firstName = first;
    lastName = last;
    ownerBio = bio;
    locationLabel = city.isEmpty ? locationLabel : city;
    photoUrl = photo;
    displayName = fullName;
    persist();
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
    PushService.notifyLive(d.name);
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
    for (final tag in d.tags) {
      if (interests.contains(tag)) s += 3;
    }
    final km = kmTo(d);
    if (km < 20) {
      s += 4;
    } else if (km < 50) {
      s += 2;
    }
    return s;
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
    if (feedSort == 'nearest') {
      list.sort((a, b) => kmTo(a).compareTo(kmTo(b)));
    } else if (feedSort == 'friends') {
      list.sort((a, b) => (a.intent == 'friends' ? 0 : 1).compareTo(b.intent == 'friends' ? 0 : 1));
    } else if (feedSort == 'puppies') {
      list.sort((a, b) => (a.intent == 'puppies' ? 0 : 1).compareTo(b.intent == 'puppies' ? 0 : 1));
    } else {
      list.sort((a, b) => score(b).compareTo(score(a)));
    }
    return list;
  }

  Iterable<DogProfile> get filtered sync* {
    final want = oppositeSex;
    for (final d in _pool) {
      if (blocked.contains(d.id)) continue;
      if (_isHidden(d)) continue;
      if (want.isNotEmpty && d.sex.isNotEmpty && d.sex.toLowerCase() != want) continue;
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
    if (feedSort == 'nearest') {
      deck.sort((a, b) => kmTo(a).compareTo(kmTo(b)));
    }
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
    PushService.notifyMatch(d.name);
    notifyListeners();
  }

  void simulateAccept(MatchThread t) {
    t.accepted = true;
    t.unread += 1;
    lastNotice = '${t.dog.owner} godkände matchningen';
    notifyListeners();
  }

  void acceptIncoming(MatchThread t) {
    t.accepted = true;
    t.unread = 0;
    if (!matches.any((m) => m.dog.id == t.dog.id && m.accepted)) {
      matches.insert(0, t);
    }
    incoming.remove(t);
    PushService.notifyMatch(t.dog.name);
    if (t.peerEmail.contains('@')) {
      Network.like(fromEmail: email, toEmail: t.peerEmail, dogId: t.dog.id).then((_) async {
        await Network.ping(t.peerEmail, 'Ny match', '$fullName godkände matchningen.');
        await _openCloud(t, t.dog, t.peerEmail);
      });
    }
    notifyListeners();
  }

  void declineIncoming(MatchThread t) {
    incoming.remove(t);
    hiddenUntil[t.dog.id] = DateTime.now().add(const Duration(days: 7));
    notifyListeners();
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
    t.messages.add(ChatLine(true, body));
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
