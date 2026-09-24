import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import 'deal.dart';

const _coral = Color(0xFFE25C3A);
const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.matches.where((m) => !m.accepted).toList();
    final open = state.matches.where((m) => m.accepted).toList();
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Chatt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.incoming.isNotEmpty) ...[
            const Text('Vill matcha med dig', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
            const SizedBox(height: 8),
            for (final m in state.incoming)
              Card(
                color: Colors.white,
                child: ListTile(
                  title: Text('${m.dog.owner} · ${m.dog.name}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${m.dog.breed} vill matcha. Godkänn för att chatta.'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      const Badge(label: Text('1')),
                      TextButton(onPressed: () => state.declineIncoming(m), child: const Text('Nej')),
                      FilledButton(onPressed: () => state.acceptIncoming(m), child: const Text('Godkänn')),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
          if (pending.isNotEmpty) ...[
            const Text('Väntar på svar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
            const SizedBox(height: 8),
            for (final m in pending)
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFE0D4), child: Icon(Icons.hourglass_top, color: _coral)),
                title: Text(m.dog.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Skickat till ${m.dog.owner}. Går ut efter 7 dagar.'),
                trailing: TextButton(onPressed: () => state.simulateAccept(m), child: const Text('De godkände')),
              ),
            const SizedBox(height: 16),
          ],
          const Text('Aktiva chattar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
          const SizedBox(height: 8),
          if (open.isEmpty) const Text('Inga godkända matcher än.', style: TextStyle(color: Color(0xFF3D4A57))),
          for (final m in open)
            Card(
              color: Colors.white,
              child: ListTile(
                leading: Badge(
                  isLabelVisible: m.unread > 0,
                  label: Text('${m.unread}'),
                  child: const CircleAvatar(backgroundColor: _coral, child: Icon(Icons.pets, color: Colors.white)),
                ),
                title: Text(m.dog.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(m.dog.breed),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  state.markRead(m);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(state: state, thread: m)));
                },
              ),
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

class _ChatPageState extends State<ChatPage> with SingleTickerProviderStateMixin {
  final c = TextEditingController();
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    widget.state.markRead(widget.thread);
  }

  @override
  void dispose() {
    pulse.dispose();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.thread;
    final breedChat = widget.state.canNegotiate(t);
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(t.dog.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (breedChat)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ScaleTransition(
                scale: Tween(begin: 0.96, end: 1.04).animate(CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () => DealSheet.open(context, widget.state, t).then((_) {
                    if (mounted) setState(() {});
                  }),
                  icon: const Icon(Icons.handshake, size: 18),
                  label: const Text('Förhandla', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            onPressed: () {
              widget.state.block(t.dog);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!t.accepted)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chatten öppnas när den andra ägaren godkänner matchningen.'),
            ),
          if (breedChat)
            Material(
              color: const Color(0xFFFFE0D4),
              child: ListTile(
                leading: const Icon(Icons.description, color: _coral),
                title: Text(
                  t.deal == null
                      ? 'Avel — tryck Förhandla för avtal'
                      : (t.deal!.signedByMe.isEmpty ? 'Avtal skapat — väntar på signering' : 'Avtal signerat ✓'),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                trailing: const Icon(Icons.chevron_right, color: _coral),
                onTap: () => DealSheet.open(context, widget.state, t).then((_) {
                  if (mounted) setState(() {});
                }),
              ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: m.fromMe ? _coral : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        m.text,
                        style: TextStyle(color: m.fromMe ? Colors.white : _ink, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: c,
                    enabled: t.accepted,
                    decoration: InputDecoration(
                      hintText: t.accepted ? 'Skriv ett meddelande' : 'Väntar på godkännande',
                      filled: true,
                      fillColor: _cream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _coral),
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
