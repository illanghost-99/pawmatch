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
    this.ownerPhoto = '',
    this.intent = 'friends',
    this.pedigreeStatus = ReviewStatus.none,
    this.vaccineStatus = ReviewStatus.none,
    this.availableForBreeding = false,
    this.availableForFriends = true,
    this.reviews = const ['Trygg ägare', 'Svarar snabbt'],
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
  final String ownerPhoto;
  final String intent;
  final ReviewStatus pedigreeStatus;
  final ReviewStatus vaccineStatus;
  final bool availableForBreeding;
  final bool availableForFriends;
  final List<String> reviews;
}

class ChatLine {
  const ChatLine(this.fromMe, this.text);
  final bool fromMe;
  final String text;
}

class SigPoint {
  const SigPoint(this.x, this.y);
  final double x;
  final double y;
}

class BreedingDeal {
  BreedingDeal({
    required this.pricePerPuppy,
    required this.expectedPups,
    required this.place,
    required this.notes,
    required this.partyA,
    required this.partyB,
    required this.body,
    this.signedByMe = '',
    this.signedByOther = '',
    List<List<SigPoint>>? signature,
  }) : signature = signature ?? [];
  final String pricePerPuppy;
  final String expectedPups;
  final String place;
  final String notes;
  final String partyA;
  final String partyB;
  final String body;
  String signedByMe;
  String signedByOther;
  List<List<SigPoint>> signature;
  bool get fullySigned => signedByMe.isNotEmpty && signedByOther.isNotEmpty;
}

class MatchThread {
  MatchThread(this.dog, this.messages, {this.accepted = false, this.outgoing = true, DateTime? createdAt, this.unread = 0})
      : createdAt = createdAt ?? DateTime.now();
  final DogProfile dog;
  final List<ChatLine> messages;
  bool accepted;
  final bool outgoing;
  final DateTime createdAt;
  int unread;
  BreedingDeal? deal;
  bool get expired => DateTime.now().difference(createdAt).inDays >= 7;
}

class MyDog {
  MyDog({
    required this.name,
    required this.breed,
    required this.age,
    required this.city,
    required this.bio,
    required this.sex,
    required this.weightKg,
    this.availableForFriends = true,
    this.availableForBreeding = false,
    this.pedigreeNote = '',
    this.vaccineNote = '',
    this.allergyNote = '',
    this.healthNote = '',
    this.hasPedigree = false,
    this.vaccinated = false,
    this.dewormed = false,
    this.chipped = false,
    this.neutered = false,
    this.hasAllergies = false,
    this.pedigreeStatus = ReviewStatus.pending,
    this.vaccineStatus = ReviewStatus.pending,
  });
  String name;
  String breed;
  int age;
  String city;
  String bio;
  String sex;
  double weightKg;
  bool availableForFriends;
  bool availableForBreeding;
  String pedigreeNote;
  String vaccineNote;
  String allergyNote;
  String healthNote;
  bool hasPedigree;
  bool vaccinated;
  bool dewormed;
  bool chipped;
  bool neutered;
  bool hasAllergies;
  ReviewStatus pedigreeStatus;
  ReviewStatus vaccineStatus;
}
