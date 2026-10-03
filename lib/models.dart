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
    this.photos = const [],
    this.sex = '',
    this.weightKg = 0,
    this.ownerPhoto = '',
    this.intent = 'friends',
    this.pedigreeStatus = ReviewStatus.none,
    this.vaccineStatus = ReviewStatus.none,
    this.availableForBreeding = false,
    this.availableForFriends = true,
    this.reviews = const [],
    this.ownerEmail = '',
    this.chipped = false,
    this.vaccinated = false,
    this.dewormed = false,
    this.neutered = false,
    this.hasPedigree = false,
    this.hasAllergies = false,
    this.allergyNote = '',
    this.healthNote = '',
    this.vaccineNote = '',
    this.pedigreeNote = '',
    this.ownerVerified = false,
    this.dogVerified = false,
    this.ownerPremium = false,
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
  final List<String> photos;
  final String sex;
  final double weightKg;
  final String ownerPhoto;
  final String intent;
  final ReviewStatus pedigreeStatus;
  final ReviewStatus vaccineStatus;
  final bool availableForBreeding;
  final bool availableForFriends;
  final List<String> reviews;
  final String ownerEmail;
  final bool chipped;
  final bool vaccinated;
  final bool dewormed;
  final bool neutered;
  final bool hasPedigree;
  final bool hasAllergies;
  final String allergyNote;
  final String healthNote;
  final String vaccineNote;
  final String pedigreeNote;
  final bool ownerVerified;
  final bool dogVerified;
  final bool ownerPremium;

  String get sizeBand {
    if (weightKg <= 0) return '';
    if (weightKg < 10) return 'small';
    if (weightKg < 25) return 'medium';
    return 'large';
  }

  List<String> get gallery {
    final all = <String>[if (photoUrl.isNotEmpty) photoUrl, ...photos];
    return all.toSet().toList();
  }

  String get sexLabel {
    final s = sex.toLowerCase();
    if (s == 'hane') return 'Hane';
    if (s == 'tik') return 'Tik';
    return '';
  }

  String get weightLabel {
    if (weightKg <= 0) return 'Ej angiven';
    final whole = weightKg == weightKg.roundToDouble();
    return '${whole ? weightKg.toStringAsFixed(0) : weightKg.toStringAsFixed(1)} kg';
  }
}

class ChatLine {
  const ChatLine(
    this.fromMe,
    this.text, {
    this.id = '',
    this.recalled = false,
    this.senderName = '',
    this.createdAt,
    this.seen = false,
    this.system = false,
  });
  final bool fromMe;
  final String text;
  final String id;
  final bool recalled;
  final String senderName;
  final DateTime? createdAt;
  final bool seen;
  final bool system;
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
    List<List<SigPoint>>? signatureOther,
  })  : signature = signature ?? [],
        signatureOther = signatureOther ?? [];
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
  List<List<SigPoint>> signatureOther;
  bool get fullySigned => signedByMe.isNotEmpty && signedByOther.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'price': pricePerPuppy,
        'pups': expectedPups,
        'place': place,
        'notes': notes,
        'a': partyA,
        'b': partyB,
        'body': body,
        'me': signedByMe,
        'other': signedByOther,
        'sig': [
          for (final stroke in signature) [for (final p in stroke) [p.x, p.y]],
        ],
        'sigB': [
          for (final stroke in signatureOther) [for (final p in stroke) [p.x, p.y]],
        ],
      };

  static List<List<SigPoint>> _strokes(dynamic raw) {
    if (raw is! List) return [];
    return [
      for (final stroke in raw)
        if (stroke is List)
          [
            for (final p in stroke)
              if (p is List && p.length >= 2) SigPoint((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          ],
    ];
  }

  factory BreedingDeal.fromJson(Map<String, dynamic> j) => BreedingDeal(
        pricePerPuppy: '${j['price'] ?? ''}',
        expectedPups: '${j['pups'] ?? ''}',
        place: '${j['place'] ?? ''}',
        notes: '${j['notes'] ?? ''}',
        partyA: '${j['a'] ?? ''}',
        partyB: '${j['b'] ?? ''}',
        body: '${j['body'] ?? ''}',
        signedByMe: '${j['me'] ?? ''}',
        signedByOther: '${j['other'] ?? ''}',
        signature: _strokes(j['sig']),
        signatureOther: _strokes(j['sigB']),
      );
}

class MatchThread {
  MatchThread(
    this.dog,
    this.messages, {
    this.accepted = false,
    this.outgoing = true,
    DateTime? createdAt,
    this.unread = 0,
    this.cloudMatchId = '',
    this.peerEmail = '',
  }) : createdAt = createdAt ?? DateTime.now();
  final DogProfile dog;
  final List<ChatLine> messages;
  bool accepted;
  final bool outgoing;
  final DateTime createdAt;
  int unread;
  BreedingDeal? deal;
  String cloudMatchId;
  String peerEmail;
  bool get expired => DateTime.now().difference(createdAt).inDays >= 7;
}

class GroupMember {
  const GroupMember(this.email, this.name);
  final String email;
  final String name;
}

class GroupChat {
  GroupChat({
    required this.id,
    required this.name,
    required this.ownerEmail,
    required this.members,
    List<ChatLine>? messages,
    this.unread = 0,
  }) : messages = messages ?? [];
  final String id;
  String name;
  final String ownerEmail;
  List<GroupMember> members;
  final List<ChatLine> messages;
  int unread;
}

class MyDog {
  MyDog({
    required this.name,
    required this.breed,
    required this.age,
    required this.city,
    required this.bio,
    this.sex = '',
    this.weightKg = 0,
    this.photos = const [],
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
    this.pedigreeDoc = '',
    this.vaccineDoc = '',
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
  List<String> photos;
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
  String pedigreeDoc;
  String vaccineDoc;
  ReviewStatus pedigreeStatus;
  ReviewStatus vaccineStatus;

  bool get breedingReady => sex.isNotEmpty && weightKg > 0 && vaccinated;
}
