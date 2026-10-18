# Quiet Places

**Your phone goes quiet where it should, and back to normal when you leave.**

Save the places where your phone should hush — a cinema, an office, a bedroom.
Quiet Places switches to silent, vibrate or Do Not Disturb when you arrive and
restores your ringer exactly as you had it when you leave.

- Uses the operating system's geofencing (`native_geofence`), so it keeps
  working with the app closed and survives a reboot.
- Records the ringer state before changing it and restores that — and stops
  managing a place if you change the ringer yourself while there.
- Live distance and inside/outside to every place, with honesty about GPS
  accuracy.
- Map editor on OpenStreetMap (`flutter_map`): drag the pin and the edge.
- Offline by default: no account, no analytics; maps are opt-in.
- A custom platform plugin, [`packages/native_ringer`](packages/native_ringer),
  controls the ringer and Do Not Disturb modes.

Store copy and screenshots: [`docs/store/listing.md`](docs/store/listing.md).

## Platform

Quiet Places is released for **Android only**. Changing the ringer and Do Not
Disturb from a geofence callback is an Android capability; iOS offers no API for
it, and the desktop and web have neither geofencing nor a ringer.

Android permissions (all declared in `android/app/src/main/AndroidManifest.xml`):
fine, coarse and background location plus a short-lived `location` foreground
service for geofencing; Do Not Disturb (notification policy) access; battery
optimisation exemption; notifications; and internet for map tiles once maps are
enabled.

## Running

```bash
flutter pub get
flutter run            # on an Android device or emulator
flutter analyze && flutter test
```

## Website, releases and downloads

- **Website** — [`site/`](site/) is a static landing page (no build step).
  [`.github/workflows/pages.yml`](.github/workflows/pages.yml) runs analyze and
  tests, then publishes it to GitHub Pages on every push to `main`, copying in
  the screenshots from `docs/store/`. One-time setup: *Settings → Pages →
  Source: GitHub Actions*. Its download buttons point at the latest release's
  APK via the GitHub API.
- **Android app** — [`.github/workflows/release.yml`](.github/workflows/release.yml)
  builds `quiet-places-android.apk` and attaches it to a GitHub Release when a
  version tag is pushed:

  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```

### Android signing

Android only installs an update over an existing app when both are signed with
the same key. Create a key once, keep it outside the repository, and never
commit it (`*.jks`, `*.keystore` and `key.properties` are git-ignored).

```bash
keytool -genkeypair -v -keystore ~/quiet-places-release.jks -storetype PKCS12 \
  -keyalg RSA -keysize 4096 -validity 10000 -alias quiet-places
base64 -i ~/quiet-places-release.jks | pbcopy   # macOS; Linux: base64 -w0 …
```

Add four repository secrets under *Settings → Secrets and variables → Actions*:
`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`
(`quiet-places`) and `ANDROID_KEY_PASSWORD` (same password for PKCS12). Set all
four or none; without them the APK is signed with a throwaway debug key.
