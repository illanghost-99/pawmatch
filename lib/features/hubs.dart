import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_state.dart';
import '../v2/ai_vet_page.dart';
import '../v2/community_page.dart';
import '../v2/health_page.dart';
import '../v2/pedigree_page.dart';
import '../v2/verify_page.dart';
import 'legal.dart';
import 'support.dart';

const _cream = Color(0xFFFFF4EC);

class _Row {
  const _Row(this.color, this.icon, this.title, this.sub, this.open);
  final Color color;
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback open;
}

class HubPage extends StatelessWidget {
  const HubPage({super.key, required this.title, required this.rows});
  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows)
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: r.color.withValues(alpha: 0.14), child: Icon(r.icon, color: r.color)),
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(r.sub),
                trailing: const Icon(Icons.chevron_right),
                onTap: r.open,
              ),
            ),
        ],
      ),
    );
  }
}

void openSupportHub(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HubPage(
        title: 'Kundtjänst',
        rows: [
          _Row(const Color(0xFFE25C3A), Icons.smart_toy_outlined, 'AI-chatt', 'Svar dygnet runt om appen', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
          }),
          _Row(const Color(0xFF2A9D8F), Icons.mail_outline, 'E-post', 'support@pawmatch.app', () async {
            final uri = Uri(scheme: 'mailto', path: 'support@pawmatch.app', queryParameters: {'subject': 'PawMatch'});
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }),
          _Row(const Color(0xFF3D5A80), Icons.phone_outlined, 'Telefon', 'Kommer när supportlinjen är öppen', () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mejla support@pawmatch.app så länge.')));
          }),
        ],
      ),
    ),
  );
}

void openDogHub(BuildContext context, AppState state) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HubPage(
        title: 'Hund och hälsa',
        rows: [
          _Row(const Color(0xFF1F7A6C), Icons.monitor_heart_outlined, 'Hälsotidslinje', 'Vaccin, vikt, besök', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthPage()));
          }),
          _Row(const Color(0xFF6B4C9A), Icons.account_tree_outlined, 'Stamtavla', 'SKK och dokument', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PedigreePage()));
          }),
          _Row(const Color(0xFF2A9D8F), Icons.groups_2_outlined, 'Community', 'Promenader och träffar', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPage()));
          }),
          _Row(const Color(0xFF3D5A80), Icons.health_and_safety_outlined, 'AI Vet', 'Sammanfattar — inte veterinär', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AiVetPage()));
          }),
          _Row(const Color(0xFF14202B), Icons.verified_outlined, 'Verifiering', 'E-post, telefon och intyg', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyPage()));
          }),
        ],
      ),
    ),
  );
}

void openLegalHub(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => HubPage(
        title: 'Villkor',
        rows: [
          _Row(const Color(0xFF3D5A80), Icons.description_outlined, 'Användarvillkor', 'Regler för appen', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Villkor', body: kTerms)));
          }),
          _Row(const Color(0xFF6B4C9A), Icons.privacy_tip_outlined, 'Integritet', 'Så hanterar vi dina uppgifter', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Integritet', body: kPrivacy)));
          }),
          _Row(const Color(0xFFE9C46A), Icons.groups_outlined, 'Communityregler', 'Så här är vi mot varandra', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalPage(title: 'Community', body: kCommunity)));
          }),
        ],
      ),
    ),
  );
}
