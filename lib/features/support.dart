import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/network.dart';

const _cream = Color(0xFFFFF4EC);
const _coral = Color(0xFFE25C3A);
const _ink = Color(0xFF14202B);

class _Msg {
  const _Msg(this.fromMe, this.text);
  final bool fromMe;
  final String text;
}

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});
  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final ask = TextEditingController();
  final scroll = ScrollController();
  final msgs = <_Msg>[
    const _Msg(false, 'Hej! Jag är PawMatch-assistenten. Fråga om matchning, avel, GDPR, konto eller hur appen funkar.'),
  ];

  String _answer(String q) {
    final t = q.toLowerCase();
    if (t.contains('gdpr') || t.contains('integritet') || t.contains('personuppg') || t.contains('data')) {
      return 'PawMatch följer GDPR. Vi sparar bara det som behövs för konto, matchning och avtal. Du kan begära registerutdrag eller radering via Profil eller support@pawmatch.app. Vi säljer inte dina uppgifter.';
    }
    if (t.contains('radera') || t.contains('ta bort konto')) {
      return 'Gå till Profil → Radera konto. Då tas profil, hundar och chattar bort. Det kan ta några dagar innan backup rensas.';
    }
    if (t.contains('personnummer') || t.contains('id')) {
      return 'Personuppgifter används för att göra avel och avtal tryggare. Du måste vara 18 år. Vi granskar uppgifter manuellt. Lämna inte extra känsliga uppgifter i chatten.';
    }
    if (t.contains('match') || t.contains('like') || t.contains('swipe')) {
      return 'Svep höger för like, vänster för nej. Tryck på kortet för fler bilder och info. Den andra ägaren måste godkänna innan ni kan chatta. Svarar de inte inom 7 dagar kan hunden dyka upp igen.';
    }
    if (t.contains('avel') || t.contains('valp') || t.contains('stamtavla') || t.contains('avtal')) {
      return 'Avel kräver att hunden är markerad för avel. Fyll i kön, vikt, vaccin och hälsa. Avtal skapas i chatten via Förhandla. Båda måste signera. PawMatch ger ingen veterinärrådgivning.';
    }
    if (t.contains('kön') || t.contains('hane') || t.contains('tik')) {
      return 'Om din hund är hane visas bara tikar i flödet. Är hon tik visas bara hanar. Det gäller För dig och Matcha.';
    }
    if (t.contains('chatt') || t.contains('meddel')) {
      return 'Chatt öppnas efter godkänd match. Anmäl olämpliga meddelanden med flaggan. Blockerade användare syns inte igen.';
    }
    if (t.contains('bild') || t.contains('foto')) {
      return 'Lägg in minst två bilder på hunden. Andra kan bläddra bilderna när de öppnar kortet.';
    }
    if (t.contains('filter') || t.contains('närmast') || t.contains('ort') || t.contains('ras')) {
      return 'I Matcha finns filter för ras, ort, ålder och radie. I För dig kan du sortera på Närmast, Hundvänner eller Avel.';
    }
    if (t.contains('hej') || t.contains('hjälp')) {
      return 'Hej! Vad vill du veta — matchning, avel, GDPR eller konto?';
    }
    return 'Jag hjälper med appen, matchning, avel, GDPR och konto. För sjukdom: kontakta veterinär. Mejla support@pawmatch.app om du vill prata med en människa.';
  }

  bool busy = false;

  Future<void> _sendAsk() async {
    final t = ask.text.trim();
    if (t.isEmpty || busy) return;
    setState(() {
      busy = true;
      msgs.add(_Msg(true, t));
      ask.clear();
    });
    final history = [
      for (final m in msgs.skip(1)) {'role': m.fromMe ? 'user' : 'assistant', 'text': m.text},
    ];
    final live = await Network.askSupport(history);
    if (!mounted) return;
    setState(() {
      msgs.add(_Msg(false, live ?? _answer(t)));
      busy = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  Future<void> _mail() async {
    final uri = Uri(scheme: 'mailto', path: 'support@pawmatch.app', queryParameters: {'subject': 'PawMatch support'});
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skriv till support@pawmatch.app')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Kundsupport'),
        actions: [TextButton(onPressed: _mail, child: const Text('E-post'))],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                return Align(
                  alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: m.fromMe ? _coral : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.fromMe ? Colors.white : _ink, fontWeight: FontWeight.w600, height: 1.35)),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ask,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendAsk(),
                    decoration: InputDecoration(
                      hintText: 'Skriv en fråga...',
                      filled: true,
                      fillColor: _cream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send_rounded, color: _coral), onPressed: busy ? null : _sendAsk),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
