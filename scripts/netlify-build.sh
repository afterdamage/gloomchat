#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.3}"
FLUTTER_DIR="$HOME/flutter"

# ── Flutter ────────────────────────────────────────────────────────────────────
echo "==> Installing Flutter $FLUTTER_VERSION"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

echo "==> Flutter doctor"
flutter doctor -v

echo "==> Getting dependencies"
flutter pub get

# ── Rust ───────────────────────────────────────────────────────────────────────
echo "==> Setting up Rust"
if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
export PATH="$HOME/.cargo/bin:$PATH"
rustup default stable
# flutter_rust_bridge_codegen build-web forces RUSTUP_TOOLCHAIN=nightly and
# uses -Z build-std, which requires nightly + rust-src component.
rustup toolchain install nightly
rustup component add rust-src --toolchain nightly
rustup target add wasm32-unknown-unknown
rustup target add wasm32-unknown-unknown --toolchain nightly

# ── yq ─────────────────────────────────────────────────────────────────────────
echo "==> Ensuring yq is available"
if ! command -v yq &>/dev/null; then
  curl -sSL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o "$HOME/.cargo/bin/yq"
  chmod +x "$HOME/.cargo/bin/yq"
fi

# ── Vodozemac (Rust → WASM) ────────────────────────────────────────────────────
echo "==> Building Vodozemac for web"
VODOZEMAC_VERSION=$(yq ".dependencies.flutter_vodozemac" < pubspec.yaml | sed 's/^\^//')
git clone --depth 1 https://github.com/famedly/dart-vodozemac.git -b "${VODOZEMAC_VERSION}" .vodozemac
cd .vodozemac
cargo install flutter_rust_bridge_codegen --locked
flutter_rust_bridge_codegen build-web \
  --dart-root dart \
  --rust-root "$(readlink -f rust)" \
  --release
cd ..
rm -f ./assets/vodozemac/vodozemac_bindings_dart*
mv .vodozemac/dart/web/pkg/vodozemac_bindings_dart* ./assets/vodozemac/
rm -rf .vodozemac

# ── native_imaging ─────────────────────────────────────────────────────────────
echo "==> Downloading native_imaging for web"
NATIVE_IMAGING_VERSION=$(yq ".dependencies.native_imaging" < pubspec.yaml | sed 's/^\^//')
curl -fsSL "https://github.com/famedly/dart_native_imaging/releases/download/v${NATIVE_IMAGING_VERSION}/native_imaging.zip" \
  -o native_imaging.zip
unzip -q native_imaging.zip
mv js/* web/
rmdir js
rm native_imaging.zip

# ── Dart web worker ────────────────────────────────────────────────────────────
echo "==> Compiling native_executor.js web worker"
flutter pub get
dart compile js ./web/native_executor.dart -o ./web/native_executor.js -m

# ── Flutter web build ──────────────────────────────────────────────────────────
echo "==> Building web"
flutter build web --release --no-tree-shake-icons

echo "==> Copying config"
cp config.sample.json build/web/config.json

echo "==> Injecting optional Google site verification file"
if [ -n "${GOOGLE_SITE_VERIFICATION_FILENAME:-}" ] && [ -n "${GOOGLE_SITE_VERIFICATION_CONTENT:-}" ]; then
  printf "%s\n" "$GOOGLE_SITE_VERIFICATION_CONTENT" > "build/web/$GOOGLE_SITE_VERIFICATION_FILENAME"
  echo "Created build/web/$GOOGLE_SITE_VERIFICATION_FILENAME"
else
  echo "Skipping Google site verification injection (env vars not set)"
fi

echo "==> Injecting optional Google site verification meta tag"
if [ -n "${GOOGLE_SITE_VERIFICATION_META_CONTENT:-}" ]; then
  meta_tag="<meta name=\"google-site-verification\" content=\"$GOOGLE_SITE_VERIFICATION_META_CONTENT\" />"
  for page in build/web/index.html build/web/landing.html; do
    if [ -f "$page" ]; then
      if grep -q 'name="google-site-verification"' "$page"; then
        echo "Meta verification tag already present in $page"
      else
        awk -v tag="  $meta_tag" '
          BEGIN { inserted = 0 }
          /<\/head>/ && !inserted { print tag; inserted = 1 }
          { print }
        ' "$page" > "$page.tmp" && mv "$page.tmp" "$page"
        echo "Injected meta verification tag in $page"
      fi
    fi
  done
else
  echo "Skipping Google meta verification injection (env var not set)"
fi

echo "==> Build complete. Publish directory: build/web"
