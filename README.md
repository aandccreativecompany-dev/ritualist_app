# Ritualist

A daily planner for Android. Three priorities a day, habits, a mantra each morning,
and reminders that reach you when you're too busy to open the app.

Built and maintained by A&C Creative Company.

## Status

Design complete, app not yet built. The screen designs live in `design/` and the
build order is in `docs/BUILD_PLAN.md`.

## Stack

- Flutter (Dart) — one codebase, Android first
- Local storage first: the app works with no network
- Local scheduled notifications for reminders (no server, no push infrastructure)
- Distribution: signed APK on GitHub Releases (see `docs/RELEASING.md`)

## Getting started

```
flutter pub get
flutter run
```

Requires Flutter with the Android SDK. Run `flutter doctor` and clear every
warning before starting.

## Package name

`ai.aandccreative.ritualist` — permanent once published. Do not change it.

## Branches

- `main` — what ships. Tagged releases are cut from here.
- `dev` — active work. Merge into `main` when a release is ready.

## Design reference

`design/AC Planner App.dc.html` holds the full screen set. Open it in a browser.
Screens are labelled `2a` through `2t`; `docs/BUILD_PLAN.md` maps them to build
order.

`design/Ritualist - Ship to Play Store.dc.html` is the publishing guide, including
the GitHub Releases route this repo uses.

## Licence

Proprietary. All rights reserved, A&C Creative Company.
