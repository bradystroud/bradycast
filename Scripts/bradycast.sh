#!/bin/sh
# Bradycast: a personal build of Tinycast, signed with Brady's Developer ID.
#
# The fork carries no source changes. Name and bundle id go on the xcodebuild line, the same way
# upstream's release.yml sets them per channel, so `git merge <upstream tag>` stays clean.
#
# A bundle id other than com.tinycast.app puts the app on ReleaseChannel.development, which never
# checks GitHub for updates. Updates happen here, on purpose: `bradycast.sh update <tag>`.
#
#   Scripts/bradycast.sh build            build Release into build/
#   Scripts/bradycast.sh install          build, then replace /Applications/Bradycast.app and relaunch
#   Scripts/bradycast.sh update [tag]     fetch upstream, list newer stable tags, merge one if given
set -eu

NAME="Bradycast"
BUNDLE_ID="com.bradycast.app"
IDENTITY="Developer ID Application: BRADY MATTHEW STROUD (AQ6HPWB3D9)"
TEAM="AQ6HPWB3D9"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="$ROOT/build/DerivedData"
APP="$DERIVED/Build/Products/Release/$NAME.app"
DEST="/Applications/$NAME.app"

version() { git -C "$ROOT" describe --tags --abbrev=0 --match 'v[0-9]*' | sed 's/^v//'; }
build_number() { git -C "$ROOT" rev-list --count HEAD; }

build() {
  cd "$ROOT"
  echo "==> Building $NAME $(version) ($(build_number))"
  xcodebuild -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$DERIVED" \
    ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$IDENTITY" DEVELOPMENT_TEAM="$TEAM" \
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    PRODUCT_NAME="$NAME" PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    MARKETING_VERSION="$(version)" CURRENT_PROJECT_VERSION="$(build_number)" \
    build -quiet
  echo "==> Verifying signature"
  codesign --verify --deep --strict "$APP"
  codesign -dvv "$APP" 2>&1 | grep -q "^Authority=Developer ID Application" \
    || { echo "not signed with Developer ID"; exit 1; }
  echo "==> $APP"
}

install() {
  build
  echo "==> Installing to $DEST"
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  sleep 1
  rm -rf "$DEST"
  ditto "$APP" "$DEST"
  open "$DEST"
  echo "==> Running $NAME $(version)"
}

update() {
  cd "$ROOT"
  git fetch -q --tags upstream
  current="v$(version)"
  echo "==> On $current. Newer stable tags:"
  git tag --list 'v[0-9]*' | grep -v -- '-' | sort -V | awk -v c="$current" '$0 > c' || true
  if [ "${1:-}" ]; then
    echo "==> Diff summary $current..$1"
    git diff --stat "$current" "$1" | tail -1
    git merge --no-edit "$1"
    echo "==> Merged $1. Review, then: Scripts/bradycast.sh install"
  fi
}

case "${1:-build}" in
  build) build ;;
  install) install ;;
  update) update "${2:-}" ;;
  *) echo "usage: $0 build|install|update [tag]"; exit 2 ;;
esac
