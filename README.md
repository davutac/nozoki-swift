# Nozoki Swift SDK

Privacy-friendly app analytics for Apple platforms. Send named events ("signals") from your app; the SDK enriches them with app and device metadata, batches them and delivers them to Nozoki.

- iOS 12+, macOS 10.13+, watchOS 5+, tvOS 13+, visionOS 1+
- No third-party dependencies

This is a fork of [TelemetryDeck's SwiftSDK](https://github.com/TelemetryDeck/SwiftSDK) 2.14.2 (commit `58f4362`), used under its license (MIT without the attribution clause, see `LICENSE`). The module and API are renamed to `Nozoki`, it sends to Nozoki by default and keeps its data apart from TelemetryDeck's on the device. The wire protocol is unchanged, so Nozoki also accepts signals from the official TelemetryDeck SDK pointed at it with `baseURL`.

## Installation (Swift Package Manager)

**Xcode:** File > Add Package Dependencies…, enter `https://github.com/davutac/nozoki-swift`, then add the `Nozoki` library to your app target.

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/davutac/nozoki-swift", from: "0.2.0"),
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "Nozoki", package: "nozoki-swift"),
    ]),
]
```

## Quick start

```swift
import SwiftUI
import Nozoki

@main
struct MyApp: App {
    init() {
        Nozoki.initialize(config: .init(appID: "YOUR-APP-ID"))
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

// Anywhere in your app:
Nozoki.signal("Settings.opened", parameters: ["tab": "privacy"])

// Optional: identify the user (hashed before it leaves the device).
Nozoki.updateDefaultUserID(to: account.id)

// Optional: send now instead of at the next interval.
Nozoki.requestImmediateSync()
```

The app ID is on the app's Settings page in the dashboard. Signals go to `https://app.nozoki.app` unless you pass `baseURL` (the dashboard's setup snippet does, for development deployments).

Beyond `signal`, the SDK has helpers for durations (`startDurationSignal` / `stopAndSendDurationSignal`), navigation (`navigationPathChanged`, the `trackNavigation` view modifier), errors (`errorOccurred`), purchases and acquisition / activation / referral / revenue events.

### Configuration

`Nozoki.Config` (an alias of `TelemetryManagerConfiguration`) is a class: create it, adjust properties, then pass it to `initialize`.

```swift
let config = Nozoki.Config(appID: "…")
config.testMode = isTestFlight        // default: true in DEBUG builds, false otherwise
config.transmitInterval = 10          // seconds between sends (the default)
config.defaultUser = account.id       // otherwise identifierForVendor, or a generated ID on macOS
config.analyticsDisabled = !userOptedIn
Nozoki.initialize(config: config)
```

## Delivery

- Signals are cached (on disk across launches, up to 10,000) and sent in batches of up to 100 every `transmitInterval` seconds.
- 2xx means delivered. 400, 401, 403, 404 (unknown app ID), 413, 422, 501 and 505 drop the batch, since it would never succeed. Anything else, including 429 (rate limited), 5xx and network errors, keeps it and retries with exponential backoff up to `maxBackoffInterval` (5 minutes).
- The server records signals at delivery time, so signals that wait in the cache are counted on the day they arrive.

## What is collected

Every signal carries the hashed user ID (`clientUser`), a session ID, `isTestMode`, its type, optional `floatValue` and a payload: your `parameters` plus the SDK's default parameters (app version and build, platform, OS version, device model, locale, accessibility settings, calendar context, session counts and more, under `TelemetryDeck.*` keys).

The server keeps app version, build, platform, OS version, device model, locale and SDK version as columns, stores your own parameters (plus `floatValue` and the SDK's navigation, error and purchase parameters, shown with a `Nozoki.` prefix) and discards the other defaults. Payloads keep up to 32 keys; keys are cut at 64 characters, values at 256.

The SDK also sends a `Nozoki.Session.started` signal at the start of each session (`sendNewSessionBeganSignal`).

## Test mode

Signals carry `isTestMode`. It defaults to `true` in DEBUG builds, so data from development and simulators stays out of the dashboard's numbers unless you switch on test mode there. Set `config.testMode` explicitly to change that, e.g. for TestFlight builds.

## Privacy

- The user identifier never leaves the device in plain text: the SDK sends a salted SHA-256 hash of it (`salt` in the config), and the server hashes it again with the app ID.
- Hashing is pseudonymization: a guessable value such as an email address can be recovered by brute force. Prefer an opaque account ID.
- Payloads are sent as-is; don't put personal data in them.
- `PrivacyInfo.xcprivacy` declares the data the SDK collects.

## Development

```sh
swift build
swift test
```

### Pulling upstream changes

This repository keeps TelemetryDeck's history, so their fixes merge in:

```sh
git remote add upstream https://github.com/TelemetryDeck/SwiftSDK.git
git fetch upstream
git merge upstream/main
```

Files they add or rename come in under `TelemetryDeck` names; rename them, keep the `"TelemetryDeck.*"` parameter keys (they're the wire protocol) and run the tests.
