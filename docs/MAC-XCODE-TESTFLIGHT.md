# PawMatch på Mac → Xcode → TestFlight

Koden i GitHub är samma app som på Asus. iOS-mappen skapas på Mac med Flutter.

**Bundle ID:** `app.pawmatch`  
**Firebase-projekt:** `pawmatch-404e5`  
**Supabase:** samma projekt du redan kopplat på Windows.

---

## 0. Vänta på Apple

I Developer-appen står det **Enrollment Pending**.  
TestFlight går inte förrän det blir **Active** och du fått mejlet *Welcome to the Apple Developer Program*.

Individkonto: oftast 1–2 dygn, ibland längre utanför USA.

Du kan göra steg 1–4 redan nu. Steg 5–6 kräver aktivt konto.

Logga in på Mac med **din** Apple ID (Iliamo Hanna), inte systerns.

---

## 1. Installera på Mac

1. Installera **Xcode** från App Store. Öppna den en gång och acceptera licensen.
2. I Terminal:

```bash
xcode-select --install
```

3. Installera Flutter: https://docs.flutter.dev/get-started/install/macos
4. Kontroll:

```bash
flutter doctor
```

Xcode och iOS toolchain ska vara gröna.

---

## 2. Hämta koden exakt som den är

```bash
cd ~
git clone https://github.com/illanghost-99/pawmatch.git
cd pawmatch
git pull
```

Skapa iOS-projektet (finns inte i GitHub än, det är meningen):

```bash
flutter create . --project-name pawmatch --org app --platforms=ios
flutter pub get
```

`--org app` + projektnamn `pawmatch` ger bundle id `app.pawmatch`.

Lägg in Face ID + push i `ios/Runner/Info.plist` (texten finns i `ios-config/Info.plist.snippet.xml`):

- `NSFaceIDUsageDescription`
- `UIBackgroundModes` → `remote-notification`

Lägg `assets/welcome_dogs.png` i `assets/` om den saknas efter clone.

---

## 3. Supabase på iOS

Samma URL och nyckel som på Windows.  
Lägg dem **inte** i GitHub.

Kör så här när du testar på iPhone:

```bash
flutter run --release \
  --dart-define=SUPABASE_URL=https://DITT-PROJEKT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=DIN_NYCKEL
```

I Supabase Authentication:

- Email login på
- Confirm email **av** under test (annars fastnar nya konton)

---

## 4. Firebase på iOS

1. Firebase Console → projekt `pawmatch-404e5` → iOS-appen `app.pawmatch`.
2. Ladda ner `GoogleService-Info.plist`.
3. Dra filen till `ios/Runner/` i Xcode. Bocka i **Copy items if needed** och target **Runner**.
4. Lägg **inte** plist i git.

Push (senare, när kontot är Active):

- Apple Developer → Keys → skapa APNs-nyckel
- Ladda upp `.p8` i Firebase → Cloud Messaging

Utan APNs funkar appen, men inte riktiga iPhone-pushar.

---

## 5. Öppna i Xcode och signera

```bash
open ios/Runner.xcworkspace
```

Använd **workspace** (vit ikon), inte `Runner.xcodeproj`.

1. Vänster: klicka **Runner** (blå ikon).
2. **Signing & Capabilities**.
3. Team = ditt Apple Developer-konto.
4. Bundle Identifier = `app.pawmatch`.
5. Automatically manage signing = på.

Koppla iPhone med kabel. Välj telefonen uppe till vänster. Tryck Play.

Första gången på telefonen: Inställningar → Allmänt → VPN och hantering av enhet → lita på utvecklaren.

---

## 6. TestFlight (när Enrollment är Active)

1. Gå till https://appstoreconnect.apple.com och logga in med samma Apple ID.
2. Appar → plus → ny app:
   - Plattform: iOS
   - Namn: PawMatch
   - Bundle ID: `app.pawmatch`
   - SKU: `pawmatch`
   - Språk: Svenska
3. I Xcode: Product → Archive.
4. När Archive är klar: Distribute App → App Store Connect → Upload.
5. App Store Connect → TestFlight → vänta på bearbetning (10–60 min).
6. Internal Testing → lägg till din Apple ID.
7. På iPhone: installera **TestFlight** från App Store → acceptera inbjudan → installera PawMatch.

Bygg IPA med samma nycklar:

```bash
flutter build ipa \
  --dart-define=SUPABASE_URL=https://DITT-PROJEKT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=DIN_NYCKEL
```

Sedan öppna `build/ios/archive/Runner.xcarchive` i Xcode och ladda upp.

Första TestFlight-bygget granskas av Apple (ofta 1 dygn). Interna testare i ditt team kan ibland testa snabbare.

---

## Vad du inte ska göra

- Inte logga in med systerns Apple ID i Xcode Signing.
- Inte lägga `GoogleService-Info.plist` eller nycklar i GitHub.
- Inte räkna med TestFlight medan det står Enrollment Pending.
