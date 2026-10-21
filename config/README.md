# Release build settings

`prod.json` holds the values every **release** build needs. Flutter reads it
with `--dart-define-from-file`, so nothing has to be typed by hand. Development
runs (`flutter run` without the flag) don't use it and stay out of Sentry.

| Key | What it is |
|---|---|
| `SENTRY_DSN` | Sentry project DSN (Sentry → Settings → Projects → your Flutter project → Client Keys). Empty = error reporting off. Not a secret: it only allows *sending* errors to the project. |
| `SENTRY_ENV` | Label shown in Sentry for these builds (`production`). |

## Releasing

First bump the version with the release script (repo root). It commits
and tags the release:

```bash
./scripts/release-mobile.sh patch   # or minor / major / build
```

Then build with the commands below.

## Build commands (run from `apps/mobile`)

```bash
# Android: APK (direct install / testing)
flutter build apk --release --dart-define-from-file=config/prod.json

# Android: App Bundle (Google Play upload)
flutter build appbundle --release --dart-define-from-file=config/prod.json

# iPhone: archive for App Store / TestFlight (needs Xcode + CocoaPods)
flutter build ipa --release --dart-define-from-file=config/prod.json

# Run a release build on a connected phone, with Sentry on
flutter run --release --dart-define-from-file=config/prod.json
```

## Android signing

Google Play refuses debug-signed uploads. Release builds use the upload key
named in `android/key.properties` (both the key and that file are
git-ignored; without them, release builds fall back to debug keys).

One-time setup, from `apps/mobile`:

```bash
keytool -genkey -v -keystore ~/dirassti-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties`:

```properties
storePassword=<the password you chose>
keyPassword=<the same password>
keyAlias=upload
storeFile=/Users/<you>/dirassti-upload-keystore.jks
```

Back up the `.jks` file and its password somewhere safe (password manager).
With Play App Signing (the default for new apps), Google holds the real app
key; if this upload key is lost, Google can reset it on request.

To point a test build at the local web server, add
`--dart-define=API_BASE_URL=http://<your-mac-ip>:3000` to any command above.

## Every release: bump the version, then tell the app about it

Full team guide (when to raise which number, backend compatibility,
hotfixes): `docs/mobile-releases.md`.

The update check compares the installed version with what an admin sets in
**Admin → Plans → Mises à jour de l'application**. So for every release:

1. In `pubspec.yaml`, raise `version:`. The part before `+` is the version
   users see (`1.0.3`), the number after `+` is the build number, which must
   always go up. Example: `1.0.2+5` becomes `1.0.3+6`.
2. Build with the commands above and publish (Play Store / App Store / APK link).
3. Once it's downloadable, set **Dernière version publiée** to the new version
   (e.g. `1.0.3`). Users on older versions get "Nouvelle version disponible".
4. Only when old versions must stop working (breaking change, critical fix,
   database change), also set **Version minimale** to the new version: older
   apps are then blocked until they update.

Set the version for a platform only once that platform's update is really
available: Apple review can take a few days longer than Google Play.
