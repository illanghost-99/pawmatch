class Moderation {
  const Moderation({required this.email, required this.ban, required this.permanent, required this.note});
  final String email;
  final bool ban;
  final bool permanent;
  final String note;

  static const prompt = '''
Du är PawMatchs supportagent. Du läser en chatt mellan hundägare.
Du griper bara in vid hot, våld, hat, sexuella trakasserier, bedrägeri eller innehåll som rör barn på ett sexuellt sätt.
Vanligt prat om hundar, avel, promenader och oenighet är tillåtet.
Första regelbrottet ger 1 veckas avstängning. Andra ger 3 veckor. Tredje stänger kontot.
Sexuellt innehåll som rör barn stänger kontot direkt.
Skriv kort på svenska vem som bröt mot reglerna och varför.
''';

  static Moderation review(List<({String email, String text})> lines) {
    final scores = <String, int>{};
    var child = '';
    for (final line in lines) {
      final who = line.email.trim().toLowerCase();
      final text = line.text.toLowerCase();
      if (who.isEmpty || text.isEmpty) continue;
      if (_childHarm(text)) child = who;
      scores[who] = (scores[who] ?? 0) + _score(text);
    }
    if (child.isNotEmpty) {
      return Moderation(
        email: child,
        ban: true,
        permanent: true,
        note: 'Assistenten: sexuellt innehåll som rör barn. Kontot stängs direkt.',
      );
    }
    String worst = '';
    var best = 0;
    scores.forEach((email, score) {
      if (score > best) {
        best = score;
        worst = email;
      }
    });
    if (best >= 3 && worst.isNotEmpty) {
      return Moderation(
        email: worst,
        ban: true,
        permanent: false,
        note: 'Assistenten: hot, hat eller trakasserier i chatten. Avstängning enligt varningstrappan.',
      );
    }
    if (best >= 1) {
      return const Moderation(
        email: '',
        ban: false,
        permanent: false,
        note: 'Assistenten: möjligt regelbrott, men inte tillräckligt tydligt för avstängning. Läs chatten.',
      );
    }
    return const Moderation(
      email: '',
      ban: false,
      permanent: false,
      note: 'Assistenten: inget tydligt regelbrott. Vanligt samtal.',
    );
  }

  static bool _childHarm(String text) {
    const young = ['barn', 'minderårig', 'under 15', 'under 18', 'liten flicka', 'liten pojke'];
    const sexual = ['sex', 'naken', 'nudes', 'knull', 'våldta', 'våldt'];
    final y = young.any(text.contains);
    final s = sexual.any(text.contains);
    return y && s;
  }

  static int _score(String text) {
    const high = [
      'döda dig',
      'dödar dig',
      'ska döda',
      'mörda',
      'slå ihjäl',
      'kniv',
      'skjuta dig',
      'vet var du bor',
      'kommer hem till dig',
      'misshandla',
      'våldta',
      'jag hatar er',
    ];
    const mid = ['hora', 'fitta', 'kuk', 'dra åt helvete', 'passa dig', 'jävla'];
    if (high.any(text.contains)) return 3;
    if (mid.any(text.contains)) return 1;
    return 0;
  }
}
