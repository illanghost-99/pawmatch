# PawMatch 2.0 — arkitektur

Vision: Sveriges ekosystem för hundägare. Inte en dating-app.
Apple-kategori: Lifestyle. Inte Dating.

## Vad som redan finns i v1 (TestFlight)
- Konto (e-post, Face ID)
- Onboarding + intressen
- Hundprofil, minst 2 bilder
- Swipe / Matcha / För dig + könsfilter
- Chatt efter godkänd match
- Parningsavtal med finger-signatur (båda parter)
- Support-AI (regelbaserad)
- Rapport/block-grunder
- Supabase-schema för profiler, hundar, likes, matcher, chatt

## V2-lager (den här releasen)
Nya skärmar under Profil, utan att riva v1-flödet:
- Hälsotidslinje
- Stamtavla (manuell + uppladdning)
- Community (träffar, parker, promenader)
- PawMatch AI Vet (sammanfattning, ingen diagnos)
- Guardian-flaggor (moderering, ingen autoblock)
- Verifieringsnivåer (1–5, BankID är framtida)
- Premium-placeholder (StoreKit kommer separat)

## Backend
Ett system: **Supabase** (Auth, Postgres, Storage, Realtime).
Firebase bara för APNs om det behövs senare.

Nya tabeller: `health_events`, `pedigree_nodes`, `documents`, `events`, `reports`, `verification`, `premium`.

## AI
- AI Vet: sammanfattar användarens egna uppladdningar. Alltid disclaimer.
- Guardian: heuristik + kö för admin. Aldrig automatisk avstängning i v2.0.
- Inget lyssnande på privat chatt utan uttryckligt samtycke (GDPR + Apple 1.2).

## Betalningar
Premium = Apple In-App Purchase (riktlinje 3.1.1).
Fysiska varor / provision på valp = inte IAP, inte i denna release.
BankID = separat avtal, ~40 kkr/år — avstängt tills budget finns.

## Skala mot 100M
Idag: Sverige. Datamodellen är landsagnostisk (`country`, `locale`, `city`).
Geo: lat/lng + radie. Senare PostGIS.
Media: Supabase Storage + CDN.
Chat: Realtime-kanaler per match.
Rate limit på likes/chatt i edge functions.

## Juridik som styr implementationen
- Ingen SKK-skrapning.
- AI är inte veterinär.
- Avtal är inte juridiskt granskad mall för SKK-överlåtelse.
- Personnummer: minimera. V2 föredrar e-post + telefon + åldersintyg.
- 18+ för avelsavtal.
