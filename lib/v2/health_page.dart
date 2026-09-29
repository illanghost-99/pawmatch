import 'package:flutter/material.dart';

class HealthEvent {
  HealthEvent(this.title, this.when, this.kind);
  final String title;
  final DateTime when;
  final String kind;
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});
  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final events = <HealthEvent>[
    HealthEvent('Grundvaccination', DateTime(2025, 4, 12), 'vaccin'),
    HealthEvent('Avmaskning', DateTime(2025, 6, 2), 'behandling'),
    HealthEvent('Vikt 4.2 kg', DateTime(2026, 1, 20), 'vikt'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(title: const Text('Hälsotidslinje'), backgroundColor: Colors.transparent),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE25C3A),
        onPressed: () {
          setState(() => events.insert(0, HealthEvent('Ny anteckning', DateTime.now(), 'anteckning')));
        },
        label: const Text('Lägg till'),
        icon: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final e = events[i];
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFFFE4DF),
                child: Icon(
                  e.kind == 'vaccin'
                      ? Icons.vaccines_outlined
                      : e.kind == 'vikt'
                          ? Icons.monitor_weight_outlined
                          : Icons.healing_outlined,
                  color: const Color(0xFFE25C3A),
                ),
              ),
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('${e.when.year}-${e.when.month.toString().padLeft(2, '0')}-${e.when.day.toString().padLeft(2, '0')} · ${e.kind}'),
            ),
          );
        },
      ),
    );
  }
}
