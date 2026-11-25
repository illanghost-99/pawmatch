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
                    mailA: state.email.trim().toLowerCase(),
                    mailB: thread.peerEmail.trim().toLowerCase(),
                  );
                  state.bump();
                  state.publishDeal(thread, tell: false);
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
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF5C4033),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.viewInsetsOf(ctx).bottom + 16),
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            final me = state.email.trim().toLowerCase();
            final mailA = deal.mailA.trim().toLowerCase();
            final mailB = deal.mailB.trim().toLowerCase();
            var iAmA = mailA.isNotEmpty && me == mailA;
            var iAmB = mailB.isNotEmpty && me == mailB;
            if (!iAmA && !iAmB) {
              iAmA = me.isNotEmpty && _exactMail(deal.body, me);
              iAmB = !iAmA && me.isNotEmpty;
            }
            if (iAmA) iAmB = false;
            final otherName = iAmA ? deal.partyB : deal.partyA;
            final waiting = deal.signedByMe.isNotEmpty && !deal.fullySigned;
            String sideName(bool mineSide) => mineSide ? deal.signedByMe : deal.signedByOther;
            List<List<SigPoint>> sideSign(bool mineSide) => mineSide ? deal.signature : deal.signatureOther;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Avelsavtal', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFF4E7D3), fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    deal.fullySigned
                        ? 'Signerat av båda parter. Du kan ladda ner det.'
                        : waiting
                            ? 'Du har signerat. Väntar på $otherName.'
                            : deal.signedByOther.isNotEmpty
                                ? '${deal.signedByOther} har signerat. Din tur.'
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
                      color: deal.fullySigned ? const Color(0xFFE5F6EE) : const Color(0xFFFBF6EA),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
                      border: Border.all(color: deal.fullySigned ? const Color(0xFF1F7A6C) : const Color(0xFFD9C8A3), width: deal.fullySigned ? 2.5 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(child: Text('PAWMATCH', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w800, color: Color(0xFF8B3A32)))),
                        const Center(child: Text('AVELSAVTAL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                        const Divider(height: 24),
                        Text(deal.body, style: const TextStyle(height: 1.45, fontSize: 14, color: Color(0xFF2C2118))),
                        const SizedBox(height: 14),
                        const Text('Uppgifter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Varje part fyller i sina tre uppgifter. Signering är låst tills de är ifyllda.', style: TextStyle(fontSize: 12, height: 1.35)),
                        const SizedBox(height: 10),
                        _PartyFacts(
                          title: iAmA && deal.signedByMe.isEmpty ? 'Dina uppgifter' : (deal.partyA.isEmpty ? 'Part 1' : deal.partyA),
                          addr: deal.addrA,
                          phone: deal.phoneA,
                          pnr: deal.pnrA,
                          edit: iAmA && deal.signedByMe.isEmpty,
                          onChanged: (a, p, n) {
                            deal.addrA = a;
                            deal.phoneA = p;
                            deal.pnrA = n;
                            state.bump();
                            setLocal(() {});
                          },
                        ),
                        const SizedBox(height: 10),
                        _PartyFacts(
                          title: iAmB && deal.signedByMe.isEmpty ? 'Dina uppgifter' : (deal.partyB.isEmpty ? 'Part 2' : deal.partyB),
                          addr: deal.addrB,
                          phone: deal.phoneB,
                          pnr: deal.pnrB,
                          edit: iAmB && deal.signedByMe.isEmpty,
                          onChanged: (a, p, n) {
                            deal.addrB = a;
                            deal.phoneB = p;
                            deal.pnrB = n;
                            state.bump();
                            setLocal(() {});
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text('Försäkran', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        const Text(
                          'Genom att signera intygar och svär varje part att uppgifterna är riktiga och stämmer överens med personen själv.',
                          style: TextStyle(height: 1.4, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _signColumn(
                        label: deal.partyA,
                        name: sideName(iAmA),
                        strokes: sideSign(iAmA),
                        empty: iAmA ? 'Tryck för att signera' : 'Inte signerad',
                        onTap: !iAmA || deal.signedByMe.isNotEmpty
                            ? null
                            : () async {
                                if (!_ownReady(deal, true)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fyll i adress, telefonnummer och personnummer innan du signerar.')));
                                  return;
                                }
                                await _writeSign(context, ctx, setLocal, state, thread, deal, otherName);
                              },
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _signColumn(
                        label: deal.partyB,
                        name: sideName(iAmB),
                        strokes: sideSign(iAmB),
                        empty: iAmB ? 'Tryck för att signera' : 'Inte signerad',
                        onTap: !iAmB || deal.signedByMe.isNotEmpty
                            ? null
                            : () async {
                                if (!_ownReady(deal, false)) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fyll i adress, telefonnummer och personnummer innan du signerar.')));
                                  return;
                                }
                                await _writeSign(context, ctx, setLocal, state, thread, deal, otherName);
                              },
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: deal.fullySigned ? const Color(0xFF1F7A6C) : const Color(0xFF5C4033), minimumSize: const Size.fromHeight(48)),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(deal.fullySigned ? 'Avtalet är signerat' : 'Stäng'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF4E7D3), side: const BorderSide(color: Color(0xFFF4E7D3)), minimumSize: const Size.fromHeight(48)),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: '${deal.body}${_factsText(deal)}'));
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

  static Future<void> _writeSign(
    BuildContext context,
    BuildContext ctx,
    void Function(void Function()) setLocal,
    AppState state,
    MatchThread thread,
    BreedingDeal deal,
    String otherName,
  ) async {
    final paths = await _signPopup(context, deal.signature);
    if (paths == null || paths.isEmpty) return;
    final live = thread.deal;
    deal.signature = paths;
    deal.signedByMe = state.fullName.trim().isEmpty ? 'Signerat' : state.fullName.trim();
    if (live != null && !identical(live, deal) && deal.signedByOther.isEmpty && live.signedByOther.isNotEmpty) {
      deal.signedByOther = live.signedByOther;
      deal.signatureOther = live.signatureOther;
    }
    thread.deal = deal;
    final done = deal.fullySigned;
    state.bump();
    setLocal(() {});
    await state.publishDeal(thread, tell: true);
    if (!ctx.mounted) return;
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (d) => _SignedOk(
        label: done ? 'Avtalet är signerat. Du kan ladda ner det.' : 'Din del är signerad',
      ),
    );
  }

  static Widget _signColumn({
    required String label,
    required String name,
    required List<List<SigPoint>> strokes,
    required String empty,
    Future<void> Function()? onTap,
  }) {
    final signed = name.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(signed ? name : label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF4E7D3), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: onTap != null ? const Color(0xFFF4E7D3) : Colors.transparent, width: 1.4),
            ),
            child: _sigBox(strokes, empty),
          ),
        ),
      ],
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
    return 'Datum: $day\n\nParter\n1. $partyA ($mailA, $phoneA), ägare av $dogA\n2. $partyB, ägare av $dogB ($breed)\n\nÖverenskommelse\nAvel mellan ovan hundar. Förväntat antal valpar: $pups.\nPris per valp: $price kr.\nPlats: $place.\n\nÖvrigt\n${notes.isEmpty ? 'Inget ytterligare.' : notes}\n\nVarje part fyller i adress, telefonnummer och personnummer innan signering.\nPawMatch är inte part och ger ingen veterinärrådgivning.\nMall, inte juridisk rådgivning.';
  }

  static bool _exactMail(String body, String email) {
    final me = email.trim().toLowerCase();
    if (me.isEmpty) return false;
    return RegExp('(?<![a-z0-9._%+-])${RegExp.escape(me)}(?![a-z0-9._%+-])').hasMatch(body.toLowerCase());
  }

  static bool _ownReady(BreedingDeal deal, bool sideA) {
    final addr = sideA ? deal.addrA : deal.addrB;
    final phone = sideA ? deal.phoneA : deal.phoneB;
    final pnr = sideA ? deal.pnrA : deal.pnrB;
    return addr.trim().isNotEmpty && phone.trim().isNotEmpty && pnr.trim().isNotEmpty;
  }

  static String _factsText(BreedingDeal d) {
    String block(String name, String addr, String phone, String pnr) =>
        '$name\n1. Adress: ${addr.trim().isEmpty ? '—' : addr.trim()}\n2. Telefonnummer: ${phone.trim().isEmpty ? '—' : phone.trim()}\n3. Personnummer: ${pnr.trim().isEmpty ? '—' : pnr.trim()}';
    return '\n\nUppgifter\n${block(d.partyA, d.addrA, d.phoneA, d.pnrA)}\n\n${block(d.partyB, d.addrB, d.phoneB, d.pnrB)}\n\nFörsäkran\nGenom att signera intygar och svär varje part att uppgifterna är riktiga och stämmer överens med personen själv.';
  }
}

class _PartyFacts extends StatefulWidget {
  const _PartyFacts({
    required this.title,
    required this.addr,
    required this.phone,
    required this.pnr,
    required this.edit,
    required this.onChanged,
  });
  final String title;
  final String addr;
  final String phone;
  final String pnr;
  final bool edit;
  final void Function(String addr, String phone, String pnr) onChanged;

  @override
  State<_PartyFacts> createState() => _PartyFactsState();
}

class _PartyFactsState extends State<_PartyFacts> {
  late final addr = TextEditingController(text: widget.addr);
  late final phone = TextEditingController(text: widget.phone);
  late final pnr = TextEditingController(text: widget.pnr);

  @override
  void dispose() {
    addr.dispose();
    phone.dispose();
    pnr.dispose();
    super.dispose();
  }

  void _push() => widget.onChanged(addr.text.trim(), phone.text.trim(), pnr.text.trim());

  @override
  Widget build(BuildContext context) {
    if (!widget.edit) {
      String show(String live, TextEditingController box) {
        final v = live.trim().isNotEmpty ? live.trim() : box.text.trim();
        return v.isEmpty ? '—' : v;
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('1. Adress: ${show(widget.addr, addr)}'),
          Text('2. Telefonnummer: ${show(widget.phone, phone)}'),
          Text('3. Personnummer: ${show(widget.pnr, pnr)}'),
        ],
      );
    }
    InputDecoration field(String label) => InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        TextField(controller: addr, textCapitalization: TextCapitalization.sentences, decoration: field('1. Adress'), onChanged: (_) => _push()),
        const SizedBox(height: 6),
        TextField(controller: phone, keyboardType: TextInputType.phone, decoration: field('2. Telefonnummer'), onChanged: (_) => _push()),
        const SizedBox(height: 6),
        TextField(controller: pnr, keyboardType: TextInputType.number, decoration: field('3. Personnummer'), onChanged: (_) => _push()),
      ],
    );
  }
}

class _SignedOk extends StatefulWidget {
  const _SignedOk({this.label = 'Signerat'});
  final String label;
  @override
  State<_SignedOk> createState() => _SignedOkState();
}

class _SignedOkState extends State<_SignedOk> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    ctrl.forward();
    Future<void>.delayed(Duration(milliseconds: widget.label.contains('ladda ner') ? 2200 : 1100), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: ctrl, curve: Curves.easeOutBack);
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: scale,
              child: const CircleAvatar(
                radius: 44,
                backgroundColor: Color(0xFF1F7A6C),
                child: Icon(Icons.check_rounded, size: 52, color: Colors.white),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(widget.label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ),
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
