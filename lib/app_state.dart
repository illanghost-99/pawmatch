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
  double lat = 59.3293;
  double lng = 18.0686;
  String locationLabel = 'Stockholm';
  String breedQuery = '';
  int ageMin = 0;
  int ageMax = 15;
  int radiusKm = 250;
  String area = '';
  String intentFilter = 'all';
  List<DogProfile> deck = List.of(sampleDogs);
  final List<MatchThread> matches = [];
  final List<DogProfile> saved = [];
  final Set<String> blocked = {};
  final List<MyDog> myDogs = [];

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
    applyFilters();
    notifyListeners();
  }

  void addMyDog(MyDog d) {
    myDogs.add(d);
    PushService.notifyLive(d.name);
    notifyListeners();
  }

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
    if (intentFilter != 'all' && d.intent == intentFilter) s += 2;
    return s;
  }

  List<DogProfile> get forYou {
    final list = filtered.toList()..sort((a, b) => score(b).compareTo(score(a)));
    return list;
  }

  Iterable<DogProfile> get filtered sync* {
    for (final d in sampleDogs) {
      if (blocked.contains(d.id)) continue;
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

  void swipe(DogProfile d, {required bool like}) {
    deck.removeWhere((x) => x.id == d.id);
    if (like) {
      matches.insert(0, MatchThread(d, [const ChatLine(false, 'Hej! Trevligt att matcha')]));
      PushService.notifyMatch(d.name);
    }
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
    t.messages.add(ChatLine(true, text));
    PushService.notifyMessage(t.dog.name);
    notifyListeners();
  }

  void block(DogProfile d) {
    blocked.add(d.id);
    matches.removeWhere((m) => m.dog.id == d.id);
    saved.removeWhere((m) => m.id == d.id);
    applyFilters();
  }
}
