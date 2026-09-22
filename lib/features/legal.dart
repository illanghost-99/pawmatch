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
        child: Text(body, style: const TextStyle(height: 1.45, fontSize: 15)),
      ),
    );
  }
}

const kTerms = '''
Användarvillkor — PawMatch (Sverige, v1)

1. Tjänsten
PawMatch är en social app där hundägare kan hitta vänner till sina hundar eller komma i kontakt kring seriös avel. PawMatch förmedlar kontakt. Vi säljer inte hundar, ger inte veterinärråd och är inte part i avtal mellan användare.

2. Konto
Du måste ange korrekta uppgifter och vara myndig. Ett konto per person. Du ansvarar för inloggningen. Du kan radera kontot i appen (Profil).

3. Hundprofiler
Du ansvarar för att bilder och uppgifter stämmer. Stamtavla, vaccin och hälsouppgifter kan granskas av oss. Ett godkännande i appen är inte ett veterinärintyg och inte en garanti.

4. Avel och valpar
Avel och eventuell försäljning sker mellan användarna. Följ djurskyddslagen, Jordbruksverkets regler och rasorganisationers krav. PawMatch tar i version 1 ingen provision och hanterar inga betalningar.

5. Förbjudet
Trakasserier, bedrägeri, förfalskade intyg, olagligt innehåll, sexuellt innehåll, djurplågeri och att locka minderåriga. Brott anmäls och kontot stängs.

6. Moderering
Vi kan ta bort innehåll och stänga konton. Du kan överklaga till support@pawmatch.app.

7. App Store
Appen följer Apples App Review Guidelines: konto kan raderas i appen, integritetspolicy finns, och känsliga uppgifter begärs bara när de behövs för tjänsten.

8. Ansvar
Tjänsten lämnas i befintligt skick. Vi ansvarar inte för möten, avelsresultat eller skador mellan användare.

Kontakt: support@pawmatch.app
''';

const kPrivacy = '''
Integritetspolicy — PawMatch (GDPR / Apple)

Personuppgiftsansvarig: PawMatch, kontakt support@pawmatch.app.

Vad vi samlar in
• E-post och inloggning
• Profil och roll (hundägare, kennel, veterinär, intresserad)
• Hunduppgifter du själv lägger in
• Ungefärlig plats för att visa hundar i närheten
• Chatt efter match
• Enhetsuppgifter för push och felrapporter

Vi samlar inte in BankID i version 1. Vi säljer inte dina uppgifter.

Varför
Avtal (leverera appen), berättigat intresse (säkerhet och missbruk) och samtycke när det krävs (notiser, plats).

Lagring
Så länge kontot finns. Vid radering tar vi bort profil och hundar. Viss logg kan sparas om lagen kräver det.

Dina rättigheter
Registerutdrag, rättelse, radering, invändning och klagomål till IMY. Radering finns i appen under Profil.

Apple Privacy Nutrition Labels
Kontaktuppgifter, användarinnehåll, plats (ungefärlig), identifierare för konto och notiser. Ingen spårning för annonser i v1.

Leverantörer
Moln inom EU när det är möjligt (t.ex. databas och notiser).
''';

const kCommunity = '''
Communityregler

• Var ärlig om hälsa, temperament och avelsstatus.
• Behandla andra ägare med respekt — både den som söker vän och den som söker avel.
• Dela inte andras personuppgifter utan samtycke.
• Inga hot, hat, nakenhet eller sexuellt innehåll.
• Avel ska sätta djurskydd först. Misstänkt vanvård rapporteras.
• Anmäl bedrägeri till support@pawmatch.app.
''';
