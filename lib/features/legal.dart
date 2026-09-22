import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body),
      ),
    );
  }
}

const kTerms = '''
Användarvillkor (utkast v1)

1. PawMatch är en social plattform för hundägare. Vi förmedlar kontakt, inte veterinärvård eller juridisk rådgivning.
2. Du ansvarar för att uppgifter om din hund är korrekta. Stamtavla och hälsouppgifter granskas i rimlig utsträckning men godkännande är inte en veterinärcertifiering.
3. Avel och valpförsäljning sker mellan användare. Följ svensk lag, djurskyddsregler och eventuella rasorganisationers krav.
4. Respektera andra. Trakasserier, bedrägeri och olagligt innehåll leder till avstängning.
5. Du kan radera ditt konto i appen. Vissa loggar kan sparas enligt lag.

Kontakta support@pawmatch.app vid frågor.
''';

const kPrivacy = '''
Integritetspolicy (utkast v1)

Personuppgiftsansvarig: PawMatch (kontakt: support@pawmatch.app).

Vi behandlar e-post, profil, hunduppgifter, plats (ungefärlig) och chatt för att leverera tjänsten.
Rättslig grund: avtal och berättigat intresse (säkerhet, missbruk).

Du kan begära registerutdrag och radering.
Vi använder leverantörer (t.ex. molndatabas) inom EU när det är möjligt.

App Store: vi följer Apples krav på tydlig policy och kontoborttagning.
''';

const kCommunity = '''
Communityregler

- Var ärlig om din hunds hälsa och temperament.
- Dela inte andras personuppgifter utan samtycke.
- Inga hot, hat eller sexuellt innehåll.
- Rapportera misstänkt bedrägeri till support.
- Avel: prioritera djurskydd. PawMatch godkänner inte djurplågeri.
''';
