#!/usr/bin/env bash
# .gitmobile Launcher for Linux / macOS / Termux

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

echo "Starting .gitmobile server..."

if command -v node >/dev/null 2>&1; then
  node "$DIR/server/index.js"
elif command -v deno >/dev/null 2>&1; then
  deno run -A "$DIR/server/index.js"
else
  echo "Error: Neither Node.js nor Deno found in PATH."
  exit 1
fi
