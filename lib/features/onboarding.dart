import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

const _rust = Color(0xFFC47A52);
const _ink = Color(0xFF1C1410);

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.state});
  final AppState state;
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int page = 0;

  static const _roles = [
    (UserRole.owner, Icons.pets, 'Hundägare', 'Matcha vänner eller avel för din hund'),
    (UserRole.kennel, Icons.home_work_outlined, 'Kennel', 'Visa uppfödning och kullar'),
    (UserRole.vet, Icons.medical_services_outlined, 'Veterinär', 'Synas för hundägare i närheten'),
    (UserRole.enthusiast, Icons.favorite_outline, 'Hundintresserad', 'Lär känna hundar och ägare'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8F2), Color(0xFFF0E0D2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(2, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= page ? _rust : _ink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                Text(
                  page == 0 ? 'Vem är du?' : 'Vad söker du?',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: _ink, letterSpacing: -0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  page == 0
                      ? 'Välj den roll som passar bäst. Du kan ändra senare.'
                      : 'Kryssa i intressen så anpassar PawMatch För dig.',
                  style: TextStyle(fontSize: 16, color: _ink.withValues(alpha: 0.68), height: 1.35),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: page == 0
                        ? ListView(
                            key: const ValueKey('roles'),
                            children: [
                              for (final item in _roles)
                                _RoleCard(
                                  icon: item.$2,
                                  title: item.$3,
                                  subtitle: item.$4,
                                  selected: s.role == item.$1,
                                  onTap: () => setState(() => s.role = item.$1),
                                ),
                            ],
                          )
                        : SingleChildScrollView(
                            key: const ValueKey('interests'),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final i in kInterests)
                                  FilterChip(
                                    label: Text('${i.icon}  ${i.label}'),
                                    selected: s.interests.contains(i.id),
                                    showCheckmark: false,
                                    selectedColor: _rust.withValues(alpha: 0.22),
                                    labelStyle: TextStyle(
                                      color: _ink,
                                      fontWeight: s.interests.contains(i.id) ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                    onSelected: (_) => setState(() => s.toggleInterest(i.id)),
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: () {
                      if (page == 0) {
                        setState(() => page = 1);
                      } else {
                        s.finishOnboarding();
                      }
                    },
                    child: Text(page == 0 ? 'Nästa' : 'Visa hundar i närheten'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: selected ? const Color(0xFFFFF1E6) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _rust : _ink.withValues(alpha: 0.08), width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected ? _rust : const Color(0xFFF3E7DC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: selected ? Colors.white : _ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: _ink.withValues(alpha: 0.62))),
                    ],
                  ),
                ),
                Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? _rust : _ink.withValues(alpha: 0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
