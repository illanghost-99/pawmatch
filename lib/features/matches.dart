import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../services/fcm.dart';
import '../services/media.dart';
import '../services/moderator.dart';
import '../services/network.dart';
import '../v2/premium_page.dart';
import '../widgets/dog_photo.dart';
import '../widgets/verified_mark.dart';
import 'deal.dart';
import 'owner_page.dart';

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
  return '$who: ${chatPreview(last.text)}';
}

int _stamp(ChatLine m) => m.createdAt?.millisecondsSinceEpoch ?? 8640000000000000;

List<ChatLine> _byTime(List<ChatLine> lines) {
  final copy = [...lines];
  copy.sort((a, b) => _stamp(a).compareTo(_stamp(b)));
  return copy;
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
    final photo = m.recalled ? const <String>[] : chatPhotoUrls(m.text);
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
                padding: photo.isEmpty ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10) : EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: m.recalled ? const Color(0xFFE7E1DC) : (photo.isNotEmpty ? Colors.transparent : (m.fromMe ? _coral : Colors.white)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: m.recalled
                    ? const Text('Meddelandet togs bort', style: TextStyle(color: Color(0xFF5C6B78), fontStyle: FontStyle.italic, fontWeight: FontWeight.w600, fontSize: 15))
                    : photo.isNotEmpty
                        ? _chatPhotos(context, photo)
                        : Text(
                            m.text,
                            style: TextStyle(color: m.fromMe ? Colors.white : _ink, fontWeight: FontWeight.w600, fontSize: 15),
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

bool _localDealNote(ChatLine m) {
  if (m.id.isNotEmpty) return false;
  final t = m.text;
  return t.startsWith('Avtal skapat') || t.startsWith('Du har signerat') || t.startsWith('Avtalet är signerat');
}

class _SignedDealCard extends StatelessWidget {
  const _SignedDealCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFE5F6EE),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF1F7A6C)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Avtalet är signerat', style: TextStyle(color: Color(0xFF14202B), fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF1F7A6C)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Båda har skrivit på. Tryck för att öppna avtalet.', style: TextStyle(color: Color(0xFF1F7A6C), fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('Levererat', style: TextStyle(color: Color(0xFF8A939C), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _chatPhotos(BuildContext context, List<String> urls) {
  final big = urls.length == 1;
  final wide = urls.length == 2 || urls.length == 4;
  final size = big ? 220.0 : (wide ? 108.0 : 70.0);
  final height = big ? 220.0 : (wide ? 140.0 : 70.0);
  return SizedBox(
    width: 220,
    child: Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (var i = 0; i < urls.length; i++)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PhotoPager(urls: urls, start: i))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(big ? 16 : 10),
              child: _ChatImage(url: urls[i], width: size, height: height, cover: true),
            ),
          ),
      ],
    ),
  );
}

class _ChatImage extends StatelessWidget {
  const _ChatImage({required this.url, this.width, this.height, required this.cover});
  final String url;
  final double? width;
  final double? height;
  final bool cover;

  @override
  Widget build(BuildContext context) {
    final fit = cover ? BoxFit.cover : BoxFit.contain;
    return Image.network(
      photoUrl(url, width: 1200),
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: const Color(0xFFE7E1DC),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: _ink),
        ),
      ),
    );
  }
}

class _PhotoPager extends StatefulWidget {
  const _PhotoPager({required this.urls, required this.start});
  final List<String> urls;
  final int start;
  @override
  State<_PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<_PhotoPager> {
  late final PageController page = PageController(initialPage: widget.start);
  late int index = widget.start;

  @override
  void dispose() {
    page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${index + 1} / ${widget.urls.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: PageView.builder(
        controller: page,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(child: _ChatImage(url: widget.urls[i], cover: false)),
        ),
      ),
    );
  }
}

Widget _pickedPhoto(String path, VoidCallback clear) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: clear,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Color(0xFF14202B), shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

String _preview(MatchThread m) {
  if (m.messages.isEmpty) return m.dog.breed.isEmpty ? 'Tryck för att skriva' : m.dog.breed;
  final last = m.messages.last;
  if (last.recalled) return 'Meddelandet togs bort';
  return last.fromMe ? 'Du: ${chatPreview(last.text)}' : chatPreview(last.text);
}

DateTime _lastActivity(MatchThread m) {
  var latest = m.createdAt;
  for (final line in m.messages) {
    final at = line.createdAt;
    if (at != null && at.isAfter(latest)) latest = at;
  }
  return latest;
}

DateTime _groupActivity(GroupChat g) {
  var latest = DateTime.fromMillisecondsSinceEpoch(0);
  for (final line in g.messages) {
    final at = line.createdAt;
    if (at != null && at.isAfter(latest)) latest = at;
  }
  return latest;
}

class MatchesPage extends StatelessWidget {
  const MatchesPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      body: _Inbox(state: state),
    );
  }
}

class _Inbox extends StatelessWidget {
  const _Inbox({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.matches.where((m) => !m.accepted).toList();
    final seen = <String>{};
    final open = <MatchThread>[
      for (final m in state.matches.where((m) => m.accepted))
        if (m.peerEmail.isEmpty || seen.add(m.peerEmail.toLowerCase())) m,
    ];
    open.sort((a, b) => _lastActivity(b).compareTo(_lastActivity(a)));
    final groups = [...state.groups]..sort((a, b) => _groupActivity(b).compareTo(_groupActivity(a)));
    final items = <Widget>[
      if (state.incoming.isNotEmpty && state.isPremium) ...[
        const Text('Vill matcha med dig', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
        const SizedBox(height: 8),
        for (final m in state.incoming)
          Card(
            color: Theme.of(context).cardColor,
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
      if (state.incoming.isNotEmpty && !state.isPremium) ...[
        const Text('Vill matcha med dig', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
        const SizedBox(height: 8),
        Card(
          color: Theme.of(context).cardColor,
          child: ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Någon gillar din hund', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Premium visar vem, så du kan svara direkt.'),
            trailing: FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage(state: state))),
              child: const Text('Visa'),
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
      if (groups.isNotEmpty) ...[
        const Text('Grupper', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
        const SizedBox(height: 8),
        for (final g in groups)
          Card(
            color: Theme.of(context).cardColor,
            margin: const EdgeInsets.only(bottom: 8),
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
        const SizedBox(height: 8),
      ],
      const Text('Aktiva chattar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: _ink)),
      const SizedBox(height: 6),
      const Text('Tryck för att öppna. Papperskorgen raderar bara hos dig.', style: TextStyle(color: Color(0xFF3D4A57), fontSize: 13)),
      const SizedBox(height: 8),
      if (open.isEmpty) const Text('Inga godkända matcher än.', style: TextStyle(color: Color(0xFF3D4A57))),
      for (final m in open)
        Card(
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () {
              state.markRead(m);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(state: state, thread: m)));
            },
            leading: Badge(
              isLabelVisible: m.unread > 0,
              label: Text('${m.unread}'),
              child: const CircleAvatar(backgroundColor: _coral, child: Icon(Icons.pets, color: Colors.white)),
            ),
            title: Row(
              children: [
                Flexible(child: Text(m.dog.name, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                VerifiedMark(owner: m.dog.ownerVerified, dog: m.dog.dogVerified, size: 18),
              ],
            ),
            subtitle: Text(_preview(m), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFF8B3A32)),
              onPressed: () async {
                if (await _confirmDelete(context, m.dog.name)) state.deleteThread(m);
              },
            ),
          ),
        ),
    ];
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }
}

Future<void> _reportConversation(
  BuildContext context,
  AppState state, {
  required String matchId,
  required String peer,
  required bool group,
}) async {
  const reasons = ['Hot eller våld', 'Trakasserier', 'Olämpligt beteende', 'Annat'];
  final reason = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: _cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('Rapportera den här chatten', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          for (final r in reasons)
            ListTile(title: Text(r), onTap: () => Navigator.pop(ctx, r)),
        ],
      ),
    ),
  );
  if (reason == null) return;
  final log = await Network.chatLog(matchId, group: group);
  final decision = Moderation.review(log);
  var note = decision.note;
  if (decision.ban && decision.email.contains('@')) {
    final length = await Network.sanction(decision.email, decision.note, permanentNow: decision.permanent);
    if (length.isNotEmpty) note = '$note Åtgärd: $length.';
  }
  final reported = decision.email.isNotEmpty ? decision.email : peer;
  await Network.fileReport(
    state.email,
    state.fullName,
    reason,
    matchId: matchId,
    reportedEmail: reported,
    agentNote: note,
    kind: group ? 'grupp' : 'chatt',
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support har tagit emot rapporten och återkommer inom kort.')));
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

class _ChatPageState extends State<ChatPage> {
  final c = TextEditingController();
  final scroll = ScrollController();
  Timer? poll;
  bool _nearBottom = true;
  double _inset = 0;
  final List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (!scroll.hasClients) return;
      _nearBottom = scroll.offset < 140;
    });
    widget.state.markRead(widget.thread);
    widget.state.attachDeal(widget.thread);
    widget.state.refreshChat(widget.thread, markSeen: true);
    Fcm.readingChat(true);
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
      if (scroll.offset > 0) scroll.jumpTo(0);
    });
  }

  @override
  void dispose() {
    Fcm.readingChat(false);
    poll?.cancel();
    scroll.dispose();
    c.dispose();
    super.dispose();
  }

  Future<void> _stepAway(Future<dynamic> leave) async {
    await Fcm.readingChat(false);
    try {
      await leave;
    } finally {
      if (mounted) await Fcm.readingChat(true);
    }
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
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    if (inset != _inset) {
      _inset = inset;
      _follow();
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: GestureDetector(
          onTap: () => _stepAway(Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerPage(state: widget.state, dog: t.dog)))),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 190),
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: const Color(0xFFE7C7B4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFFFE0D4),
                  backgroundImage: t.dog.photoUrl.startsWith('http') ? NetworkImage(t.dog.photoUrl) : null,
                  child: t.dog.photoUrl.startsWith('http') ? null : Text((t.dog.name.isEmpty ? '?' : t.dog.name[0]).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _ink)),
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(t.dog.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink))),
                const Icon(Icons.chevron_right, size: 18, color: _ink),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Förhandla avtal',
            icon: const Icon(Icons.handshake_outlined, color: _coral),
            onPressed: () => _stepAway(DealSheet.open(context, widget.state, t).then((_) {
              if (mounted) setState(() {});
            })),
          ),
          IconButton(
            tooltip: 'Blockera',
            icon: const Icon(Icons.block, color: _ink),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Blockera?'),
                  content: Text('${t.dog.owner} och ${t.dog.name} syns inte igen, och chatten stängs.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Blockera')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await widget.state.blockPeer(t.dog);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          IconButton(
            tooltip: 'Rapportera chatten',
            icon: const Icon(Icons.flag_outlined, color: _coral),
            onPressed: () => _reportConversation(
              context,
              widget.state,
              matchId: t.cloudMatchId,
              peer: t.peerEmail,
              group: false,
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
          if (t.accepted)
            Material(
              color: const Color(0xFFFFE0D4),
              child: ListTile(
                leading: const Icon(Icons.handshake_outlined, color: _coral),
                title: Text(
                  t.deal == null
                      ? 'Tryck för att förhandla och signera avtal'
                      : t.deal!.fullySigned
                          ? 'Avtalet är signerat. Tryck för att öppna'
                          : t.deal!.signedByMe.isEmpty
                              ? 'Avtal att signera. Din tur'
                              : 'Du har signerat. Väntar på motpart',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
                ),
                trailing: const Icon(Icons.chevron_right, color: _coral),
                onTap: () => _stepAway(DealSheet.open(context, widget.state, t).then((_) {
                  if (mounted) setState(() {});
                })),
              ),
            ),
          Expanded(
            child: Builder(builder: (context) {
              final lines = _byTime(t.messages).where((m) => !_localDealNote(m)).toList();
              final signed = t.deal?.fullySigned == true;
              return ListView.builder(
                reverse: true,
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: lines.length + (signed ? 1 : 0),
                itemBuilder: (context, i) {
                  if (signed && i == 0) {
                    return _SignedDealCard(
                      onTap: () => _stepAway(DealSheet.open(context, widget.state, t).then((_) {
                        if (mounted) setState(() {});
                      })),
                    );
                  }
                  final offset = signed ? i - 1 : i;
                  final m = lines[lines.length - 1 - offset];
                  return TalkBubble(
                    line: m,
                    otherName: _personName(t),
                    onRecall: m.fromMe && !m.recalled && m.id.isNotEmpty && !m.system ? () => _recall(m) : null,
                  );
                },
              );
            }),
          ),
          Container(
            color: Theme.of(context).cardColor,
            padding: EdgeInsets.fromLTRB(12, 8, 8, MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_photos.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final path in List<String>.from(_photos))
                          _pickedPhoto(path, () => setState(() => _photos.remove(path))),
                      ],
                    ),
                  ),
                Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Bild',
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: _coral),
                  onPressed: !t.accepted
                      ? null
                      : () async {
                          final room = 5 - _photos.length;
                          if (room <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Högst 5 bilder.')));
                            return;
                          }
                          final paths = await Media.chooseUpTo(context, limit: room, title: 'Skicka bild');
                          if (!mounted || paths.isEmpty) return;
                          setState(() => _photos.addAll(paths.take(room)));
                        },
                ),
                Expanded(
                  child: TextField(
                    controller: c,
                    enabled: t.accepted,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: _ink, fontSize: 16, height: 1.25),
                    cursorColor: _coral,
                    decoration: InputDecoration(
                      hintText: t.accepted ? 'Skriv ett meddelande' : 'Väntar på match',
                      hintStyle: const TextStyle(color: Color(0xFF8A939C), fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFE4E1DC))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFE4E1DC))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFD7C8C0))),
                      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: Color(0xFFE4E1DC))),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _coral),
                  onPressed: !t.accepted
                      ? null
                      : () async {
                          final photos = List<String>.from(_photos);
                          final text = c.text.trim();
                          if (photos.isEmpty && text.isEmpty) return;
                          if (photos.isNotEmpty) {
                            setState(() => _photos.clear());
                            final ok = await widget.state.sendPhotos(t, photos);
                            if (!mounted) return;
                            if (!ok) {
                              setState(() => _photos.addAll(photos));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilden kunde inte skickas.')));
                              return;
                            }
                          }
                          if (text.isNotEmpty) {
                            widget.state.send(t, text);
                            c.clear();
                          }
                          if (mounted) {
                            setState(() {});
                            _follow(force: true);
                          }
                        },
                ),
              ],
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
  final List<String> _photos = [];

  bool atLatest = true;

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
    scroll.addListener(() {
      if (!scroll.hasClients) return;
      atLatest = scroll.offset < 140;
    });
    widget.state.markGroupRead(g);
    widget.state.refreshGroup(g);
    _jump(force: true);
    poll = Timer.periodic(const Duration(seconds: 1), (_) async {
      await widget.state.refreshGroup(g);
      widget.state.markGroupRead(g);
      if (mounted) setState(() {});
      _jump();
    });
  }

  void _jump({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scroll.hasClients) return;
      if (!force && !atLatest) return;
      if (scroll.offset > 0) scroll.jumpTo(0);
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Rapportera gruppen',
            icon: const Icon(Icons.flag_outlined, color: _coral),
            onPressed: () => _reportConversation(
              context,
              widget.state,
              matchId: group.id,
              peer: '',
              group: true,
            ),
          ),
          IconButton(icon: const Icon(Icons.group_outlined), onPressed: () => _members(context)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(builder: (context) {
              final lines = _byTime(group.messages);
              return ListView.builder(
                reverse: true,
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: lines.length,
                itemBuilder: (context, i) {
                  final m = lines[lines.length - 1 - i];
                  return TalkBubble(line: m, otherName: m.senderName.isEmpty ? 'Hundägaren' : m.senderName);
                },
              );
            }),
          ),
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_photos.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final path in List<String>.from(_photos))
                          _pickedPhoto(path, () => setState(() => _photos.remove(path))),
                      ],
                    ),
                  ),
                Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Bild',
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: _coral),
                  onPressed: () async {
                    final room = 5 - _photos.length;
                    if (room <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Högst 5 bilder.')));
                      return;
                    }
                    final paths = await Media.chooseUpTo(context, limit: room, title: 'Skicka bild');
                    if (!mounted || paths.isEmpty) return;
                    setState(() => _photos.addAll(paths.take(room)));
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: c,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Skriv till gruppen',
                      filled: true,
                      fillColor: _cream,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: _coral),
                  onPressed: () async {
                    final photos = List<String>.from(_photos);
                    final text = c.text.trim();
                    if (photos.isEmpty && text.isEmpty) return;
                    if (photos.isNotEmpty) {
                      setState(() => _photos.clear());
                      final ok = await widget.state.sendGroupPhotos(group, photos);
                      if (!mounted) return;
                      if (!ok) {
                        setState(() => _photos.addAll(photos));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bilden kunde inte skickas.')));
                        return;
                      }
                    }
                    if (text.isNotEmpty) {
                      widget.state.sendGroup(group, text);
                      c.clear();
                    }
                    if (mounted) {
                      setState(() {});
                      _jump(force: true);
                    }
                  },
                ),
              ],
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
