# PawMatch

Sveriges sociala app för hundägare. Matcha hundar i närheten — till **vänner** eller **valpkull**.

Repo: https://github.com/illanghost-99/pawmatch

Stack: **Flutter** (iOS + Android) + **Supabase** (gratisnivå).

Inte i v1: BankID, avtalsverktyg, valpprovision, betald Premium.

## Kom igång

```bash
git clone https://github.com/illanghost-99/pawmatch.git
cd pawmatch
flutter create . --project-name pawmatch --org app.pawmatch --platforms=ios,android
flutter pub get
flutter run
```

`flutter create .` skapar `ios/` och `android/` utan att skriva över `lib/`.

På Mac öppnar du sedan `ios/Runner.xcworkspace` i Xcode för TestFlight.

### Supabase (valfritt)

Utan nycklar kör appen testdata.

```bash
flutter run --dart-define=SUPABASE_URL=https://DIN.supabase.co --dart-define=SUPABASE_ANON_KEY=DIN_KEY
```

## v1
- Onboarding: roll + intressen
- För dig — rankat på intressen och plats
- Utforska — swipe + filter
- Match + chatt
- Blockera / radera konto
