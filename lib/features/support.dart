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
      appBar: AppBar(title: const Text('Kundsupport')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Vi hjälper dig', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Skriv kort vad som hänt. Svar brukar komma inom 1–2 arbetsdagar. '
            'Akuta djursjukdomsfrågor går till veterinär — inte till oss.',
          ),
          const SizedBox(height: 16),
          TextField(controller: subject, decoration: const InputDecoration(labelText: 'Ämne', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(
            controller: body,
            maxLines: 6,
            decoration: const InputDecoration(labelText: 'Meddelande', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _send,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Öppna mejl till support'),
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.schedule),
            title: Text('Supporttider'),
            subtitle: Text('Vardagar 09–17 (CET)'),
          ),
        ],
      ),
    );
  }
}
