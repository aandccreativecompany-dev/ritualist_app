# Releasing

Distribution is a signed APK attached to a GitHub Release. No Play Console fee,
no review, no subscription billing.

## One-time setup

### 1. Create the upload keystore

```
keytool -genkey -v -keystore ritualist-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep this file and its passwords forever. A different key on a later version
forces every user to uninstall and lose their data. Back it up offline and store
the passwords in a password manager. It is gitignored — never commit it.

### 2. Point Gradle at it

Create `android/key.properties` (gitignored):

```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=../ritualist-upload.jks
```

Then wire the release `signingConfig` in `android/app/build.gradle` to read it.

### 3. Add the repository secrets

For the automated build, in Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | `base64 -i ritualist-upload.jks` output |
| `KEYSTORE_PASSWORD` | store password |
| `KEY_PASSWORD` | key password |
| `KEY_ALIAS` | `upload` |

## Cutting a release

1. Merge `dev` into `main`.
2. Bump `version:` in `pubspec.yaml` — the build number after `+` must increase
   every single time.
3. Tag and push:

```
git tag v0.1.0
git push origin v0.1.0
```

The `release.yml` workflow builds the signed APK and attaches it to a draft
release. Open the release, write the notes, publish.

The permanent link to hand to users:
`https://github.com/aandccreativecompany-dev/ritualist-app/releases/latest`

## Release notes template

```
## What's new
- ...

## Install
1. Download the APK below.
2. When your phone asks, allow installs from this source.
3. If a screen says the app is unrecognised or unsafe, tap
   More details → Install anyway. This warning is normal for apps
   installed outside the Play Store.
4. Open Ritualist and allow notifications so your reminders arrive.

Want automatic updates? Install Obtainium, point it at this repository once,
and it will update Ritualist for you.
```

Expect to lose people at the Play Protect warning. Saying up front that it is
normal recovers a good share of them.

## Manual build, if the workflow is not set up yet

```
flutter build apk --release
```

Output at `build/app/outputs/flutter-apk/app-release.apk`. Rename it
`ritualist-0.1.0.apk` before attaching, so the version is visible in the download.
