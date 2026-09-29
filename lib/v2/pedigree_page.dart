import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/media.dart';

class PedigreePage extends StatefulWidget {
  const PedigreePage({super.key});
  @override
  State<PedigreePage> createState() => _PedigreePageState();
}

class _PedigreePageState extends State<PedigreePage> {
  final reg = TextEditingController();
  String doc = '';
  String status = 'Ingen inlämning';

  @override
  void dispose() {
    reg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(title: const Text('SKK och stamtavla'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Ladda upp SKK-intyg eller stamtavla. Vi granskar och slår upp hunden i SKK Hunddata. PawMatch hämtar inte data automatiskt från SKK.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: reg,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'SKK registreringsnummer',
              hintText: 'S12345/2022',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            leading: const Icon(Icons.upload_file, color: Color(0xFFE25C3A)),
            title: Text(doc.isEmpty ? 'Ladda upp SKK-intyg / stamtavla' : 'Intyg tillagt'),
            subtitle: Text(status),
            onTap: () async {
              final p = await Media.choose(context, title: 'SKK-intyg');
              if (p != null) setState(() {
                doc = p;
                status = 'Inskickat — väntar på granskning';
              });
            },
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A), minimumSize: const Size.fromHeight(50)),
            onPressed: () {
              if (reg.text.trim().isEmpty && doc.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fyll i nummer eller ladda upp intyg.')));
                return;
              }
              setState(() => status = 'Inskickat — väntar på granskning');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skickat till granskning. Vi söker upp hunden i SKK.')));
            },
            child: const Text('Skicka till granskning'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => launchUrl(Uri.parse('https://hundar.skk.se/hunddata/'), mode: LaunchMode.externalApplication),
            child: const Text('Öppna SKK Hunddata'),
          ),
          OutlinedButton(
            onPressed: () => launchUrl(Uri.parse('https://hundar.skk.se/Avelsdata/'), mode: LaunchMode.externalApplication),
            child: const Text('Öppna SKK Avelsdata'),
          ),
          const SizedBox(height: 20),
          const Text('Familjeträd', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          _node('Din hund', reg.text.isEmpty ? 'Registreringsnr valfritt' : reg.text),
          Row(
            children: [
              Expanded(child: _node('Mor', 'Okänd')),
              const SizedBox(width: 8),
              Expanded(child: _node('Far', 'Okänd')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _node(String title, String sub) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: Color(0xFF5C534C))),
          ],
        ),
      ),
    );
  }
}
