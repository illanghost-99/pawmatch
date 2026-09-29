# Face ID och push

## Notiser i v1 (klart i koden)
Appen visar en notis på telefonen när:
- någon matchar
- någon skriver
- en hund publiceras

Det är **lokala notiser**. De funkar när appen är öppen eller i bakgrunden på samma telefon.

## Xcode — gör en gång
1. TARGETS → Runner → Signing & Capabilities
2. + Capability → **Push Notifications**
3. Spara

Telefonen frågar om tillåtelse första gången du öppnar den nya builden. Tryck Tillåt.

## Riktig push när appen är avstängd (senare)
Kräver APNs-nyckel (.p8) + Firebase Cloud Messaging.
1. developer.apple.com → Keys → Create APNs key
2. Ladda upp .p8 i Firebase → Cloud Messaging
3. Lägg GoogleService-Info.plist i ios/Runner/
4. Då kan en server skicka notis till en annan användares iPhone
