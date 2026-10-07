import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../models.dart';
import '../services/fcm.dart';
import '../services/moderator.dart';
import '../services/network.dart';

const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);
const _coral = Color(0xFFE25C3A);

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.state});
  final AppState state;
  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in const [(0, 'Rapporter'), (1, 'Hundar'), (2, 'Konton'), (3, 'Team'), (4, 'Notiser')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(item.$2),
                        selected: tab == item.$1,
                        onSelected: (_) => setState(() => tab = item.$1),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: switch (tab) {
              1 => _Dogs(state: widget.state),
              2 => _Accounts(state: widget.state),
              3 => _Team(email: widget.state.email),
              4 => _PushLab(email: widget.state.email),
              _ => _Reports(state: widget.state),
            },
          ),
        ],
      ),
    );
  }
}

class _Reports extends StatefulWidget {
  const _Reports({required this.state});
  final AppState state;
  @override
  State<_Reports> createState() => _ReportsState();
}

class _ReportsState extends State<_Reports> {
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await Network.allReports();
    if (!mounted) return;
    setState(() {
      rows = list;
      loading = false;
    });
  }

  Future<void> _reply(Map<String, dynamic> row) async {
    final c = TextEditingController(text: '${row['reply'] ?? ''}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${row['from_name'] ?? 'Användare'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${row['body'] ?? ''}', style: const TextStyle(height: 1.35)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Ditt svar'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stäng')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Skicka svar')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await Network.replyReport('${row['id']}', c.text.trim());
      await _load();
    }
    c.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _coral));
    final waiting = rows.where((r) => ('${r['reply'] ?? ''}').trim().isEmpty).length;
    final done = rows.length - waiting;
    final chats = rows.where((r) => '${r['kind'] ?? ''}' == 'chatt' || '${r['kind'] ?? ''}' == 'grupp').length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: rows.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Stat(label: 'Väntar', value: waiting, color: _coral, delay: 0),
                    const SizedBox(width: 8),
                    _Stat(label: 'Besvarade', value: done, color: const Color(0xFF1F8A4C), delay: 120),
                    const SizedBox(width: 8),
                    _Stat(label: 'Chattar', value: chats, color: const Color(0xFF2F80ED), delay: 240),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Tryck på ett ärende. Då ser du vad som hänt och hela chatten.', style: TextStyle(color: Color(0xFF3D4A57), height: 1.35)),
                const SizedBox(height: 8),
                if (rows.isEmpty) const Padding(padding: EdgeInsets.only(top: 24), child: Text('Inga rapporter än.')),
              ],
            );
          }
          final r = rows[i - 1];
          final number = r['case_no'] ?? r['id'];
          final answered = ('${r['reply'] ?? ''}').trim().isNotEmpty;
          return Card(
            color: Colors.white,
            child: ListTile(
              title: Text('Ärende $number', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${r['kind'] ?? 'problem'} · ${r['body'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: answered ? const Color(0xFFE5F6EC) : const Color(0xFFFFE0D4),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(answered ? 'Klar' : 'Ny', style: TextStyle(color: answered ? const Color(0xFF1F8A4C) : _coral, fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => CasePage(row: r)));
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}

class _Dogs extends StatefulWidget {
  const _Dogs({required this.state});
  final AppState state;
  @override
  State<_Dogs> createState() => _DogsState();
}

class _DogsState extends State<_Dogs> {
  final q = TextEditingController();
  List<DogProfile> hits = [];
  bool busy = false;

  Future<void> _search() async {
    setState(() => busy = true);
    final list = await Network.searchDogs(q.text);
    if (!mounted) return;
    setState(() {
      hits = list;
      busy = false;
    });
  }

  Future<void> _open(DogProfile d) async {
    var owner = d.ownerVerified;
    var dog = d.dogVerified;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text('${d.owner} · ${d.ownerEmail}', style: const TextStyle(color: Color(0xFF3D4A57))),
                const SizedBox(height: 8),
                Text('${d.breed} · ${d.sexLabel} · ${d.weightLabel} · ${d.city}'),
                if (d.bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(d.bio)),
                if (d.pedigreeNote.isNotEmpty) Text('Stamtavla: ${d.pedigreeNote}'),
                if (d.vaccineNote.isNotEmpty) Text('Vaccin: ${d.vaccineNote}'),
                if (d.healthNote.isNotEmpty) Text('Hälsa: ${d.healthNote}'),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Verifiera hundägaren', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Blå V på profil och hund.'),
                  value: owner,
                  activeThumbColor: const Color(0xFF2F80ED),
                  onChanged: (v) => setLocal(() => owner = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Verifiera hunden', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Tillsammans med ägaren blir märket grönt.'),
                  value: dog,
                  activeThumbColor: const Color(0xFF1F8A4C),
                  onChanged: (v) => setLocal(() => dog = v),
                ),
                FilledButton(
                  onPressed: () async {
                    await Network.verifyOwner(d.ownerEmail, owner);
                    await Network.verifyDog(d.id, dog);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Spara'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: q,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: 'Namn, ras eller e-post',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(onPressed: busy ? null : _search, icon: const Icon(Icons.search, color: _coral)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: hits.length,
            itemBuilder: (_, i) {
              final d = hits[i];
              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink)),
                  subtitle: Text('${d.owner} · ${d.breed}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(d),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color, required this.delay});
  final String label;
  final int value;
  final Color color;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 500 + delay),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Opacity(opacity: t.clamp(0, 1), child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: Column(
            children: [
              Text('$value', style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: Color(0xFF3D4A57), fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class CasePage extends StatefulWidget {
  const CasePage({super.key, required this.row});
  final Map<String, dynamic> row;
  @override
  State<CasePage> createState() => _CasePageState();
}

class _CasePageState extends State<CasePage> {
  final reply = TextEditingController();
  List<({String email, String text})> log = [];
  String note = '';
  String suggestion = '';
  bool loading = true;

  String get _reporter => '${widget.row['from_email'] ?? ''}'.toLowerCase();

  String _suggestionFor(String agentNote) {
    return Moderation.suggestReply(reason: '${widget.row['body'] ?? ''}', note: agentNote);
  }

  @override
  void initState() {
    super.initState();
    note = '${widget.row['agent_note'] ?? ''}';
    suggestion = _suggestionFor(note);
    final sent = '${widget.row['reply'] ?? ''}'.trim();
    reply.text = sent.isEmpty ? suggestion : sent;
    _load();
  }

  Future<void> _load() async {
    final id = '${widget.row['match_id'] ?? ''}';
    final group = '${widget.row['kind'] ?? ''}' == 'grupp';
    final lines = id.isEmpty ? <({String email, String text})>[] : await Network.chatLog(id, group: group);
    if (!mounted) return;
    setState(() {
      log = lines;
      loading = false;
    });
  }

  Future<void> _review() async {
    final decision = Moderation.review(log);
    var text = decision.note;
    if (decision.ban && decision.email.contains('@')) {
      final length = await Network.sanction(decision.email, decision.note, permanentNow: decision.permanent);
      if (length.isNotEmpty) text = '$text Åtgärd: $length.';
    }
    final next = _suggestionFor(text);
    if (!mounted) return;
    setState(() {
      if (reply.text.trim().isEmpty || reply.text.trim() == suggestion) reply.text = next;
      note = text;
      suggestion = next;
    });
  }

  String _who(String email) {
    if (email == _reporter) return 'Den som rapporterade';
    if (email.isEmpty) return 'Okänd';
    final name = email.split('@').first;
    return name.isEmpty ? email : name;
  }

  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.row['case_no'] ?? widget.row['id'];
    final reported = '${widget.row['reported_email'] ?? ''}';
    final calm = note.contains('inget tydligt') || note.isEmpty;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(title: Text('Ärende $number', style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.row['kind'] ?? 'Ärende'} · ${widget.row['body'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text('Rapporterat av ${widget.row['from_name'] ?? _reporter}', style: const TextStyle(color: Color(0xFF3D4A57))),
                if (reported.isNotEmpty) Text('Gäller $reported', style: const TextStyle(color: Color(0xFF3D4A57))),
                if ('${widget.row['kind'] ?? ''}' == 'samtal')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FilledButton.icon(
                      onPressed: () async {
                        final match = RegExp(r'(\+?\d[\d\s\-]{6,})').firstMatch('${widget.row['body'] ?? ''}');
                        final raw = (match?.group(0) ?? '').replaceAll(RegExp(r'[^\d+]'), '');
                        if (raw.length < 8) return;
                        await launchUrl(Uri(scheme: 'tel', path: raw));
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Ring användaren'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: calm ? const Color(0xFFE5F6EC) : const Color(0xFFFFE0D4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              note.isEmpty ? 'Assistenten har inte läst chatten än.' : note,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35, color: _ink),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: log.isEmpty ? null : _review, child: const Text('Låt assistenten läsa')),
              if (reported.contains('@')) TextButton(onPressed: () => Network.liftBan(reported), child: const Text('Häv avstängning')),
            ],
          ),
          const SizedBox(height: 18),
          const Text('Chatten', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const Text('Vänster är den som rapporterade. Höger är den andra.', style: TextStyle(color: Color(0xFF3D4A57), fontSize: 13)),
          const SizedBox(height: 8),
          if (loading) const LinearProgressIndicator(),
          if (!loading && log.isEmpty) const Text('Det här ärendet har ingen chatt kopplad.'),
          for (final line in log)
            Align(
              alignment: line.email == _reporter ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: line.email == _reporter ? Colors.white : _coral,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_who(line.email), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: line.email == _reporter ? const Color(0xFF5C6B78) : Colors.white70)),
                    const SizedBox(height: 2),
                    Text(line.text, style: TextStyle(color: line.email == _reporter ? _ink : Colors.white, height: 1.3)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text('Svar till den som rapporterade', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 4),
          const Text('Förslaget ligger redan i rutan. Skicka det, eller skriv om det först.', style: TextStyle(color: Color(0xFF3D4A57), height: 1.35)),
          const SizedBox(height: 8),
          TextField(
            controller: reply,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => setState(() => reply.text = suggestion),
            child: const Text('Lägg tillbaka förslaget'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              if (reply.text.trim().isEmpty) return;
              await Network.replyReport('${widget.row['id']}', reply.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Skicka svaret'),
          ),
        ],
      ),
    );
  }
}

class _Accounts extends StatefulWidget {
  const _Accounts({required this.state});
  final AppState state;
  @override
  State<_Accounts> createState() => _AccountsState();
}

class _AccountsState extends State<_Accounts> {
  final q = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String note = '';

  Future<void> _load() async {
    final list = await Network.adminAccounts();
    if (!mounted) return;
    final full = list.any((r) => '${r['created'] ?? ''}'.isNotEmpty);
    setState(() {
      rows = list;
      note = full ? '' : 'Listan visar bara konton med en hund tills funktionen admin-accounts är uppladdad.';
      loading = false;
    });
  }

  List<Map<String, dynamic>> get shown {
    final text = q.text.trim().toLowerCase();
    if (text.isEmpty) return rows;
    return rows.where((r) => '${r['name']} ${r['email']}'.toLowerCase().contains(text)).toList();
  }

  Future<void> _act(Map<String, dynamic> row, String mode) async {
    final name = '${row['name']}';
    final word = switch (mode) {
      'on' => 'aktivera',
      'off' => 'avaktivera',
      'closed' => 'stänga',
      _ => 'radera',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${word[0].toUpperCase()}${word.substring(1)} $name?'),
        content: Text(switch (mode) {
          'off' => 'Hunden och kontot döljs i appen. Ingenting raderas. Aktivera igen så kommer de tillbaka.',
          'on' => 'Hunden och kontot syns i appen igen.',
          'closed' => 'Kontot stängs och hunden döljs tills du aktiverar det igen.',
          _ => 'Personen ser ändringen nästa gång appen öppnas.',
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ja')),
        ],
      ),
    );
    if (ok != true) return;
    await Network.setAccount('${row['email']}', mode);
    await _load();
  }

  @override
  void dispose() {
    q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _coral));
    final list = shown;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: q,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Sök namn eller e-post', filled: true, fillColor: Colors.white),
          ),
        ),
        if (note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(note, style: const TextStyle(color: Color(0xFF3D4A57), height: 1.3)),
          ),
        Expanded(
          child: list.isEmpty
              ? const Center(child: Text('Inga konton hittades.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final r = list[i];
                    final dogs = (r['dogs'] as List?)?.join(', ') ?? '';
                    final status = '${r['status'] ?? 'Aktiv'}';
                    final photos = int.tryParse('${r['photos'] ?? 0}') ?? 0;
                    return Card(
                      color: Colors.white,
                      child: ListTile(
                        title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text('${r['email']}${dogs.isEmpty ? '' : '\n$dogs'}${photos > 0 ? '\n$photos bilder' : ''}'),
                        isThreeLine: dogs.isNotEmpty || photos > 0,
                        trailing: Text(status, style: TextStyle(color: status == 'Aktiv' ? const Color(0xFF1F8A4C) : _coral, fontWeight: FontWeight.w800)),
                        onTap: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('${r['email']}')),
                                ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text('Aktivera'), onTap: () { Navigator.pop(ctx); _act(r, 'on'); }),
                                ListTile(leading: const Icon(Icons.pause_circle_outline), title: const Text('Avaktivera'), onTap: () { Navigator.pop(ctx); _act(r, 'off'); }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Team extends StatefulWidget {
  const _Team({required this.email});
  final String email;
  @override
  State<_Team> createState() => _TeamState();
}

class _TeamState extends State<_Team> {
  List<String> people = [];
  String fresh = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await Network.admins();
    if (!mounted) return;
    setState(() {
      people = list;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: _coral));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const Text('Skapa en kod och skicka den till personen. Hen trycker sju gånger på PawMatch i profilen och skriver in koden. Koden fungerar en gång.', style: TextStyle(height: 1.35, color: Color(0xFF3D4A57))),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final code = await Network.createInvite(widget.email);
            if (!mounted) return;
            setState(() => fresh = code.isEmpty ? 'Kunde inte skapa koden. Kör SQL:en först.' : code);
          },
          child: const Text('Skapa inbjudningskod'),
        ),
        if (fresh.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(fresh, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
        const SizedBox(height: 18),
        const Text('Admins', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        for (final email in people)
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(email),
              subtitle: Text(email == 'dilanahanna@hotmail.com' ? 'Ägare' : 'Admin'),
              trailing: email == 'dilanahanna@hotmail.com' || email == widget.email.toLowerCase()
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () async {
                        await Network.revokeAdmin(email);
                        _load();
                      },
                    ),
            ),
          ),
      ],
    );
  }
}

class _PushLab extends StatefulWidget {
  const _PushLab({required this.email});
  final String email;
  @override
  State<_PushLab> createState() => _PushLabState();
}

class _PushLabState extends State<_PushLab> {
  Map<String, String> info = {};
  int devices = -1;
  List<String> notes = [];
  String send = '';
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => busy = true);
    final next = await Fcm.diagnose();
    final count = await Network.deviceCount(widget.email);
    final log = await Network.recentPushNotes(widget.email);
    var code = next['code'] ?? 'OKAND';
    if (code == 'TOKEN_OK' && count == 0) code = 'DB_EMPTY';
    if (code == 'TOKEN_OK' && count < 0) code = 'DB_FAIL';
    next['code'] = code;
    next['devices'] = '$count';
    if (!mounted) return;
    setState(() {
      info = next;
      devices = count;
      notes = log;
      busy = false;
    });
  }

  Future<void> _send() async {
    setState(() => busy = true);
    final result = await Network.pingReport(widget.email);
    var code = info['code'] ?? '';
    if (result.contains('"sent":1') || result.contains('sent: 1')) code = 'SEND_1';
    if (result.contains('"sent":0') || result.contains('sent: 0')) code = 'SEND_0';
    if (!mounted) return;
    setState(() {
      send = result;
      info = {...info, 'code': code, 'send': result};
      busy = false;
    });
  }

  String get _report {
    return [
      'PawMatch notistest',
      'konto: ${widget.email}',
      'felkod: ${info['code'] ?? ''}',
      'tillstånd: ${info['permission'] ?? ''}',
      'apple-nyckel: ${info['apns'] ?? ''}',
      'firebase-nyckel: ${info['fcm'] ?? ''} ${info['fcm_start'] ?? ''}',
      'sparade telefoner: $devices',
      'firebase-projekt: ${info['project'] ?? ''}',
      'bundle: ${info['bundle'] ?? ''}',
      'firebase-appar: ${info['firebase_apps'] ?? ''}',
      'senaste fel: ${info['last_error'] ?? ''}',
      'apns-fel: ${info['apns_error'] ?? ''}',
      'fcm-fel: ${info['fcm_error'] ?? ''}',
      'skickat: $send',
      'logg:',
      ...notes,
    ].join('\n');
  }

  String get _meaning {
    switch (info['code']) {
      case 'PERMISSION_DENIED':
        return 'iPhone har blockerat notiser. Gå till Inställningar, PawMatch, Aviseringar och tillåt.';
      case 'APNS_NULL':
        return 'Apple gav ingen notisnyckel. Felet sitter i Xcode eller i .p8-nyckeln i Firebase, inte i chatten.';
      case 'FCM_NULL':
        return 'Apple svarade, men Firebase gav ingen nyckel. Bundle-id måste vara app.pawmatch.';
      case 'DB_EMPTY':
        return 'Nyckeln finns i telefonen men sparades inte. Servern har ingen telefon att skicka till.';
      case 'DB_FAIL':
        return 'Kunde inte läsa sparade telefoner. Kopiera texten och skicka den.';
      case 'TOKEN_OK':
        return 'Telefonen är registrerad. Skicka en testnotis, stäng appen och vänta.';
      case 'SEND_0':
        return 'Servern körde men hittade ingen telefon. Svaret är sent 0.';
      case 'SEND_1':
        return 'Servern skickade. Kolla låsskärmen. Syns inget är det Apple som stoppar leveransen.';
      case 'FIREBASE_FAIL':
        return 'Firebase startade inte. Feltexten nedan är den viktiga.';
      default:
        return 'Kör testet och kopiera texten.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = info['code'] ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(code.isEmpty ? 'Läser…' : code, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _coral)),
        const SizedBox(height: 8),
        Text(_meaning, style: const TextStyle(height: 1.35, color: Color(0xFF3D4A57))),
        const SizedBox(height: 14),
        _line('Tillstånd', info['permission'] ?? ''),
        _line('Apple-nyckel', info['apns'] ?? ''),
        _line('Firebase-nyckel', '${info['fcm'] ?? ''} ${info['fcm_start'] ?? ''}'.trim()),
        _line('Sparade telefoner', devices < 0 ? 'kunde inte läsa' : '$devices'),
        _line('Projekt', info['project'] ?? ''),
        _line('Bundle', info['bundle'] ?? ''),
        if ((info['last_error'] ?? '').isNotEmpty) _line('Senaste fel', info['last_error'] ?? ''),
        if ((info['apns_error'] ?? '').isNotEmpty) _line('Apple-fel', info['apns_error'] ?? ''),
        if ((info['fcm_error'] ?? '').isNotEmpty) _line('Firebase-fel', info['fcm_error'] ?? ''),
        if (send.isNotEmpty) _line('Serversvar', send),
        const SizedBox(height: 8),
        FilledButton(onPressed: busy ? null : _run, child: const Text('Kör testet igen')),
        const SizedBox(height: 8),
        FilledButton(onPressed: busy ? null : _send, child: const Text('Skicka testnotis till den här telefonen')),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: _report));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopierat. Klistra in det i chatten.')));
          },
          child: const Text('Kopiera allt'),
        ),
        const SizedBox(height: 16),
        const Text('Senaste loggen', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        if (notes.isEmpty) const Text('Ingen logg ännu.'),
        for (final line in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(line, style: const TextStyle(fontSize: 12, color: Color(0xFF3D4A57))),
          ),
      ],
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _ink))),
          Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(color: _ink))),
        ],
      ),
    );
  }
}




