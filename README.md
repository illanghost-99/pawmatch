# PawMatch

Sveriges sociala app för hundägare — vänner och valpkull i hela landet.

https://github.com/illanghost-99/pawmatch

## Funktioner v1
- Enkel inloggning / skapa konto
- Onboarding med intressen → **För dig**
- Swipe + filter (ras, ålder, ort, radie) över många svenska städer
- Mina hundar: vänner och/eller avel, stamtavla & vaccin till granskning
- Chatt efter match, blockera
- Kundsupport (mailto)
- Villkor, integritet, communityregler
- Admin-demo: `admin/index.html` (Vercel + kod)

Inte i v1: BankID, betald provision, lagkravssignering.

## Kör
```bash
git clone https://github.com/illanghost-99/pawmatch.git && cd pawmatch
flutter create . --project-name pawmatch --org app.pawmatch --platforms=ios,android
flutter pub get && flutter run
```
