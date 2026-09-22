# PawMatch — checklista (det du måste göra själv)

Grok kan inte logga in på Apple Developer, ladda upp APNs eller lägga din plist i Xcode åt dig.

## Klart i GitHub
- [x] Flutter-app (auth, För dig, swipe, chatt, mina hundar, support, policys)
- [x] Admin (`admin/index.html`) + granskningskö mot Supabase
- [x] Face ID-kod (`local_auth`)
- [x] Push-hooks (match, meddelande, godkänd, publicerad)
- [x] `.gitignore` blockerar `GoogleService-Info.plist` och `.p8`

## Du gör

### 1. Supabase
- [ ] Kör `supabase/migrations/20260922120000_review_columns.sql` i SQL Editor
- [ ] Spara URL + anon-nyckel till `flutter run --dart-define=...`

### 2. Firebase (du har projekt pawmatch-404e5)
- [ ] Ladda ner `GoogleService-Info.plist` (dela den inte publikt)
- [ ] När Mac finns: lägg filen i `ios/Runner/`
- [ ] `flutter pub add firebase_core firebase_messaging`
- [ ] Avkommentera Firebase-raderna i `lib/services/push.dart`

### 3. APNs (krävs för iPhone-push)
- [ ] developer.apple.com → Keys → APNs Key (.p8)
- [ ] Firebase → Project settings → Cloud Messaging → ladda upp .p8 + Team ID
- [ ] Xcode → Signing & Capabilities → Push Notifications

### 4. Admin på Vercel
- [ ] vercel.com → Import `illanghost-99/pawmatch` → Deploy
- [ ] Logga in med kod `pawmatch-admin`
- [ ] Klistra in Supabase URL + anon key i admin-UI

### 5. Apple Developer / TestFlight
- [ ] Mac + Xcode
- [ ] Bundle ID `app.pawmatch`
- [ ] Archive → TestFlight

## Bundle ID
`app.pawmatch` — måste vara identiskt i Firebase, Xcode och App Store Connect.
