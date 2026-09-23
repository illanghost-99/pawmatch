import 'dart:math';
import 'package:flutter/foundation.dart';
import 'data/sample_dogs.dart';
import 'models.dart';
import 'services/push.dart';

class AppState extends ChangeNotifier {
  UserRole role = UserRole.owner;
  final Set<String> interests = {};
  bool onboarded = false;
  bool signedIn = false;
  String email = '';
  String displayName = 'Max';
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
  List<DogProfile> deck = List.of(sampleDogs);
  final List<MatchThread> matches = [];
  final List<MatchThread> incoming = [];
  final List<DogProfile> saved = [];
  final Set<String> blocked = {};
  final Map<String, DateTime> hiddenUntil = {};
  final List<MyDog> myDogs = [];
  String lastNotice = '';

  void signIn(String e) {
    email = e;
    signedIn = true;
    PushService.init();
    notifyListeners();
  }

  void signOut() {
    signedIn = false;
    email = '';
    notifyListeners();
  }

  void toggleInterest(String id) {
    if (!interests.add(id)) interests.remove(id);
    notifyListeners();
  }

  void finishOnboarding() {
    onboarded = true;
    if (incoming.isEmpty && sampleDogs.isNotEmpty) {
      incoming.add(MatchThread(sampleDogs.first, [const ChatLine(false, 'Hej! Vi söker en lekkompis.')], accepted: false, outgoing: false));
    }
    applyFilters();
    notifyListeners();
  }

  void addMyDog(MyDog d) {
    myDogs.add(d);
    PushService.notifyLive(d.name);
    notifyListeners();
  }

  void updateMyDog(int index, MyDog d) {
    if (index < 0 || index >= myDogs.length) return;
    myDogs[index] = d;
    notifyListeners();
  }

  void removeMyDog(int index) {
    if (index < 0 || index >= myDogs.length) return;
    myDogs.removeAt(index);
    notifyListeners();
  }

  void bump() => notifyListeners();

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
    for (final t in d.tags) {
      if (interests.contains(t)) s += 3;
    }
    final km = kmTo(d);
    if (km < 20) s += 4;
    if (km < 50) s += 2;
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
    for (final d in sampleDogs) {
      if (blocked.contains(d.id)) continue;
      if (_isHidden(d)) continue;
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
    notifyListeners();
  }

  void setFeedSort(String v) {
    feedSort = v;
    intentFilter = (v == 'friends' || v == 'puppies') ? v : 'all';
    applyFilters();
  }

  void swipe(DogProfile d, {required bool like}) {
    hiddenUntil[d.id] = DateTime.now().add(const Duration(days: 7));
    deck.removeWhere((x) => x.id == d.id);
    if (like) {
      matches.insert(0, MatchThread(d, [], accepted: false, outgoing: true));
      lastNotice = 'Förfrågan skickad till ${d.owner} som äger ${d.name}. Chatt öppnas när de godkänner — annars syns hunden igen om 7 dagar.';
      PushService.notifyMatch(d.name);
    } else {
      lastNotice = '';
    }
    notifyListeners();
  }

  void simulateAccept(MatchThread t) {
    t.accepted = true;
    t.messages.add(const ChatLine(false, 'Matchningen är godkänd — nu kan ni chatta.'));
    notifyListeners();
  }

  void acceptIncoming(MatchThread t) {
    t.accepted = true;
    t.messages.add(const ChatLine(false, 'Matchningen är godkänd — nu kan ni chatta.'));
    if (!matches.any((m) => m.dog.id == t.dog.id && m.accepted)) {
      matches.insert(0, t);
    }
    incoming.remove(t);
    PushService.notifyMatch(t.dog.name);
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

  void send(MatchThread t, String text) {
    if (!t.accepted) return;
    t.messages.add(ChatLine(true, text));
    PushService.notifyMessage(t.dog.name);
    notifyListeners();
  }

  void block(DogProfile d) {
    blocked.add(d.id);
    matches.removeWhere((m) => m.dog.id == d.id);
    incoming.removeWhere((m) => m.dog.id == d.id);
    saved.removeWhere((m) => m.id == d.id);
    applyFilters();
  }
}
