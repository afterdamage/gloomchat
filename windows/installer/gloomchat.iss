; GloomChat Windows Installer — Inno Setup 6 script
; Build with: iscc gloomchat.iss
; Requires Inno Setup 6.x: https://jrsoftware.org/isinfo.php

#define MyAppName      "GloomChat"
#define MyAppVersion   "2.4.0"
#define MyAppPublisher "Afterdamage"
#define MyAppURL       "https://www.gloomchat.com"
#define MyAppExeName   "afterdamage.exe"
#define MyAppId        "{8A3F2B4C-1D9E-4F7A-B6C2-3E5D8F9A0B1C}"

; Path to the Flutter Windows release build output.
; Run `flutter build windows --release` first.
#define BuildDir "..\..\build\windows\x64\runner\Release"

[Setup]
AppId={{#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
; Require admin only if installing to Program Files; otherwise user-level is fine.
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\..\build\windows\installer
OutputBaseFilename=GloomChat-Setup-{#MyAppVersion}
SetupIconFile=..\runner\resources\app_icon.ico
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
; Minimum Windows version: Windows 10 (Flutter requirement)
MinVersion=10.0.17763
ArchitecturesInstallIn64BitMode=x64compatible
; Show a license page (optional — create a LICENSE.txt to enable)
; LicenseFile=..\..\LICENSE.txt

; Wizard appearance
WizardImageFile=wizard_banner.bmp
WizardSmallImageFile=wizard_icon.bmp
WizardImageStretch=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
; Main executable
Source: "{#BuildDir}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion

; Flutter engine and app DLLs
Source: "{#BuildDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#BuildDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#BuildDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist
Source: "{#BuildDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

; App data directory (Flutter assets, ICU data, etc.)
Source: "{#BuildDir}\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

; Any additional plugin DLLs Flutter may have placed next to the exe
Source: "{#BuildDir}\*.dll"; DestDir: "{app}"; Flags: ignoreversion skipifsourcedoesntexist

[Icons]
; Start Menu shortcut
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"

; Optional desktop shortcut (created only if the task is checked)
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Remove any leftover user-data caches written to the install dir (none expected,
; but this is a safety net for any temp files the app may create there).
Type: filesandordirs; Name: "{app}\cache"
