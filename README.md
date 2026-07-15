# GloomChat

A dark, quiet, end-to-end encrypted messenger for the [Matrix](https://matrix.org) network.

GloomChat is its own project. It speaks Matrix, runs anywhere Flutter runs, and is built for people who want their chat app to get out of the way and stay out of it.

---

## What it is

GloomChat is a Matrix client. That means:

- You pick (or run) a homeserver. GloomChat doesn't host anything.
- Your account, contacts, and history live on that homeserver — not on our infrastructure, because there isn't any.
- You can talk to anyone on any other Matrix client: Element, Nheko, NeoChat, SchildiChat, whatever they're using.
- Conversations are end-to-end encrypted by default, with cross-signing and device verification.

## What it isn't

- It is not a SaaS product. There is no GloomChat account, no telemetry, no analytics pipeline.
- It is not a drop-in replacement for any other client. Defaults, layout, and behavior are opinionated.

## Design principles

1. **Dark by default, dark on purpose.** GloomChat ships with a Dracula-based theme system and a small palette of accent colors. Light mode is not a priority.
2. **Adaptive, not uniform.** Mobile gets a drawer. Desktop and web get a persistent navigation rail and a multi-column layout. The same binary should feel native on a phone and a 4K monitor.
3. **Encryption is non-negotiable.** E2EE is on for new conversations, key backup is encouraged, and verification flows are surfaced rather than hidden.
4. **Fewer toggles, better defaults.** Settings exist where they earn their keep. The rest is decided for you.

## Platforms

| Platform | Status      |
|----------|-------------|
| Android  | Supported   |
| iOS      | Supported   |
| Linux    | Supported   |
| Windows  | Supported   |
| macOS    | Supported   |
| Web      | Supported   |

---

## Building

Requirements:

- [Flutter](https://flutter.dev) (stable channel, see [pubspec.yaml](pubspec.yaml) for the minimum SDK)
- [Rust](https://www.rust-lang.org/tools/install) (for the Vodozemac crypto library)
- Platform toolchain for whatever target you're building (Android SDK, Xcode, MSVC, etc.)

Get the source and fetch packages:

```bash
git clone https://github.com/afterdamage/gloomchat.git
cd gloomchat
flutter pub get
```

Run a debug build on whatever device is attached:

```bash
flutter run
```

### Android

```bash
flutter build apk --release
```

To enable Firebase Cloud Messaging on builds that need it:

```bash
./scripts/add-firebase-messaging.sh
```

UnifiedPush is supported out of the box for FOSS distributions.

### iOS / iPadOS

Requires macOS, Xcode, and a configured signing identity. The repo includes a helper script:

```bash
./scripts/build-ios.sh
```

Configure signing through the relevant `GLOOMCHAT_*` environment variables documented at the top of that script.

### Web

```bash
./scripts/prepare-web.sh
flutter build web --release
```

The build output in `build/web/` can be served by any static host. Drop a `config.json` next to `index.html` to override runtime defaults — see [config.sample.json](config.sample.json).

### Desktop

Make sure desktop support is enabled in your Flutter install, then:

```bash
flutter build linux --release      # Linux
flutter build windows --release    # Windows
flutter build macos --release      # macOS
```

On Debian-based Linux you'll need a few system libraries:

```bash
sudo apt install libsecret-1-dev libsecret-1-0 librhash0 libwebkit2gtk-4.0-dev libjsoncpp1
```

---

## Configuration

Most behavior is configurable at runtime through the in-app settings. For deployments (notably web), runtime defaults can be overridden via `config.json`. Every available key is listed in [config.sample.json](config.sample.json) — only set the keys you actually want to change; everything else falls back to a sensible default.

## Contributing

Pull requests are welcome. Before opening one, please read [CONTRIBUTING.md](CONTRIBUTING.md). Keep changes focused, run `flutter analyze` and `dart format .` before submitting, and explain *why* in the PR description, not just *what*.

Issue reports should include: platform, app version, homeserver software (if known), and concrete steps to reproduce.

## Security

If you believe you've found a security vulnerability, please follow the coordinated disclosure process described in [SECURITY.md](SECURITY.md). Do not file public issues for unpatched vulnerabilities.

## Privacy

GloomChat does not collect, transmit, or sell your data. The app talks to your homeserver and to whatever push relay you've configured, and that's it. See [PRIVACY.md](PRIVACY.md) for the full statement.

## License

See [LICENSE](LICENSE).

## Acknowledgements

GloomChat stands on the shoulders of the wider Matrix ecosystem — most directly the [matrix-dart-sdk](https://gitlab.com/famedly/company/frontend/famedlysdk), the [Vodozemac](https://github.com/matrix-org/vodozemac) cryptographic library, and the Flutter community. Thanks to everyone who built the pieces that made this possible.
