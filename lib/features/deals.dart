import 'package:flutter/material.dart';
import '../app_state.dart';
import 'deal.dart';

class DealsPage extends StatelessWidget {
  const DealsPage({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final list = state.deals;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(
        title: const Text('Mina avtal', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
      ),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Inga avtal än. När du förhandlar i en avelschatt hamnar avtalet här.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final t = list[i];
                final d = t.deal!;
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFE25C3A), child: Icon(Icons.description, color: Colors.white)),
                    title: Text('${d.partyA} × ${d.partyB}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      '${t.dog.name} · ${d.pricePerPuppy} kr/valp · ${d.signedByMe.isEmpty ? 'Ej signerat' : 'Signerat'}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => DealSheet.open(context, state, t),
                  ),
                );
              },
            ),
    );
  }
}
