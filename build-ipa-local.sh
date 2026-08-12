#!/usr/bin/env bash
# Local IPA build — mirror of .github/workflows/main.yml. Produces an IPA
# you can sign with Sideloadly/AltStore/TrollStore.
#
# Pipeline:
#   1. Build EeveeSwiftProtobuf.framework from apple/swift-protobuf source
#      (renamed module — see Tools/SwiftProtobufBuild/).
#   2. theos `make package FINALPACKAGE=1` — produces .deb with
#      EeveeSpotify.dylib + EeveeSpotify.bundle + framework.
#   3. Build zxPluginsInject.dylib — sideload compat shim (keychain redirect,
#      group containers, CloudKit stub).
#   4. cyan inject deb-contents (dylib + framework + bundle) into vanilla IPA.
#      This is the STABLE output — confirmed installable via SideStore.
#   5. Strip Watch.app if it survived cyan -du.
#   6. Produce a SECOND, EXPERIMENTAL ipa: a copy of the stable one with
#      zxPluginsInject LC-injected via ipapatch into the main exec + every
#      appex. ipapatch's LC-injection produces a Mach-O that ldid can read
#      but apparently can't re-sign afterward (assert "end >= size - 0x10"),
#      which is exactly what SideStore/AltStore need to do at install time —
#      so this variant may fail to install there. See README.md
#      ("Known issue: IPA fails to install / ldid assert") for the full
#      writeup and how this was diagnosed.
#
# Requires: theos, cyan (pyzule-rw), ipapatch, dpkg, ldid, plutil.

set -euo pipefail

VANILLA_IPA="${1:-}"
[ -n "$VANILLA_IPA" ] && [ -f "$VANILLA_IPA" ] || {
    echo "usage: $0 <path/to/Spotify-vanilla.ipa>" >&2
    exit 1
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

[ -n "${THEOS:-}" ] || { [ -d "$HOME/theos" ] && export THEOS="$HOME/theos" || { echo "THEOS not set"; exit 1; }; }

VERSION=$(grep -E '^Version:' control | awk '{print $2}')
SPOT_VERSION=$(unzip -p "$VANILLA_IPA" 'Payload/Spotify.app/Info.plist' \
    | plutil -extract CFBundleShortVersionString raw - 2>/dev/null || echo "unknown")
OUT_DIR="Outputs/IPAS"
OUT_IPA="$OUT_DIR/EeveeSpotify-${VERSION}-${SPOT_VERSION}.ipa"
OUT_IPA_ZXPI="$OUT_DIR/EeveeSpotify-${VERSION}-${SPOT_VERSION}-zxpi-experimental.ipa"
mkdir -p "$OUT_DIR"

color() { printf '\033[1;32m==> %s\033[0m\n' "$*"; }

color "1/6  EeveeSwiftProtobuf.framework"
chmod +x Tools/SwiftProtobufBuild/build-eeveeswiftprotobuf.sh
Tools/SwiftProtobufBuild/build-eeveeswiftprotobuf.sh

color "2/6  theos make package"
THEOS_PACKAGE_SCHEME=rootless make package FINALPACKAGE=1
DEB_FILE=$(ls -t packages/com.eevee.spotify_*.deb 2>/dev/null | head -1)
[ -n "$DEB_FILE" ] || { echo "deb not produced"; exit 1; }

color "3/6  zxPluginsInject.dylib"
chmod +x Tools/build-zxpi.sh
Tools/build-zxpi.sh >/dev/null

color "4/6  extract deb"
DEB_EXTRACT="$REPO_DIR/Outputs/deb-extract"
rm -rf "$DEB_EXTRACT"; mkdir -p "$DEB_EXTRACT"
dpkg-deb -R "$DEB_FILE" "$DEB_EXTRACT"
DYLIB_SRC=$(find "$DEB_EXTRACT" -name 'EeveeSpotify.dylib' | head -1)
BUNDLE_SRC=$(find "$DEB_EXTRACT" -type d -name 'EeveeSpotify.bundle' | head -1)
FRAMEWORK_SRC=$(find "$DEB_EXTRACT" -type d -name 'EeveeSwiftProtobuf.framework' | head -1)
[ -n "$DYLIB_SRC" ] || { echo "dylib not in deb"; exit 1; }

color "5/6  cyan inject (stable output, no ipapatch)"
INJECT=("$DYLIB_SRC")
[ -n "$FRAMEWORK_SRC" ] && INJECT+=("$FRAMEWORK_SRC")
[ -n "$BUNDLE_SRC" ]    && INJECT+=("$BUNDLE_SRC")
rm -f "$OUT_IPA"
cyan -i "$VANILLA_IPA" -o "$OUT_IPA" -f "${INJECT[@]}" -c 9 -m 15.0 -du

# Belt-and-suspenders: cyan -du strips appex/Watch but verify.
cd "$OUT_DIR"
rm -rf Payload
unzip -q "$(basename "$OUT_IPA")"
if [ -d "Payload/Spotify.app/Watch" ]; then
    rm -rf Payload/Spotify.app/Watch
    zip -qry "$(basename "$OUT_IPA")" Payload
fi
rm -rf Payload
cd - >/dev/null

color "6/6  ipapatch LC-inject zxPluginsInject (EXPERIMENTAL variant, separate file)"
cp "$OUT_IPA" "$OUT_IPA_ZXPI"
ipapatch --input "$OUT_IPA_ZXPI" --inplace --noconfirm --dylib packages/zxPluginsInject.dylib || \
    echo "ipapatch step failed - continuing without the experimental variant" >&2

color "Done"
ls -lh "$OUT_IPA" "$OUT_IPA_ZXPI" 2>/dev/null || true
echo "Recommended: $(basename "$OUT_IPA") - stable, confirmed installable via SideStore."
echo "Experimental: $(basename "$OUT_IPA_ZXPI") - adds zxPluginsInject sideload-compat shim via ipapatch," \
     "but that LC-injection is known to break re-signing (ldid assert) on some install tools. See README.md."
echo "Sign with Sideloadly / AltStore / TrollStore."
