import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chatt')),
      body: state.matches.isEmpty
          ? const Center(child: Text('Inga matcher än.'))
          : ListView(
              children: [
                for (final m in state.matches)
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
                Expanded(child: TextField(controller: c)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
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
