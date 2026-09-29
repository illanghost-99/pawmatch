import 'package:flutter/material.dart';
import 'ai_vet.dart';

class AiVetPage extends StatefulWidget {
  const AiVetPage({super.key});
  @override
  State<AiVetPage> createState() => _AiVetPageState();
}

class _Msg {
  const _Msg(this.me, this.text);
  final bool me;
  final String text;
}

class _AiVetPageState extends State<AiVetPage> {
  final ask = TextEditingController();
  final msgs = <_Msg>[
    const _Msg(false, AiVet.disclaimer),
  ];

  void _send() {
    final t = ask.text.trim();
    if (t.isEmpty) return;
    setState(() {
      msgs.add(_Msg(true, t));
      msgs.add(_Msg(false, AiVet.reply(t)));
      ask.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(title: const Text('AI Vet'), backgroundColor: Colors.transparent),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFE7F0EA), borderRadius: BorderRadius.circular(14)),
            child: const Text('Sammanfattar information. Ersätter inte veterinär.', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final m = msgs[i];
                return Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 340),
                    decoration: BoxDecoration(
                      color: m.me ? const Color(0xFF1F7A6C) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.me ? Colors.white : const Color(0xFF14202B), height: 1.35)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ask,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Fråga om vaccin, journal eller DNA…',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(onPressed: _send, icon: const Icon(Icons.send_rounded, color: Color(0xFF1F7A6C))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
