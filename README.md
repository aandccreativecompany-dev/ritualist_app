# Ritualist

A daily planner for Android. Three priorities a day, habits, a mantra each morning,
and reminders that reach you when you're too busy to open the app.

Built and maintained by A&C Creative Company.

## Status

v0.1 — working app, all local-only screens built. No accounts, no paywall,
no server: everything designed around Supabase sign-in and Play Billing stays
un-built until that's explicitly turned back on (see "Not in this build" below).

## What's in v0.1

- Home card stack: date, mantra, top three priorities, habits — reorderable
  and hideable from Settings or the first-run quiz
- Habit streaks and a five-week history grid
- Three daily local reminders: 7:30am mantra + priorities, a 1pm check that
  only fires if something's still open, a 9pm close-the-day
- Onboarding: welcome → a short quiz that sets a preset → the module picker.
  Runs once; retakeable from Settings any time
- Scripting (outcome engineering): write the outcome you want as if it
  already happened
- Quote of the day: today's mantra, full-screen and shareable
- Weekly momentum review: priorities finished and habit check-ins over the
  last 7 days
- Evening reflection: two short prompts, locked behind an optional PIN with
  biometric unlock on top
- Vision board: a grid of captioned placeholder tiles (no photo picker —
  no raster assets ship with the app)
- Light and dark, following the phone, overridable in Settings
- Copy-and-paste backup, because there are no accounts

## Not in this build

Sign-in (email/Google/phone OTP) and the paywall are designed (see `design/`)
but deliberately not built: v0.1 is accounts-free and free of charge, per the
product decisions in the design handoff. Wiring up real sign-in needs a
Supabase project; the paywall needs Google Play Billing product IDs. Both are
future work, not bugs.

## Stack

- Flutter (Dart) — one codebase, Android first
- Local storage first: the app works with no network
- Local scheduled notifications for reminders (no server, no push infrastructure)
- Distribution: an APK on GitHub Releases (see `docs/RELEASING.md`); Play
  Store submission is future work

## Getting started

```
flutter pub get
flutter run
```

Requires Flutter with the Android SDK. Run `flutter doctor` and clear every
warning before starting. There's no `android/` folder committed — see
"Building" below.

## Building

You don't need Flutter installed to get an APK:

- **Quick/debug build**: Actions tab → **Build APK (debug, manual)** → **Run
  workflow**. Downloads as a build artifact from the run page. No signing
  secrets required — this is what most contributors want.
- **Signed release**: push a `v*` tag. The **Release APK** workflow builds a
  signed APK and drafts a GitHub Release, but only once the repo has
  `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD` and `KEY_ALIAS`
  secrets set (Settings → Secrets and variables → Actions). Until those
  exist, don't push a tag — the workflow will fail at the signing step.

Both workflows generate `android/` fresh via `flutter create` and layer
`android_overrides/AndroidManifest.xml` on top — the repo deliberately holds
no Gradle wrapper. See `docs/RELEASING.md` for the full release process and
`docs/FINDING_BUILD_ERRORS.md` if a run fails.

## Package name

`ai.aandccreative.ritualist` — permanent once published. Do not change it.

## Design reference

`design/AC Planner App.dc.html` holds the full 20-screen design set (dark and
light) — everything above plus the not-yet-built sign-in and paywall screens.
Open it in a browser. Screens are labelled `2a` through `2t`.

`design/Ritualist - Ship to Play Store.dc.html` is the publishing guide,
including the GitHub Releases route this repo currently uses.

## Licence

Proprietary. All rights reserved, A&C Creative Company.
