import 'package:flutter/material.dart';
import 'verification.dart';

class VerifyPage extends StatelessWidget {
  const VerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4EC),
      appBar: AppBar(title: const Text('Verifiering'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final l in VerifyLevel.values)
            Card(
              color: Colors.white,
              child: ListTile(
                leading: CircleAvatar(child: Text('${l.rank}')),
                title: Text(l.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(l.hint),
              ),
            ),
        ],
      ),
    );
  }
}
