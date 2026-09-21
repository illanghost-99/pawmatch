import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.state});
  final AppState state;
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int page = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PawMatch', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(page == 0 ? 'Vem är du?' : 'Vad söker du? Appen anpassar För dig.'),
              const SizedBox(height: 24),
              if (page == 0)
                ...UserRole.values.map((r) => RadioListTile<UserRole>(
                      title: Text(switch (r) {
                        UserRole.owner => 'Hundägare',
                        UserRole.kennel => 'Kennel',
                        UserRole.vet => 'Veterinär',
                        UserRole.enthusiast => 'Hundintresserad',
                      }),
                      value: r,
                      groupValue: s.role,
                      onChanged: (v) => setState(() => s.role = v!),
                    ))
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in kInterests)
                      FilterChip(
                        label: Text('${i.icon} ${i.label}'),
                        selected: s.interests.contains(i.id),
                        onSelected: (_) => setState(() => s.toggleInterest(i.id)),
                      ),
                  ],
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (page == 0) {
                    setState(() => page = 1);
                  } else {
                    s.finishOnboarding();
                  }
                },
                child: Text(page == 0 ? 'Nästa' : 'Visa hundar i närheten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
