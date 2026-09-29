import 'package:flutter/material.dart';
import '../app_state.dart';
import 'circle_models.dart';
import 'premium_page.dart';

class CirclesPage extends StatelessWidget {
  const CirclesPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(
        title: const Text('Cirklar'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              if (!state.isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage(state: state)));
                return;
              }
              _create(context);
            },
          ),
        ],
      ),
      body: state.circles.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Promenadcirklar', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    state.isPremium
                        ? 'Skapa en grupp, bjud in matchningar och planera promenader.'
                        : 'Gratis: du kan bli inbjuden. Premium: skapa och leda cirklar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A)),
                    onPressed: () {
                      if (!state.isPremium) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage(state: state)));
                        return;
                      }
                      _create(context);
                    },
                    child: Text(state.isPremium ? 'Skapa cirkel' : 'Lås upp med Premium'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final c in state.circles)
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFFFE4DF), child: Icon(Icons.groups, color: Color(0xFFE25C3A))),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${c.members.length} medlemmar · ${c.walkPlan.isEmpty ? 'Ingen promenad planerad' : c.walkPlan}'),
                      onTap: () => _open(context, c),
                    ),
                  ),
              ],
            ),
    );
  }

  void _create(BuildContext context) {
    final name = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Namn på cirkeln')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                state.addCircle(name.text.trim());
                Navigator.pop(ctx);
              },
              child: const Text('Skapa'),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, WalkCircle c) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => _CircleChat(state: state, circle: c)));
  }
}

class _CircleChat extends StatelessWidget {
  const _CircleChat({required this.state, required this.circle});
  final AppState state;
  final WalkCircle circle;

  @override
  Widget build(BuildContext context) {
    final text = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text(circle.name)),
      body: Column(
        children: [
          if (state.isPremium)
            ListTile(
              title: const Text('Redigera som ägare'),
              subtitle: const Text('Lägg till, ta bort, bakgrund'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                final plan = TextEditingController(text: circle.walkPlan);
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: plan, decoration: const InputDecoration(labelText: 'Nästa promenad')),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: () {
                            circle.walkPlan = plan.text.trim();
                            state.bump();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Spara'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in circle.messages)
                  Align(
                    alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: m.fromMe ? const Color(0xFFE25C3A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(m.text, style: TextStyle(color: m.fromMe ? Colors.white : Colors.black87)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: TextField(controller: text, decoration: const InputDecoration(hintText: 'Skriv till cirkeln'))),
                IconButton(
                  onPressed: () {
                    if (text.text.trim().isEmpty) return;
                    state.sendCircle(circle, text.text.trim());
                    text.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
