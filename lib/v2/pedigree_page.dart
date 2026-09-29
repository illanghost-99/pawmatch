import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PedigreePage extends StatelessWidget {
  const PedigreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(title: const Text('Stamtavla'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'PawMatch hämtar inte data från SKK. Ladda upp papper eller fyll i släkten själv. Status blir “granskas av oss” — inte “verifierat av SKK”.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          _node('Din hund', 'Registreringsnr valfritt'),
          Row(
            children: [
              Expanded(child: _node('Mor', 'Okänd')),
              const SizedBox(width: 8),
              Expanded(child: _node('Far', 'Okänd')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _node('Mormor', '')),
              Expanded(child: _node('Morfar', '')),
              Expanded(child: _node('Farmor', '')),
              Expanded(child: _node('Farfar', '')),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A), minimumSize: const Size.fromHeight(50)),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uppladdning kopplas till Storage i nästa steg.'))),
            icon: const Icon(Icons.upload_file),
            label: const Text('Ladda upp stamtavla / hälsocertifikat'),
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
