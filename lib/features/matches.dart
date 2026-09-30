import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import 'deal.dart';

const _coral = Color(0xFFE25C3A);
const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);

String _preview(MatchThread m) {
  if (m.messages.isEmpty) return m.dog.breed.isEmpty ? 'Tryck för att skriva' : m.dog.breed;
  final last = m.messages.last;
  if (last.recalled) return 'Meddelandet togs bort';
  return last.fromMe ? 'Du: ${last.text}' : last.text;
}

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
                subtitle: Text('Skickat till ${m.dog.owner}.'),
              ),
            const SizedBox(height: 16),
          ],
          const Text('Aktiva chattar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
          const SizedBox(height: 6),
          const Text('Svep åt sidan för att radera. Chatten finns kvar hos den andra.', style: TextStyle(color: Color(0xFF3D4A57), fontSize: 13)),
          const SizedBox(height: 8),
          if (open.isEmpty) const Text('Inga godkända matcher än.', style: TextStyle(color: Color(0xFF3D4A57))),
          for (final m in open)
            Dismissible(
              key: ValueKey(m.cloudMatchId.isEmpty ? m.dog.id : m.cloudMatchId),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: const Color(0xFF8B3A32),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              confirmDismiss: (_) => _confirmDelete(context, m.dog.name),
              onDismissed: (_) => state.deleteThread(m),
              child: Card(
                color: Colors.white,
                child: ListTile(
                  leading: Badge(
                    isLabelVisible: m.unread > 0,
                    label: Text('${m.unread}'),
                    child: const CircleAvatar(backgroundColor: _coral, child: Icon(Icons.pets, color: Colors.white)),
                  ),
                  title: Text(m.dog.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(_preview(m), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    state.markRead(m);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(state: state, thread: m)));
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Radera chatten?'),
      content: Text('Chatten med $name försvinner från din telefon. Den andra ägaren behåller den.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Radera')),
      ],
    ),
  );
  return ok == true;
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
  Timer? poll;
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    widget.state.markRead(widget.thread);
    widget.state.refreshChat(widget.thread);
    poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      await widget.state.refreshChat(widget.thread);
      widget.state.markRead(widget.thread);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    poll?.cancel();
    pulse.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _recall(ChatLine m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dra tillbaka?'),
        content: const Text('Meddelandet tas bort för er båda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Dra tillbaka')),
        ],
      ),
    );
    if (ok == true) {
      await widget.state.recall(widget.thread, m);
      if (mounted) setState(() {});
    }
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
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (await _confirmDelete(context, t.dog.name) && context.mounted) {
                await widget.state.deleteThread(t);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!t.accepted)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chatten öppnas när den andra ägaren också swipear ja.'),
            ),
          if (breedChat)
            Material(
              color: const Color(0xFFFFE0D4),
              child: ListTile(
                leading: const Icon(Icons.description, color: _coral),
                title: Text(
                  t.deal == null ? 'Avel — tryck Förhandla för avtal' : (t.deal!.signedByMe.isEmpty ? 'Avtal skapat — väntar på signering' : 'Avtal signerat'),
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
                    child: GestureDetector(
                      onLongPress: m.fromMe && !m.recalled && m.id.isNotEmpty ? () => _recall(m) : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
                        decoration: BoxDecoration(
                          color: m.recalled ? const Color(0xFFE7E1DC) : (m.fromMe ? _coral : Colors.white),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          m.recalled ? 'Meddelandet togs bort' : m.text,
                          style: TextStyle(
                            color: m.recalled ? const Color(0xFF5C6B78) : (m.fromMe ? Colors.white : _ink),
                            fontStyle: m.recalled ? FontStyle.italic : FontStyle.normal,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
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
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: t.accepted ? 'Skriv ett meddelande' : 'Väntar på match',
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
