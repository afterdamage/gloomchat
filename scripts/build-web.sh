#!/usr/bin/env bash
set -euo pipefail

echo "==> Building web"
flutter build web --no-tree-shake-icons "$@"

echo "==> Copying config"
cp config.sample.json build/web/config.json

echo "==> Done. Serve with: python3 -m http.server 8080 --directory build/web"
