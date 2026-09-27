#!/usr/bin/env bash
# SessionStart: make sure Dart and Very Good CLI are available, then fetch
# dependencies.
#
# On a developer machine Dart is already installed and this only runs
# `dart pub get`. In a Claude Code cloud session the container has no Dart,
# so the stable SDK is downloaded into /opt/dart-sdk and linked into
# /usr/local/bin, where later shells, hooks and MCP servers find it.
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"

log() { echo "[session-start] $*" >&2; }

if ! command -v dart >/dev/null 2>&1; then
  if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
    log "dart not found on PATH; install the Dart SDK (https://dart.dev/get-dart)."
    exit 0
  fi
  log "installing the Dart SDK (stable)"
  tmp="$(mktemp -d)"
  curl -sSfL -o "$tmp/dart.zip" \
    https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip
  unzip -q "$tmp/dart.zip" -d "$tmp"
  rm -rf /opt/dart-sdk
  mv "$tmp/dart-sdk" /opt/dart-sdk
  rm -rf "$tmp"
  ln -sf /opt/dart-sdk/bin/dart /usr/local/bin/dart
fi

if ! command -v very_good >/dev/null 2>&1; then
  log "activating very_good_cli"
  dart pub global activate very_good_cli >/dev/null
  if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
    ln -sf "$HOME/.pub-cache/bin/very_good" /usr/local/bin/very_good
  elif [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "export PATH=\"\$PATH:$HOME/.pub-cache/bin\"" >>"$CLAUDE_ENV_FILE"
  fi
fi

dart pub get >/dev/null
log "dart $(dart --version 2>&1 | sed -E 's/.*version: ([^ ]+).*/\1/'), dependencies fetched"
