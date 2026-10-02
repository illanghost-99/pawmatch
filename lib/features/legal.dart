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
Användarvillkor — PawMatch

1. Tjänsten
PawMatch är en social app där hundägare kan hitta vänner till sina hundar eller komma i kontakt kring seriös avel. PawMatch förmedlar kontakt. Vi säljer inte hundar, ger inte veterinärråd och är inte part i avtal mellan användare.

2. Konto
Du måste ange korrekta uppgifter och vara myndig. Ett konto per person. Du ansvarar för inloggningen. Du kan radera kontot i appen under Profil.

3. Hundprofiler
Du ansvarar för att bilder och uppgifter stämmer. Stamtavla, vaccin och hälsouppgifter kan granskas av oss. Ett godkännande i appen är inte ett veterinärintyg och inte en garanti.

4. Avel och valpar
Avel och eventuell försäljning sker mellan användarna. Följ djurskyddslagen, Jordbruksverkets regler och rasorganisationers krav. PawMatch tar ingen provision på avtal mellan användare. Sådan betalning sker direkt mellan er. Abonnemang i PawMatch betalas via Apple.

5. Förbjudet
Trakasserier, bedrägeri, förfalskade intyg, olagligt innehåll, sexuellt innehåll, djurplågeri och att locka minderåriga. Brott anmäls och kontot stängs.

6. Moderering
Vi kan ta bort innehåll och stänga konton. Du kan överklaga till support@pawmatch.app.

7. App Store
Appen följer Apples riktlinjer. Kontot kan raderas i appen, integritetspolicyn finns i appen, och känsliga uppgifter begärs bara när de behövs för tjänsten.

8. Ansvar
Tjänsten tillhandahålls i befintligt skick. Vi ansvarar inte för möten, avelsresultat eller skador mellan användare.

9. Ändringar
Vi kan uppdatera villkoren. De aktuella villkoren finns alltid i appen. Fortsätter du använda PawMatch efter en uppdatering gäller de nya villkoren.

Kontakt: support@pawmatch.app
Samma text finns på https://illanghost-99.github.io/pawmatch/
Senast uppdaterad: 2 oktober 2026
''';

const kPrivacy = '''
Integritetspolicy — PawMatch

Personuppgiftsansvarig: PawMatch.
Kontakt: support@pawmatch.app.

Vad vi samlar in
• E-post och inloggning
• Namn och telefonnummer
• Profil och roll (hundägare, kennel, veterinär, intresserad)
• Hunduppgifter du själv lägger in
• Ungefärlig plats för att visa hundar i närheten
• Chatt efter match
• Uppgifter som behövs för notiser och för att hålla appen stabil

Vi säljer inte dina uppgifter och använder dem inte för annonsspårning.

Varför
Avtal (för att leverera appen), berättigat intresse (säkerhet och att motverka missbruk) och samtycke när det krävs (notiser och plats).

Lagring
Så länge kontot finns. När du raderar kontot tar vi bort profil och hundar. Viss information kan sparas om lagen kräver det.

Dina rättigheter
Du har rätt till registerutdrag, rättelse, radering och invändning, samt att klaga hos Integritetsskyddsmyndigheten (IMY). Radering finns i appen under Profil.

Köp
Abonnemang betalas via Apple. Apple hanterar betalningen. PawMatch ser inte ditt kortnummer.

Leverantörer
Uppgifter kan behandlas av leverantörer som driftar databasen, skickar notiser och besvarar kundtjänst. Vi väljer moln inom EU när det är möjligt.

Samma text finns på https://illanghost-99.github.io/pawmatch/

Senast uppdaterad: 2 oktober 2026
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
