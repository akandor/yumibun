# Universal Links for shared mixes

The app shares mixes as `https://moodist.tpk.pw/?share=<encoded {id:volume}>` — the same
format the web app uses. For an installed app to intercept that link (instead of Safari
opening the site), iOS requires an **Apple App Site Association (AASA)** file on the domain.

## Deploy this file

Serve [`.well-known/apple-app-site-association`](.well-known/apple-app-site-association) at:

```
https://moodist.tpk.pw/.well-known/apple-app-site-association
```

Requirements (all mandatory, or iOS silently ignores it):

- **HTTPS** with a valid certificate.
- `Content-Type: application/json`.
- **No file extension** on the path, and **no redirects** to reach it.
- Reachable anonymously (no auth, no query string needed).

Verify:

```bash
curl -i https://moodist.tpk.pw/.well-known/apple-app-site-association
```

The `appIDs` value is `<TeamID>.<BundleID>` = `UE57845B3R.com.toepper.rocks.Moodist`.
The `components` entry matches only `/?share=...`, so ordinary pages keep opening in the
browser — only share links launch the app.

## App side (already done)

- `Moodist/Moodist.entitlements` declares `applinks:moodist.tpk.pw`
  (wired into both build configs via `CODE_SIGN_ENTITLEMENTS`).
- `ContentView` handles the incoming link (`onContinueUserActivity` /
  `NSUserActivityTypeBrowsingWeb`) and prompts to load the shared mix.
- The **App ID** in the Apple Developer portal must have the **Associated Domains**
  capability enabled for a device/TestFlight/App Store build to honor the entitlement.
  (Simulator builds work without it.)

## Fallback behavior

- App installed → tapping the link opens Moodist and offers to load the mix.
- App not installed → the exact same link opens `moodist.tpk.pw`, which reads
  `?share=` and renders the mix on the site.
