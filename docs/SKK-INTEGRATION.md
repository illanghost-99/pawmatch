# SKK-integration — juridisk slutsats (september 2026)

## Finns officiellt API?
Nej. Svenska Kennelklubben publicerar **inget öppet developer-API** för Hunddata, Avelsdata, stamtavlor eller hälsoregister.

Offentliga tjänster som finns idag:
- [Hunddata](https://hundar.skk.se/hunddata/) — sök registrerade hundar
- [Avelsdata](https://hundar.skk.se/Avelsdata/) — rasstatistik och provparning
- [Mitt SKK](https://www.mittskk.se/) — medlems-e-tjänster
- [Djurid / DjurID](https://djurid.se) — ägarregister (SKK + Nordic Web Team)

Dessa är SKK:s egna webbtjänster, inte partner-API:er.

## Vad säger villkoren?
SKK:s [användarvillkor](https://www.skk.se/sidfot-bottenlankar/anvandarvillkor/) är tydliga:

1. Innehåll får användas **enbart för eget, icke-kommersiellt bruk**.
2. SKK-innehåll (hunddata, avels- och veterinärdata, rasdata, tävlingsresultat, beräkningar) får **inte** läggas in i annan databas eller på annan webbplats utan skriftligt samtycke.
3. Ingen licens till immaterialrätt ges implicit.
4. Allt material är upphovsrättsskyddat.

**Slutsats:** Scraping, spegling eller ”officiell SKK-badge” utan avtal är olagligt och skadligt för varumärket.

## Vad PawMatch får göra nu
- Låta användaren **själv skriva in** registreringsnummer.
- Låta användaren **ladda upp** stamtavla, hälsocertifikat och DNA.
- Märka status som `Uppladdat — granskas av PawMatch`, aldrig `Verifierat av SKK`.
- Länka ut till Hunddata/Avelsdata så användaren själv kan kontrollera källan.
- Moderera uppladdningar manuellt i admin.

## Vad som krävs för riktig SKK-koppling
Skriftligt avtal med SKK (kansli, Sollentuna). Trolig väg:
1. Partnerförfrågan till SKK IT / affärsutveckling.
2. Databehandlingsavtal (GDPR art. 28) om personuppgifter delas.
3. Teknisk integration via deras leverantör (historiskt Nordic Web Team / Junipeer för Djurid).
4. Tydlig märkning: data kommer från SKK, cache-regler, rättelseprocess.

Tills avtal finns: **ingen automatisk hämtning**.

## Kontakt att skicka (utkast)
Ämne: Förfrågan om officiell dataåtkomst — PawMatch

Hej SKK,

PawMatch är en svensk app för seriös matchning av hundvänner och avel. Vi vill inte spegla Hunddata. Vi vill undersöka om det finns en officiell, avtalsbunden väg att verifiera registreringsnummer mot ert register, med användarens samtycke.

Kan ni hänvisa rätt person på kansliet?

## SKK-avtal vs PawMatch-avtal
SKK-anslutna uppfödare **måste** använda SKK:s köpe-/foderavtal vid överlåtelse av hund. PawMatch parningsavtal är ett **komplement mellan ägare**, inte ersättning för SKK:s tvingande överlåtelseavtal. Det ska stå i varje avtalstext.
