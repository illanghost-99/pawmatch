import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final subject = TextEditingController();
  final body = TextEditingController();
  final ask = TextEditingController();
  final replies = <String>[
    'Hej! Jag är PawMatch-assistenten. Fråga om matchning, avel, integritet eller hur appen funkar.',
  ];

  String _answer(String q) {
    final t = q.toLowerCase();
    if (t.contains('match') || t.contains('like') || t.contains('swipe')) {
      return 'När du trycker Matcha skickas en förfrågan. Ni kan chatta först när den andra ägaren godkänner. Svarar de inte inom 7 dagar försvinner förfrågan och hunden kan synas igen.';
    }
    if (t.contains('avel') || t.contains('valp') || t.contains('stamtavla')) {
      return 'Avel sker mellan ägare. Kryssa i stamtavla, vaccin och allergier. PawMatch ger ingen veterinärrådgivning och tar ingen provision i version 1.';
    }
    if (t.contains('radera') || t.contains('gdpr') || t.contains('integritet') || t.contains('konto')) {
      return 'Du raderar kontot under Profil. Vi följer GDPR. Registerutdrag: support@pawmatch.app.';
    }
    if (t.contains('chatt') || t.contains('meddel')) {
      return 'Chatt öppnas bara efter godkänd match. Anmäl olämpliga meddelanden med flaggan i chatten.';
    }
    return 'Jag hjälper med appen, matchning, policy och konto. För sjukdom: kontakta veterinär. Mejla support@pawmatch.app om jag inte räcker.';
  }

  Future<void> _send() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@pawmatch.app',
      queryParameters: {
        'subject': subject.text.isEmpty ? 'PawMatch support' : subject.text,
        'body': body.text,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Öppna din mejlapp och skriv till support@pawmatch.app')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kontakta oss')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('AI-assistent 24/7', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF7F4EE), borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in replies) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(r)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: TextField(controller: ask, decoration: const InputDecoration(hintText: 'Fråga om appen...'))),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (ask.text.trim().isEmpty) return;
                  setState(() {
                    replies.add('Du: ${ask.text.trim()}');
                    replies.add(_answer(ask.text.trim()));
                    ask.clear();
                  });
                },
              ),
            ],
          ),
          const Divider(height: 36),
          const Text('E-post', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Svar inom 1–2 arbetsdagar. Akuta djursjukdomar går till veterinär.'),
          const SizedBox(height: 12),
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'Ämne', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: body, maxLines: 5, decoration: const InputDecoration(labelText: 'Meddelande', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _send, icon: const Icon(Icons.mail_outline), label: const Text('Öppna mejl till support')),
        ],
      ),
    );
  }
}
