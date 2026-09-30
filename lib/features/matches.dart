import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../v2/premium_page.dart';
import 'deal.dart';

const _coral = Color(0xFFE25C3A);
const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);

String _groupPreview(GroupChat g) {
  if (g.messages.isEmpty) {
    final names = [for (final m in g.members) if (m.name.isNotEmpty) m.name];
    return names.isEmpty ? 'Gruppchatt' : names.join(', ');
  }
  final last = g.messages.last;
  if (last.recalled) return 'Meddelandet togs bort';
  final who = last.fromMe ? 'Du' : (last.senderName.isEmpty ? 'Någon' : last.senderName);
  return '$who: ${last.text}';
}

String _clock(DateTime? t) {
  if (t == null) return '';
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

String _personName(MatchThread t) {
  final o = t.dog.owner.trim();
  if (o.isNotEmpty && !o.contains('@') && o.toLowerCase() != 'ägare') return o;
  if (t.dog.name.trim().isNotEmpty && t.dog.name != 'Hund' && t.dog.name != 'Match') return t.dog.name;
  return 'Hundägaren';
}

class TalkBubble extends StatelessWidget {
  const TalkBubble({super.key, required this.line, required this.otherName, this.onRecall});
  final ChatLine line;
  final String otherName;
  final VoidCallback? onRecall;

  @override
  Widget build(BuildContext context) {
    final m = line;
    if (m.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Text(m.text, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF5C6B78), fontWeight: FontWeight.w600, fontSize: 13)),
            if (_clock(m.createdAt).isNotEmpty) Text(_clock(m.createdAt), style: const TextStyle(color: Color(0xFF8A939C), fontSize: 11)),
          ],
        ),
      );
    }
    final time = _clock(m.createdAt);
    final status = !m.fromMe ? '' : (m.id.isEmpty ? 'Skickar…' : (m.seen ? 'Läst' : 'Levererat'));
    final meta = [time, status].where((s) => s.isNotEmpty).join(' · ');
    final name = m.fromMe ? 'Jag' : (m.senderName.trim().isNotEmpty ? m.senderName.trim() : otherName);
    return Align(
      alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onRecall,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          child: Column(
            crossAxisAlignment: m.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 3, left: 6, right: 6),
                child: Text(name, style: const TextStyle(color: Color(0xFF8A939C), fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              if (meta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
                  child: Text(meta, style: const TextStyle(color: Color(0xFF8A939C), fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        actions: [
          IconButton(
            tooltip: state.isPremium ? 'Ny grupp' : 'Premium krävs',
            onPressed: () => state.isPremium ? _openCreateGroup(context, state) : _premiumGroup(context, state),
            icon: Icon(
              Icons.add_circle_rounded,
              size: 32,
              color: state.isPremium ? _coral : const Color(0xFFC4B8B0),
            ),
          ),
        ],
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
          if (state.groups.isNotEmpty) ...[
            const Text('Grupper', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
            const SizedBox(height: 8),
            for (final g in state.groups)
              Card(
                color: Colors.white,
                child: ListTile(
                  leading: Badge(
                    isLabelVisible: g.unread > 0,
                    label: Text('${g.unread}'),
                    child: const CircleAvatar(backgroundColor: Color(0xFF1F7A6C), child: Icon(Icons.groups, color: Colors.white)),
                  ),
                  title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(_groupPreview(g), maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    state.markGroupRead(g);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GroupChatPage(state: state, group: g)));
                  },
                ),
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
  final scroll = ScrollController();
  Timer? poll;
  bool _nearBottom = true;
  double _inset = 0;
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (!scroll.hasClients) return;
      final gap = scroll.position.maxScrollExtent - scroll.position.pixels;
      _nearBottom = gap < 120;
    });
    widget.state.markRead(widget.thread);
    widget.state.refreshChat(widget.thread, markSeen: true);
    poll = Timer.periodic(const Duration(seconds: 1), (_) async {
      await widget.state.refreshChat(widget.thread, markSeen: true);
      widget.state.markRead(widget.thread);
      if (mounted) setState(() {});
      _follow();
    });
    _follow(force: true);
  }

  void _follow({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scroll.hasClients) return;
      if (!force && !_nearBottom) return;
      scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    poll?.cancel();
    pulse.dispose();
    scroll.dispose();
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
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset != _inset) {
      _inset = inset;
      _follow();
    }
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
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                for (final m in t.messages)
                  TalkBubble(
                    line: m,
                    otherName: _personName(t),
                    onRecall: m.fromMe && !m.recalled && m.id.isNotEmpty && !m.system ? () => _recall(m) : null,
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
                          _follow(force: true);
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


void _premiumGroup(BuildContext context, AppState state) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Premium'),
      content: const Text('Gruppchatt ingår i Premium. Knappen syns för alla, men bara Premium kan skapa en grupp med personer du redan chattat med.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Inte nu')),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage(state: state)));
          },
          child: const Text('Visa Premium'),
        ),
      ],
    ),
  );
}

Future<void> _openCreateGroup(BuildContext context, AppState state) async {
  final partners = state.chatPartners;
  final name = TextEditingController();
  final picked = <String>{};
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ny grupp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
              const SizedBox(height: 6),
              const Text('Välj minst två personer du redan chattat med.', style: TextStyle(color: Color(0xFF3D4A57))),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setLocal(() {}),
                decoration: InputDecoration(
                  labelText: 'Namn, till exempel Promenad lördag',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              if (partners.isEmpty)
                const Text('Du har inga chattar än. Matcha först, sedan kan du bjuda in dem.')
              else
                for (final person in partners)
                  CheckboxListTile(
                    value: picked.contains(person.email),
                    activeColor: _coral,
                    contentPadding: EdgeInsets.zero,
                    title: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    onChanged: (on) => setLocal(() {
                      if (on == true) {
                        picked.add(person.email);
                      } else {
                        picked.remove(person.email);
                      }
                    }),
                  ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: name.text.trim().isEmpty || picked.length < 2
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: const Text('Skapa grupp'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (ok != true) {
    name.dispose();
    return;
  }
  final people = [for (final person in partners) if (picked.contains(person.email)) person];
  final made = await state.createGroup(name.text, people);
  name.dispose();
  if (!made && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gruppen kunde inte skapas. Försök igen.')));
  }
}

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key, required this.state, required this.group});
  final AppState state;
  final GroupChat group;
  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final c = TextEditingController();
  final scroll = ScrollController();
  Timer? poll;

  GroupChat get g {
    for (final item in widget.state.groups) {
      if (item.id == widget.group.id) return item;
    }
    return widget.group;
  }

  bool get mine => g.ownerEmail == widget.state.email.toLowerCase();

  @override
  void initState() {
    super.initState();
    widget.state.markGroupRead(g);
    widget.state.refreshGroup(g);
    _jump();
    poll = Timer.periodic(const Duration(seconds: 1), (_) async {
      await widget.state.refreshGroup(g);
      widget.state.markGroupRead(g);
      if (mounted) setState(() {});
      _jump();
    });
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    poll?.cancel();
    scroll.dispose();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = g;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.group_outlined), onPressed: () => _members(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              children: [
                for (final m in group.messages)
                  TalkBubble(line: m, otherName: m.senderName.isEmpty ? 'Hundägaren' : m.senderName),
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
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Skriv till gruppen',
                      filled: true,
                      fillColor: _cream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _coral),
                  onPressed: () {
                    if (c.text.trim().isEmpty) return;
                    widget.state.sendGroup(group, c.text.trim());
                    c.clear();
                    setState(() {});
                    _jump();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _members(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final group = g;
            final inside = group.members.map((m) => m.email).toSet();
            final extra = [for (final person in widget.state.chatPartners) if (!inside.contains(person.email)) person];
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(mine ? 'Du skapade gruppen' : 'Medlemmar', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  for (final member in group.members)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(member.email == group.ownerEmail ? 'Skapare' : 'Medlem'),
                      trailing: mine && member.email != group.ownerEmail
                          ? IconButton(
                              icon: const Icon(Icons.person_remove_outlined, color: Color(0xFF8B3A32)),
                              onPressed: () async {
                                await widget.state.removeGroupMember(group, member);
                                if (ctx.mounted) setLocal(() {});
                              },
                            )
                          : null,
                    ),
                  if (mine && extra.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Lägg till från dina chattar', style: TextStyle(fontWeight: FontWeight.w800)),
                    for (final person in extra)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(person.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.person_add_alt_1, color: _coral),
                          onPressed: () async {
                            await widget.state.addGroupMember(group, person);
                            if (ctx.mounted) setLocal(() {});
                          },
                        ),
                      ),
                  ],
                  if (mine) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B3A32), side: const BorderSide(color: Color(0xFF8B3A32))),
                      onPressed: () async {
                        final yes = await showDialog<bool>(
                          context: ctx,
                          builder: (d) => AlertDialog(
                            title: const Text('Lös upp gruppen?'),
                            content: const Text('Chatten försvinner för alla i gruppen.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Avbryt')),
                              TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Lös upp')),
                            ],
                          ),
                        );
                        if (yes == true) {
                          await widget.state.deleteGroup(group);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text('Lös upp gruppen'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
