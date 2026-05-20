# GloomChat Windows Installer

## Prerequisites

1. **Inno Setup 6** — download from https://jrsoftware.org/isinfo.php
2. **Flutter Windows build** — must be built before running the installer script

## Build steps

```powershell
# 1. Build the Flutter Windows release
flutter build windows --release

# 2. Open Inno Setup Compiler and compile gloomchat.iss
#    OR compile from the command line:
iscc windows\installer\gloomchat.iss
```

The installer EXE is written to:
```
build\windows\installer\GloomChat-Setup-2.4.0.exe
```

## Optional wizard graphics

Inno Setup 6 with `WizardStyle=modern` accepts two optional BMP images:

| File | Size | Purpose |
|------|------|---------|
| `wizard_banner.bmp` | 164 × 314 px | Left-side sidebar shown on every page |
| `wizard_icon.bmp` | 55 × 55 px | Small logo shown top-right of the wizard header |

Place both files next to `gloomchat.iss`. If omitted, Inno Setup uses its own default graphics.

## Updating the version

The version is defined at the top of `gloomchat.iss`:
```
#define MyAppVersion "2.4.0"
```

Keep it in sync with the `version:` field in `pubspec.yaml`.
