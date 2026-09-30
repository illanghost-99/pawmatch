import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
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
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Rapporter')),
                ButtonSegment(value: 1, label: Text('Hundar')),
              ],
              selected: {tab},
              onSelectionChanged: (v) => setState(() => tab = v.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: tab == 0 ? _Reports(state: widget.state) : _Dogs(state: widget.state)),
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
    if (rows.isEmpty) return const Center(child: Text('Inga rapporter än.'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: rows.length,
        itemBuilder: (_, i) {
          final r = rows[i];
          final number = r['case_no'] ?? r['id'];
          final answered = ('${r['reply'] ?? ''}').trim().isNotEmpty;
          return Card(
            color: Colors.white,
            child: ListTile(
              title: Text('Ärende $number', style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${r['kind'] ?? 'problem'} · ${r['body'] ?? ''}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Icon(answered ? Icons.mark_email_read : Icons.mark_email_unread, color: answered ? const Color(0xFF1F8A4C) : _coral),
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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    reply.text = '${widget.row['reply'] ?? ''}';
    note = '${widget.row['agent_note'] ?? ''}';
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
    if (mounted) setState(() => note = text);
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
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(title: Text('Ärende $number', style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Från ${widget.row['from_name'] ?? widget.row['from_email']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${widget.row['body'] ?? ''}', style: const TextStyle(height: 1.35)),
          if (reported.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Gäller $reported')),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(note, style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: log.isEmpty ? null : _review, child: const Text('Låt assistenten läsa')),
              if (reported.contains('@')) TextButton(onPressed: () => Network.liftBan(reported), child: const Text('Häv avstängning')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Chatten', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          if (loading) const LinearProgressIndicator(),
          if (!loading && log.isEmpty) const Text('Ingen chatt är kopplad till det här ärendet.'),
          for (final line in log)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.email, style: const TextStyle(fontSize: 12, color: Color(0xFF5C6B78), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(line.text, style: const TextStyle(color: _ink, height: 1.3)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: reply,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Svar till den som rapporterade', filled: true, fillColor: Colors.white),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              if (reply.text.trim().isEmpty) return;
              await Network.replyReport('${widget.row['id']}', reply.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Skicka svar'),
          ),
        ],
      ),
    );
  }
}

