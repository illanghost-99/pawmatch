# Face ID och push

## Face ID / biometri
- Paket: `local_auth`
- iOS: lägg `NSFaceIDUsageDescription` i Info.plist
- Anrop: `Biometrics.unlock()` vid återkomst till appen eller känsliga lägen

## Push (match, chatt, godkännande)
1. Skapa Firebase-projekt (gratis)
2. Lägg till iOS-app + ladda upp APNs-nyckel (kräver Apple Developer + Mac)
3. `flutterfire configure`
4. Byt `PushService` till FirebaseMessaging
5. Spara FCM-token i Supabase `profiles.fcm_token`
6. Edge Function skickar notis vid: ny match, nytt meddelande, pedigree/vaccine approved

Tills APNs finns fungerar lokala debugPrint + in-app banners.
