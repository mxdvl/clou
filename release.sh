#!/usr/bin/env sh
# Build the Connect IQ Store submission package: bin/clou-<tag>.iq.
#
# Unlike run.sh (which builds a .prg for one device, for the simulator or
# sideloading), this packages a release build for every product listed in
# manifest.xml into a single signed .iq, ready to upload in the Connect IQ
# Developer Portal. The output filename is tagged with the most recent git
# tag reachable from HEAD, so the package a version corresponds to is
# unambiguous.
#
# Usage:
#   ./release.sh
#
# Requires on PATH: monkeyc (Connect IQ SDK bin/) + JDK.
set -eu

cd "$(dirname "$0")"

VERSION="$(git describe --tags --abbrev=0)"
OUT="bin/clou-$VERSION.iq"
mkdir -p bin

echo "building release package -> $OUT ..."
monkeyc -e -r -o "$OUT" -f monkey.jungle -y developer_key.der -w -l 3

echo "done: $OUT"
