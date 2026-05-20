#!/usr/bin/env bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
USER_HOME="${HOME}"

# Pinned to the repo's tool versions.
FLUTTER_VERSION="3.41.5"
FLUTTER_DIR="${USER_HOME}/flutter-sdk"

# Android SDK defaults. Override these before running if needed.
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${USER_HOME}/Android/Sdk}"
ANDROID_CMDLINE_TOOLS_DIR="${ANDROID_SDK_ROOT}/cmdline-tools/latest"
ANDROID_PLATFORM="android-35"
ANDROID_BUILD_TOOLS="35.0.0"
ANDROID_NDK_VERSION="27.0.12077973"

JAVA_HOME_DEFAULT="/usr/lib/jvm/java-21-openjdk-amd64"
JAVA_HOME="${JAVA_HOME:-${JAVA_HOME_DEFAULT}}"

log() {
  printf '\n==> %s\n' "$1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

install_apt_packages() {
  log "Installing host packages"
  sudo apt-get update
  sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    ca-certificates \
    openjdk-21-jdk \
    build-essential \
    clang \
    lld \
    pkg-config \
    cmake \
    ninja-build \
    libgtk-3-dev \
    libsecret-1-dev \
    libjsoncpp-dev \
    libstdc++-13-dev
}

install_flutter() {
  log "Installing non-Snap Flutter ${FLUTTER_VERSION}"
  if [[ ! -d "${FLUTTER_DIR}" ]]; then
    git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git "${FLUTTER_DIR}"
  else
    git -C "${FLUTTER_DIR}" fetch --depth 1 origin "${FLUTTER_VERSION}"
    git -C "${FLUTTER_DIR}" checkout "${FLUTTER_VERSION}"
  fi

  export PATH="${FLUTTER_DIR}/bin:${PATH}"
  hash -r

  if [[ "$(command -v flutter)" == /snap/* ]]; then
    echo "flutter still resolves to Snap: $(command -v flutter)" >&2
    echo "Adjust PATH so ${FLUTTER_DIR}/bin comes first, then rerun." >&2
    exit 1
  fi

  flutter --version
}

install_android_sdk() {
  log "Installing Android command-line tools"
  mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools"

  if [[ ! -x "${ANDROID_CMDLINE_TOOLS_DIR}/bin/sdkmanager" ]]; then
    tmp_zip="$(mktemp /tmp/android-cmdline-tools.XXXXXX.zip)"
    curl -fsSL \
      https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip \
      -o "${tmp_zip}"

    tmp_dir="$(mktemp -d /tmp/android-cmdline-tools.XXXXXX)"
    unzip -q "${tmp_zip}" -d "${tmp_dir}"
    rm -f "${tmp_zip}"

    rm -rf "${ANDROID_CMDLINE_TOOLS_DIR}"
    mkdir -p "${ANDROID_CMDLINE_TOOLS_DIR}"
    mv "${tmp_dir}/cmdline-tools/"* "${ANDROID_CMDLINE_TOOLS_DIR}/"
    rm -rf "${tmp_dir}"
  fi

  export ANDROID_SDK_ROOT
  export ANDROID_HOME="${ANDROID_SDK_ROOT}"
  export PATH="${ANDROID_CMDLINE_TOOLS_DIR}/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"

  set +o pipefail
  yes | sdkmanager --licenses >/dev/null
  set -o pipefail
  sdkmanager \
    "platform-tools" \
    "platforms;${ANDROID_PLATFORM}" \
    "build-tools;${ANDROID_BUILD_TOOLS}" \
    "cmdline-tools;latest" \
    "ndk;${ANDROID_NDK_VERSION}"
}

install_rust() {
  log "Installing Rust toolchain required by flutter_vodozemac"
  if [[ ! -x "${USER_HOME}/.cargo/bin/rustup" ]]; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
  fi

  # shellcheck disable=SC1091
  source "${USER_HOME}/.cargo/env"
  rustup default stable
  rustup target add \
    aarch64-linux-android \
    armv7-linux-androideabi \
    x86_64-linux-android \
    i686-linux-android

  rustc -Vv
}

write_local_properties() {
  log "Updating android/local.properties"
  cat > "${REPO_DIR}/android/local.properties" <<EOF
sdk.dir=${ANDROID_SDK_ROOT}
flutter.sdk=${FLUTTER_DIR}
flutter.buildMode=debug
flutter.versionName=2.4.0
flutter.versionCode=3546
EOF
}

prepare_env() {
  export JAVA_HOME
  export PATH="${JAVA_HOME}/bin:${PATH}"
  export ANDROID_SDK_ROOT
  export ANDROID_HOME="${ANDROID_SDK_ROOT}"
  export PATH="${ANDROID_CMDLINE_TOOLS_DIR}/bin:${ANDROID_SDK_ROOT}/platform-tools:${FLUTTER_DIR}/bin:${USER_HOME}/.cargo/bin:${PATH}"
}

build_apk() {
  log "Cleaning and building debug APK"
  cd "${REPO_DIR}"
  flutter clean
  rm -rf build/flutter_vodozemac android/.gradle .dart_tool
  flutter pub get
  flutter build apk --debug
}

main() {
  require_command sudo
  require_command curl
  require_command git
  require_command unzip

  install_apt_packages
  install_flutter
  install_android_sdk
  install_rust
  prepare_env
  write_local_properties
  build_apk

  log "Done"
  echo "APK path: ${REPO_DIR}/build/app/outputs/flutter-apk/app-debug.apk"
}

main "$@"