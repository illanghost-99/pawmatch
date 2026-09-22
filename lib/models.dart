class Interest {
  const Interest(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

const kInterests = [
  Interest('friends', 'Hundvänner', '🐾'),
  Interest('walks', 'Promenader', '🚶'),
  Interest('play', 'Lekträffar', '🎾'),
  Interest('training', 'Träning', '🏅'),
  Interest('puppies', 'Valpar / avel', '🍼'),
  Interest('park', 'Hundrastgård', '🌳'),
  Interest('swim', 'Simma', '🌊'),
  Interest('cafe', 'Uteservering', '☕'),
  Interest('agility', 'Agility', '⚡'),
  Interest('hunt', 'Jakt', '🌲'),
  Interest('show', 'Utställning', '🎩'),
  Interest('city', 'Stad', '🏙️'),
  Interest('nature', 'Natur', '⛰️'),
  Interest('small', 'Små raser', '🐶'),
  Interest('large', 'Stora raser', '🐕'),
  Interest('senior', 'Seniorhundar', '👴'),
];

enum UserRole { owner, kennel, vet, enthusiast }

enum ReviewStatus { none, pending, approved, rejected }

class DogProfile {
  const DogProfile({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
    required this.city,
    required this.lat,
    required this.lng,
    required this.bio,
    required this.owner,
    required this.tags,
    this.photoUrl = '',
    this.intent = 'friends',
    this.pedigreeStatus = ReviewStatus.none,
    this.vaccineStatus = ReviewStatus.none,
    this.availableForBreeding = false,
    this.availableForFriends = true,
  });

  final String id;
  final String name;
  final String breed;
  final int age;
  final String city;
  final double lat;
  final double lng;
  final String bio;
  final String owner;
  final List<String> tags;
  final String photoUrl;
  final String intent;
  final ReviewStatus pedigreeStatus;
  final ReviewStatus vaccineStatus;
  final bool availableForBreeding;
  final bool availableForFriends;
}

class ChatLine {
  const ChatLine(this.fromMe, this.text);
  final bool fromMe;
  final String text;
}

class MatchThread {
  MatchThread(this.dog, this.messages);
  final DogProfile dog;
  final List<ChatLine> messages;
}

class MyDog {
  MyDog({
    required this.name,
    required this.breed,
    required this.age,
    required this.city,
    required this.bio,
    this.availableForFriends = true,
    this.availableForBreeding = false,
    this.pedigreeNote = '',
    this.vaccineNote = '',
    this.pedigreeStatus = ReviewStatus.pending,
    this.vaccineStatus = ReviewStatus.pending,
  });
  String name;
  String breed;
  int age;
  String city;
  String bio;
  bool availableForFriends;
  bool availableForBreeding;
  String pedigreeNote;
  String vaccineNote;
  ReviewStatus pedigreeStatus;
  ReviewStatus vaccineStatus;
}
