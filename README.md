# PawMatch

Social plattform för hundägare. Flutter + Supabase. Byggd för App Store v1.

Repo: https://github.com/illanghost-99/pawmatch

## Läs först
- `docs/00-RISKS-AND-V1-SCOPE.md` — vad som får lov att släppas, vad Apple avslår
- `docs/APP-STORE.md` — metadata, IAP, review-notes
- `docs/PRIVACY-POLICY-DRAFT.md` — utkast, inte juridiskt granskat

## Stack
- App: Flutter, Cupertino-first
- Backend: Supabase Auth + Postgres + Storage + Realtime
- Betalning i appen: StoreKit via RevenueCat

Firebase används inte som databas i v1.

## Kör lokalt
```bash
cd apps/mobile
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

## Är detta produktionsklart?
Nej. Detta är en granskbar v1-grund, inte en färdig app för 100 miljoner användare.

Varumärke: PawMatch (inte Pawamatch).
