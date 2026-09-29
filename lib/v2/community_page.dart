import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Promenad Hornstull', 'Stockholm · sön 10:00', Icons.directions_walk),
      ('Hundcafé Vasastan', 'Stockholm · lör 14:00', Icons.coffee_outlined),
      ('Rastgård Rålambshov', 'Öppen nu', Icons.park_outlined),
      ('Uppfödarträff', 'Göteborg · 12 okt', Icons.groups_outlined),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(title: const Text('Community'), backgroundColor: Colors.transparent),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final e = items[i];
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFFFE4DF), child: Icon(e.$3, color: const Color(0xFFE25C3A))),
              title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(e.$2),
              trailing: const Text('Gå med', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE25C3A))),
            ),
          );
        },
      ),
    );
  }
}
