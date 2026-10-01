import 'dart:io';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/network.dart';
import '../v2/premium_page.dart';
import 'admin_page.dart';
import 'deals.dart';
import 'edit_profile.dart';
import 'hubs.dart';
import 'my_dogs.dart';
import 'report.dart';
import 'settings.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.state});
  final AppState state;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int taps = 0;
  DateTime tapped = DateTime.fromMillisecondsSinceEpoch(0);
  bool admin = false;

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    Network.isAdmin(state.email).then((v) {
      if (mounted) setState(() => admin = v);
    });
    state.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    state.removeListener(_tick);
    super.dispose();
  }

  Future<void> _secret() async {
    final now = DateTime.now();
    if (now.difference(tapped) > const Duration(seconds: 4)) taps = 0;
    tapped = now;
    taps++;
    if (taps < 7) return;
    taps = 0;
    if (await Network.isAdmin(state.email)) {
      if (!mounted) return;
      setState(() => admin = true);
      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(state: state)));
      return;
    }
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Support'),
        content: TextField(controller: code, obscureText: true, decoration: const InputDecoration(labelText: 'Kod')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Öppna')),
        ],
      ),
    );
    if (ok == true) {
      final typed = code.text.trim();
      final invited = await Network.redeemInvite(typed, state.email);
      if (invited) {
        if (!mounted) return;
        setState(() => admin = true);
        Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(state: state)));
      }
    }
    code.dispose();
  }

  ImageProvider? _photo(String photo) {
    if (photo.isEmpty) return null;
    if (photo.startsWith('http')) return NetworkImage(photo);
    return FileImage(File(photo));
  }

  @override
  Widget build(BuildContext context) {
    final photo = state.photoUrl;
    final dark = state.darkMode;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF1C1410) : const Color(0xFFFFF4EC),
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Inställningar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage(state: state))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(state: state))),
              child: Ink(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE25C3A), Color(0xFFF4A261)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      backgroundImage: _photo(photo),
                      child: photo.isEmpty ? const Icon(Icons.pets, color: Color(0xFFE25C3A), size: 36) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.fullName.isEmpty ? (state.email.isEmpty ? 'Konto' : state.email) : state.fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(
                            state.isPremium ? 'PawMatch Premium' : (state.ownerBio.isEmpty ? 'Tryck för att redigera profil' : state.ownerBio),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          if (state.myDogs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Avel per hund', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            ...List.generate(state.myDogs.length, (i) {
              final d = state.myDogs[i];
              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(d.availableForBreeding ? 'Ute för avel' : 'Bara vänner'),
                  value: d.availableForBreeding,
                  activeThumbColor: const Color(0xFFE25C3A),
                  onChanged: (on) {
                    if (!on) {
                      d.availableForBreeding = false;
                      state.bump();
                      return;
                    }
                    if (d.neutered) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kastrerad hund kan inte läggas ut för avel.')));
                      return;
                    }
                    if (!d.breedingReady) {
                      openDogForm(context, state, index: i, forceBreeding: true);
                      return;
                    }
                    d.availableForBreeding = true;
                    state.bump();
                  },
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          _tile(context, const Color(0xFFE25C3A), Icons.pets, 'Mina hundar', '${state.myDogs.length} sparade', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => MyDogsPage(state: state)));
          }),
          _tile(context, const Color(0xFFF4A261), Icons.workspace_premium_outlined, 'Abonnemang', state.isPremium ? 'Premium aktivt' : '6 månader gratis', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PremiumPage(state: state)));
          }),
          _tile(context, const Color(0xFF1F7A6C), Icons.description, 'Mina avtal', '${state.deals.length} st', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DealsPage(state: state)));
          }),
          _tile(context, const Color(0xFF6B4C9A), Icons.favorite_outline, 'Hund och hälsa', 'Stamtavla, vaccin, community', () => openDogHub(context, state)),
          _tile(context, const Color(0xFF2A9D8F), Icons.support_agent, 'Kundtjänst', 'AI-chatt, e-post, telefon', () => openSupportHub(context, state)),
          _tile(context, const Color(0xFF8B3A32), Icons.flag_outlined, 'Rapportera ett problem', 'Skriv till support', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReportPage(state: state)));
          }),
          if (admin)
            _tile(context, const Color(0xFF8C6A2F), Icons.admin_panel_settings_outlined, 'Supportinkorg', 'Rapporter och verifiering', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPage(state: state)));
            }),
          _tile(context, const Color(0xFF3D5A80), Icons.gavel_outlined, 'Villkor', 'Användarvillkor och GDPR', () => openLegalHub(context)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1B2430), minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () => state.signOut(),
            child: const Text('Logga ut'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B3A32),
              side: const BorderSide(color: Color(0xFF8B3A32)),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              await state.eraseAccount();
            },
            child: const Text('Radera konto'),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _secret,
            child: const Center(child: Text('PawMatch', style: TextStyle(color: Color(0xFFB7A79C), fontSize: 12))),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Color color, IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
