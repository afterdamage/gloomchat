# Contributing to GloomChat

Thanks for taking the time. This document covers everything you need to know before sending a pull request.

---

## Before you start

GloomChat moves fast and has strong opinions about its defaults and design direction. To avoid putting in work that doesn't land:

- **Bug fixes and small improvements** — just open a PR.
- **New features or behavior changes** — open an issue first. Describe what you want to change and why. Wait for a maintainer to say go before writing code.
- **Theme / visual changes** — same as above. Screenshots in the issue help.

If you're unsure whether something is in scope, ask in an issue.

---

## Setting up

1. Fork `https://github.com/afterdamage/gloomchat` and clone your fork.
2. Make sure you have [Flutter](https://flutter.dev) (stable channel) and [Rust](https://www.rust-lang.org/tools/install) installed.
3. Run `flutter pub get` to fetch dependencies.
4. Run `flutter run` against a device or emulator to verify everything works before making changes.

If you want to run the repository's test suites, see the `test/` and `integration_test/` directories. Integration tests require Docker and a local homeserver.

---

## Making changes

### Keep it focused

One pull request = one concern. If you find yourself fixing two unrelated things, split them into two PRs. Reviewers should be able to reason about a change without context-switching.

### Commit style

GloomChat uses [Conventional Commits](https://www.conventionalcommits.org):

```
feat: add purple accent color option
fix: prevent crash when opening empty chat
refactor: extract message bubble padding to token
docs: update build instructions for Linux
```

- Use the imperative mood ("add", not "adds" or "added").
- Keep the subject line under 72 characters.
- If the change is non-obvious, add a body explaining the *why*.
- One commit per PR wherever possible. Use `git rebase -i` to clean up before submitting.
- No merge commits. Rebase onto `main`.
- [Sign your commits.](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)

---

## Code conventions

The app source is under `/lib`. Entry point: `lib/main.dart`.

### Structure

```
lib/
├── config/       — App-wide constants, AppConfig, theme wiring
├── l10n/         — Localization ARB files
├── pages/        — One folder per feature; each split into controller + view
├── theme/        — Dracula theme system (base, accents, tokens)
├── utils/        — Stateless helpers and extensions
└── widgets/      — Shared, reusable widgets
```

### Controller / View split

Every page is a pair:

| File | Type | Responsibility |
|------|------|----------------|
| `foo.dart` | `StatefulWidget` + `State` (controller) | State, actions, lifecycle |
| `foo_view.dart` | `StatelessWidget` (view) | Widget tree only |

The controller's `build` method returns the view, passing `this`:

```dart
@override
Widget build(BuildContext context) => FooView(this);
```

The view takes the controller as its only constructor parameter and calls back into it directly. Views must not compute, derive, or decide anything — if logic is needed, it belongs in the controller or in a `/lib/utils/` helper.

### Naming

- Files: `lower_snake_case.dart`
- Controller classes: `FooController` (the `State<T>` subclass)
- View classes: `FooView`
- Widgets that are not page-level can omit the suffix if the name is clear

### Theming

Use Dracula tokens — not hardcoded hex values. All tokens are in `lib/theme/`. If a color you need doesn't exist as a token, add it there first.

---

## Before submitting

Run both of these and fix any issues:

```bash
dart format lib
flutter analyze
```

For test coverage, also run:

```bash
flutter test test
```

To run integration tests locally:

```bash
./scripts/prepare_integration_test.sh
flutter test integration_test/mobile_test.dart
```

PRs that fail formatting or analysis will not be merged.

---

## Pull request checklist

- [ ] Issue linked (if applicable)
- [ ] Only changes what the PR title claims
- [ ] Single clean commit (or clearly scoped commits for larger changes)
- [ ] `dart format lib` clean
- [ ] `flutter analyze` clean
- [ ] Tested on at least one platform

---

## Code of conduct

Be direct, be kind, assume good intent. Disrespectful or hostile behavior will get you removed.
