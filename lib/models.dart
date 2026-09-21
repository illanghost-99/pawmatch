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
  Interest('hunt', 'Jakt', '🌲'),
  Interest('city', 'Stad', '🏙️'),
  Interest('nature', 'Natur', '⛰️'),
];

enum UserRole { owner, kennel, vet, enthusiast }

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
    this.intent = 'friends',
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
  final String intent;
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
