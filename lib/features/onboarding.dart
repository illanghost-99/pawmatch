import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

const _rose = Color(0xFFC23B2E);
const _ink = Color(0xFF1C1410);

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.state});
  final AppState state;
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int page = 0;
  final dogName = TextEditingController();
  final dogBreed = TextEditingController();
  final dogCity = TextEditingController();
  var dogAge = 3;
  var friends = true;
  var breeding = false;

  static const _roles = [
    (UserRole.owner, Icons.pets, 'Hundägare', 'Matcha vänner eller avel för din hund'),
    (UserRole.kennel, Icons.home_work_outlined, 'Kennel', 'Visa uppfödning och kullar'),
    (UserRole.vet, Icons.medical_services_outlined, 'Veterinär', 'Synas för hundägare i närheten'),
    (UserRole.enthusiast, Icons.favorite_outline, 'Hundintresserad', 'Lär känna hundar och ägare'),
  ];

  @override
  void dispose() {
    dogName.dispose();
    dogBreed.dispose();
    dogCity.dispose();
    super.dispose();
  }

  void _next() {
    if (page < 2) {
      setState(() => page++);
      return;
    }
    if (dogName.text.trim().isNotEmpty) {
      widget.state.addMyDog(MyDog(
        name: dogName.text.trim(),
        breed: dogBreed.text.trim().isEmpty ? 'Blandras' : dogBreed.text.trim(),
        age: dogAge,
        city: dogCity.text.trim().isEmpty ? widget.state.locationLabel : dogCity.text.trim(),
        bio: '',
        availableForFriends: friends,
        availableForBreeding: breeding,
      ));
    }
    widget.state.finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final titles = ['Vem är du?', 'Vad söker du?', 'Din hund'];
    final subs = [
      'Välj den roll som passar bäst. Du kan ändra senare.',
      'Kryssa i intressen så anpassar PawMatch sig för dig.',
      'Lägg till din första hund så kan andra hitta er. Du kan hoppa över.',
    ];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F3), Color(0xFFF6D5CF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= page ? _rose : _ink.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(titles[page], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _ink, letterSpacing: -0.6)),
                const SizedBox(height: 8),
                Text(subs[page], style: TextStyle(fontSize: 16, color: _ink.withValues(alpha: 0.7), height: 1.35)),
                const SizedBox(height: 20),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
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
                        : page == 1
                            ? SingleChildScrollView(
                                key: const ValueKey('interests'),
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    for (final i in kInterests)
                                      FilterChip(
                                        label: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                          child: Text('${i.icon}  ${i.label}'),
                                        ),
                                        selected: s.interests.contains(i.id),
                                        showCheckmark: false,
                                        selectedColor: _rose.withValues(alpha: 0.18),
                                        backgroundColor: Colors.white,
                                        side: BorderSide(color: s.interests.contains(i.id) ? _rose : Colors.black12),
                                        labelStyle: TextStyle(
                                          color: _ink,
                                          fontWeight: s.interests.contains(i.id) ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                        onSelected: (_) => setState(() => s.toggleInterest(i.id)),
                                      ),
                                  ],
                                ),
                              )
                            : ListView(
                                key: const ValueKey('dog'),
                                children: [
                                  _field(dogName, 'Hundens namn'),
                                  const SizedBox(height: 12),
                                  _field(dogBreed, 'Ras'),
                                  const SizedBox(height: 12),
                                  _field(dogCity, 'Ort'),
                                  const SizedBox(height: 16),
                                  Text('Ålder: $dogAge år', style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Slider(
                                    value: dogAge.toDouble(),
                                    min: 0,
                                    max: 15,
                                    divisions: 15,
                                    activeColor: _rose,
                                    onChanged: (v) => setState(() => dogAge = v.round()),
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: _rose,
                                    title: const Text('Söker hundvänner'),
                                    value: friends,
                                    onChanged: (v) => setState(() => friends = v),
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    activeThumbColor: _rose,
                                    title: const Text('Öppen för avel'),
                                    subtitle: const Text('Uppgifter granskas senare.'),
                                    value: breeding,
                                    onChanged: (v) => setState(() => breeding = v),
                                  ),
                                ],
                              ),
                  ),
                ),
                if (page == 2)
                  TextButton(
                    onPressed: () => widget.state.finishOnboarding(),
                    child: const Text('Hoppa över just nu'),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _rose,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _next,
                    child: Text(page == 0 ? 'Nästa' : page == 1 ? 'Nästa — lägg till hund' : 'Visa hundar i närheten'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
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
        color: selected ? const Color(0xFFFFE8E4) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _rose : _ink.withValues(alpha: 0.08), width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected ? _rose : const Color(0xFFF8E4E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: selected ? Colors.white : _ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: _ink.withValues(alpha: 0.62))),
                    ],
                  ),
                ),
                Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? _rose : _ink.withValues(alpha: 0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
