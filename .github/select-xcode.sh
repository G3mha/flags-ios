#!/usr/bin/env bash
#
# Selects an exact Xcode version, or fails saying what is actually installed.
#
# Matches on the version xcodebuild reports rather than on the .app's name,
# because runner images do not name them consistently — Xcode_26.6.app,
# Xcode_26.6.0.app and a plain Xcode.app symlink have all been a thing — and
# a pin that guesses at filenames is not much of a pin.
#
# Usage: .github/select-xcode.sh 26.6

set -euo pipefail

want="${1:?usage: select-xcode.sh <version>}"

version_of() {
  "$1/Contents/Developer/usr/bin/xcodebuild" -version 2>/dev/null | head -1 | awk '{print $2}'
}

for app in /Applications/Xcode*.app; do
  [ -d "$app" ] || continue
  if [ "$(version_of "$app")" = "$want" ]; then
    sudo xcode-select -switch "$app"
    echo "Selected $app"
    xcodebuild -version
    exit 0
  fi
done

echo "Xcode $want is not on this runner. Installed:" >&2
for app in /Applications/Xcode*.app; do
  [ -d "$app" ] || continue
  echo "  $(version_of "$app")	$app" >&2
done
echo >&2
echo "Either install it, or raise XCODE_VERSION in .github/workflows/ci.yml" >&2
echo "once the project is known to build with a newer one." >&2
exit 1
