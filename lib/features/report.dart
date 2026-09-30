import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/network.dart';

const _cream = Color(0xFFFFF4EC);
const _ink = Color(0xFF14202B);
const _coral = Color(0xFFE25C3A);

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.state});
  final AppState state;
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final text = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool sent = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await Network.myReports(widget.state.email);
    if (mounted) setState(() => rows = list);
  }

  Future<void> _send() async {
    if (busy || text.text.trim().isEmpty) return;
    setState(() => busy = true);
    final ok = await Network.fileReport(widget.state.email, widget.state.fullName, text.text);
    if (!mounted) return;
    setState(() {
      busy = false;
      sent = ok;
    });
    if (ok) {
      text.clear();
      await _load();
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(title: const Text('Rapportera', style: TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text('Beskriv vad som inte fungerar. Support läser det och svarar här.', style: TextStyle(color: Color(0xFF3D4A57), height: 1.35)),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Vad hände?',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _coral, minimumSize: const Size.fromHeight(50)),
            onPressed: busy ? null : _send,
            child: Text(busy ? 'Skickar…' : 'Skicka rapport'),
          ),
          if (sent) ...[
            const SizedBox(height: 12),
            const Text('Support har tagit emot din rapport och återkommer inom kort.', style: TextStyle(fontWeight: FontWeight.w700, color: _ink, height: 1.35)),
          ],
          const SizedBox(height: 20),
          const Text('Dina rapporter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          if (rows.isEmpty) const Text('Inga rapporter än.', style: TextStyle(color: Color(0xFF3D4A57))),
          for (final r in rows)
            Card(
              color: Colors.white,
              child: ListTile(
                title: Text('${r['body'] ?? ''}', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(('${r['reply'] ?? ''}').trim().isEmpty ? 'Väntar på svar från support.' : 'Support: ${r['reply']}'),
              ),
            ),
        ],
      ),
    );
  }
}
