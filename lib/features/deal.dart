import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../models.dart';

class DealSheet {
  static Future<void> open(BuildContext context, AppState state, MatchThread thread) async {
    if (thread.deal != null) {
      await _showContract(context, state, thread);
      return;
    }
    final mine = state.myDogs.where((d) => d.availableForBreeding).toList();
    final myDog = TextEditingController(text: mine.isNotEmpty ? mine.first.name : '');
    final price = TextEditingController(text: '12000');
    final pups = TextEditingController(text: '4');
    final place = TextEditingController(text: state.locationLabel);
    final notes = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF4EC),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Förhandla avel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _OwnerChip(label: state.fullName, color: const Color(0xFFE25C3A), onTap: () => _me(context, state))),
                  const SizedBox(width: 8),
                  Expanded(child: _OwnerChip(label: thread.dog.owner, color: const Color(0xFF1F7A6C), onTap: () => _them(context, thread.dog))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Avtal skickas till ${state.email.isEmpty ? 'din e-post' : state.email} när det skapats.', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(controller: myDog, decoration: _dec('Din hund')),
              const SizedBox(height: 8),
              TextField(controller: price, keyboardType: TextInputType.number, decoration: _dec('Pris per valp (kr)')),
              const SizedBox(height: 8),
              TextField(controller: pups, keyboardType: TextInputType.number, decoration: _dec('Förväntat antal valpar')),
              const SizedBox(height: 8),
              TextField(controller: place, decoration: _dec('Plats')),
              const SizedBox(height: 8),
              TextField(controller: notes, maxLines: 3, decoration: _dec('Övrigt')),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE25C3A), minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                onPressed: () {
                  final body = _draft(
                    partyA: state.fullName,
                    mailA: state.email,
                    phoneA: state.phone,
                    dogA: myDog.text.trim().isEmpty ? 'Min hund' : myDog.text.trim(),
                    partyB: thread.dog.owner,
                    dogB: thread.dog.name,
                    breed: thread.dog.breed,
                    price: price.text.trim(),
                    pups: pups.text.trim(),
                    place: place.text.trim(),
                    notes: notes.text.trim(),
                  );
                  thread.deal = BreedingDeal(
                    pricePerPuppy: price.text.trim(),
                    expectedPups: pups.text.trim(),
                    place: place.text.trim(),
                    notes: notes.text.trim(),
                    partyA: state.fullName,
                    partyB: thread.dog.owner,
                    body: body,
                  );
                  if (thread.messages.isEmpty || !thread.messages.last.text.startsWith('Avtal skapat')) {
                    thread.messages.add(ChatLine(true, 'Avtal skapat. Kopia kan skickas till ${state.email}.'));
                  }
                  state.bump();
                  Navigator.pop(ctx);
                  _showContract(context, state, thread);
                },
                child: const Text('Skapa avtal'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static InputDecoration _dec(String l) => InputDecoration(
        labelText: l,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      );

  static void _me(BuildContext context, AppState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(s.identityPending ? 'Identitet: väntar på granskning' : 'Identitet ifylld'),
            const SizedBox(height: 8),
            Text('E-post: ${s.email}'),
            Text('Telefon: ${s.phone.isEmpty ? '—' : s.phone}'),
            Text('Adress: ${s.address.isEmpty ? '—' : s.address}'),
            Text('Personnummer: ${s.personalNumber.isEmpty ? '—' : 'sparat (dolt)'}'),
          ],
        ),
      ),
    );
  }

  static void _them(BuildContext context, DogProfile d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.owner, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            Text('${d.name} · ${d.breed} · ${d.city}'),
            const SizedBox(height: 8),
            Text(d.bio),
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [for (final r in d.reviews) Chip(label: Text(r))]),
          ],
        ),
      ),
    );
  }

  static Widget _sigBox(List<List<SigPoint>> strokes, String empty) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: strokes.isEmpty
          ? Align(alignment: Alignment.centerLeft, child: Text(empty, style: const TextStyle(color: Colors.black54)))
          : CustomPaint(painter: _SigPainter(strokes, fit: true), child: const SizedBox.expand()),
    );
  }

  static Future<void> _showContract(BuildContext context, AppState state, MatchThread thread) {
    final deal = thread.deal;
    if (deal == null) return Future.value();
    final name = TextEditingController(text: deal.signedByMe.isEmpty ? state.fullName : deal.signedByMe);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF5C4033),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final waiting = deal.signedByMe.isNotEmpty && !deal.fullySigned;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Avelsavtal', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF4E7D3), fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    deal.fullySigned
                        ? 'Signerat av båda parter'
                        : waiting
                            ? 'Du har signerat. Väntar på ${deal.partyB}.'
                            : 'Båda måste signera innan avtalet är klart.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFF4E7D3)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _OwnerChip(label: deal.partyA.isEmpty ? state.fullName : deal.partyA, color: const Color(0xFFE25C3A), onTap: () => _me(context, state))),
                      const SizedBox(width: 8),
                      Expanded(child: _OwnerChip(label: deal.partyB, color: const Color(0xFF1F7A6C), onTap: () => _them(context, thread.dog))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF6EA),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
                      border: Border.all(color: const Color(0xFFD9C8A3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: Text('PAWMATCH', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w800, color: Color(0xFF8B3A32)))),
                        const Center(child: Text('AVELSAVTAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                        const Divider(height: 24),
                        Text(deal.body, style: const TextStyle(height: 1.45, fontSize: 14, color: Color(0xFF2C2118))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (deal.signedByMe.isEmpty) ...[
                    TextField(controller: name, decoration: _dec('Fullständigt namn')),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final paths = await _signPopup(context, deal.signature);
                        if (paths != null) {
                          deal.signature = paths;
                          setLocal(() {});
                        }
                      },
                      child: _sigBox(deal.signature, 'Tryck för att signera med fingret'),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(deal.signedByMe, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF4E7D3), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              _sigBox(deal.signature, '—'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(deal.fullySigned ? deal.signedByOther : deal.partyB, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF4E7D3), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              _sigBox(deal.signatureOther, 'Inväntas'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1F7A6C), minimumSize: const Size.fromHeight(52)),
                    onPressed: () async {
                      if (deal.signedByMe.isNotEmpty) {
                        Navigator.pop(ctx);
                        return;
                      }
                      if (name.text.trim().isEmpty || deal.signature.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fyll i namn och signatur.')));
                        return;
                      }
                      deal.signedByMe = name.text.trim();
                      thread.messages.add(ChatLine(true, 'Du har signerat. Väntar på ${deal.partyB}.'));
                      state.bump();
                      setLocal(() {});
                      if (!ctx.mounted) return;
                      await showDialog<void>(
                        context: ctx,
                        barrierDismissible: false,
                        builder: (d) => const _SignedOk(label: 'Din del är signerad'),
                      );
                    },
                    child: Text(deal.fullySigned
                        ? 'Avtalet klart — stäng'
                        : deal.signedByMe.isEmpty
                            ? 'Bekräfta min signering'
                            : 'Stäng — väntar på motpart'),
                  ),
                  if (waiting)
                    TextButton(
                      onPressed: () {
                        deal.signedByOther = deal.partyB;
                        deal.signatureOther = [
                          [const SigPoint(12, 50), const SigPoint(40, 62), const SigPoint(70, 40), const SigPoint(110, 58), const SigPoint(150, 36)],
                        ];
                        thread.messages.add(ChatLine(false, '${deal.partyB} har signerat avtalet.'));
                        state.bump();
                        setLocal(() {});
                      },
                      child: Text('Simulera ${deal.partyB}s signering (demo)', style: const TextStyle(color: Color(0xFFF4E7D3))),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF4E7D3), side: const BorderSide(color: Color(0xFFF4E7D3)), minimumSize: const Size.fromHeight(48)),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: deal.body));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kopierat. Kan mejlas till ${state.email}.')));
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Ladda ner / kopiera'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static Future<List<List<SigPoint>>?> _signPopup(BuildContext context, List<List<SigPoint>> existing) {
    final strokes = existing.map((s) => List<SigPoint>.from(s)).toList();
    return showDialog<List<List<SigPoint>>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: const Color(0xFFFBF6EA),
          title: const Text('Skriv din signatur'),
          content: SizedBox(
            width: 320,
            height: 220,
            child: GestureDetector(
              onPanStart: (d) {
                strokes.add([SigPoint(d.localPosition.dx, d.localPosition.dy)]);
                setLocal(() {});
              },
              onPanUpdate: (d) {
                if (strokes.isEmpty) return;
                strokes.last.add(SigPoint(d.localPosition.dx, d.localPosition.dy));
                setLocal(() {});
              },
              child: Container(
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFD9C8A3)), borderRadius: BorderRadius.circular(12)),
                child: CustomPaint(painter: _SigPainter(strokes), child: const SizedBox.expand()),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () { strokes.clear(); setLocal(() {}); }, child: const Text('Rensa')),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Avbryt')),
            FilledButton(onPressed: () => Navigator.pop(ctx, strokes), child: const Text('Klar')),
          ],
        ),
      ),
    );
  }

  static String _draft({
    required String partyA,
    required String mailA,
    required String phoneA,
    required String dogA,
    required String partyB,
    required String dogB,
    required String breed,
    required String price,
    required String pups,
    required String place,
    required String notes,
  }) {
    final day = DateTime.now().toIso8601String().split('T').first;
    return 'Datum: $day\n\nParter\n1. $partyA ($mailA, $phoneA), ägare av $dogA\n2. $partyB, ägare av $dogB ($breed)\n\nÖverenskommelse\nAvel mellan ovan hundar. Förväntat antal valpar: $pups.\nPris per valp: $price kr.\nPlats: $place.\n\nÖvrigt\n${notes.isEmpty ? 'Inget ytterligare.' : notes}\n\nPawMatch är inte part och ger ingen veterinärrådgivning.\nMall, inte juridisk rådgivning.';
  }
}

class _SignedOk extends StatefulWidget {
  const _SignedOk({this.label = 'Signerat'});
  final String label;
  @override
  State<_SignedOk> createState() => _SignedOkState();
}

class _SignedOkState extends State<_SignedOk> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 44,
              backgroundColor: Color(0xFF1F7A6C),
              child: Icon(Icons.check_rounded, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 14),
            Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _SigPainter extends CustomPainter {
  _SigPainter(this.strokes, {this.fit = false});
  final List<List<SigPoint>> strokes;
  final bool fit;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = strokes.expand((s) => s);
    if (pts.isEmpty) return;
    var minX = pts.first.x, maxX = pts.first.x, minY = pts.first.y, maxY = pts.first.y;
    for (final p in pts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }
    final w = (maxX - minX).clamp(8, 4000);
    final h = (maxY - minY).clamp(8, 4000);
    final scale = fit ? ((size.width - 16) / w < (size.height - 16) / h ? (size.width - 16) / w : (size.height - 16) / h) : 1.0;
    final dx = fit ? (size.width - w * scale) / 2 - minX * scale : 0.0;
    final dy = fit ? (size.height - h * scale) / 2 - minY * scale : 0.0;
    final paint = Paint()
      ..color = const Color(0xFF1B2430)
      ..strokeWidth = fit ? 2.4 : 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.x * scale + dx, s.first.y * scale + dy);
      for (final pt in s.skip(1)) {
        path.lineTo(pt.x * scale + dx, pt.y * scale + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SigPainter old) => true;
}

class _OwnerChip extends StatelessWidget {
  const _OwnerChip({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: color, width: 1.5)),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
