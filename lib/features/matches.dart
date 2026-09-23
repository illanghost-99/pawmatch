import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.matches.where((m) => !m.accepted && !m.expired).toList();
    final open = state.matches.where((m) => m.accepted).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EE),
      appBar: AppBar(title: const Text('Chatt'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.incoming.isNotEmpty) ...[
            const Text('Vill matcha med dig', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final m in state.incoming)
              Card(
                child: ListTile(
                  title: Text('${m.dog.owner} · ${m.dog.name}'),
                  subtitle: Text('${m.dog.breed} vill matcha. Godkänn för att chatta.'),
                  trailing: Wrap(
                    children: [
                      TextButton(onPressed: () => state.declineIncoming(m), child: const Text('Nej')),
                      FilledButton(onPressed: () => state.acceptIncoming(m), child: const Text('Godkänn')),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (pending.isNotEmpty) ...[
            const Text('Väntar på svar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            for (final m in pending)
              ListTile(
                leading: const Icon(Icons.hourglass_top),
                title: Text(m.dog.name),
                subtitle: Text('Skickat till ${m.dog.owner}. Förfrågan går ut efter 7 dagar.'),
              ),
            const SizedBox(height: 16),
          ],
          const Text('Aktiva chattar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (open.isEmpty) const Text('Inga godkända matcher än.'),
          for (final m in open)
            ListTile(
              title: Text(m.dog.name),
              subtitle: Text(m.dog.breed),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(state: state, thread: m))),
            ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.state, required this.thread});
  final AppState state;
  final MatchThread thread;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.dog.name),
        actions: [IconButton(icon: const Icon(Icons.flag_outlined), onPressed: () { widget.state.block(t.dog); Navigator.pop(context); })],
      ),
      body: Column(
        children: [
          if (!t.accepted)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chatten öppnas när den andra ägaren godkänner matchningen.'),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in t.messages)
                  Align(
                    alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.fromMe ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m.text),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: c, enabled: t.accepted, decoration: InputDecoration(hintText: t.accepted ? 'Skriv...' : 'Väntar på godkännande'))),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: !t.accepted
                      ? null
                      : () {
                          if (c.text.trim().isEmpty) return;
                          widget.state.send(t, c.text.trim());
                          c.clear();
                          setState(() {});
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
