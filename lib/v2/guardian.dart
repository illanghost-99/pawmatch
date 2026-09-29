/// Flags content for humans. Never auto-bans.
class GuardianFlag {
  const GuardianFlag(this.code, this.reason, this.score);
  final String code;
  final String reason;
  final int score;
}

class Guardian {
  static const _spam = [
    'whatsapp',
    'telegram',
    'utanför appen',
    'swisha hit',
    'crypto',
    'investera',
    'gratis valp mot',
  ];
  static const _abuse = ['hora', 'döda', 'krossa', 'idiot'];
  static const _scamBreed = [
    'skickar valpen mot förskott',
    'bara swish',
    'ingen visning',
    'importerad i morgon',
  ];

  static List<GuardianFlag> scan(String raw) {
    final t = raw.toLowerCase();
    final out = <GuardianFlag>[];
    for (final w in _spam) {
      if (t.contains(w)) out.add(GuardianFlag('spam', 'Misstänkt flytt ut ur appen: $w', 40));
    }
    for (final w in _abuse) {
      if (t.contains(w)) out.add(GuardianFlag('abuse', 'Stötande språk', 70));
    }
    for (final w in _scamBreed) {
      if (t.contains(w)) out.add(GuardianFlag('scam', 'Misstänkt avelsupplägg', 80));
    }
    if (RegExp(r'(\+46|07)\d{7,}').hasMatch(t) && t.contains('skriv')) {
      out.add(const GuardianFlag('contact', 'Telefonnummer i chatt — flagga för review', 30));
    }
    return out;
  }
}
