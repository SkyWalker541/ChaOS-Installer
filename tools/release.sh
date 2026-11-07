#!/bin/bash
# Builds ChaOS Installer for macOS, Windows and Linux, all from a Mac, into
# dist/<version>/ with SHA256SUMS. The version is Cargo.toml's.
#
#   tools/release.sh            build and check, nothing leaves this computer
#   tools/release.sh --publish  then tag the commit, push the tag, and make the
#                               GitHub release from those files, with the notes
#                               in dist/notes-<version>.md
#
# Needs Rust through rustup with the x86_64-apple-darwin target, tauri-cli,
# Docker (OrbStack works) for the Windows and Linux builds, and for --publish
# the gh command, signed in.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
REPO=SkyWalker541/ChaOS-Installer
VERSION=$(sed -n 's/^version = "\(.*\)"$/\1/p' src-tauri/Cargo.toml | head -1)
DIST=dist/$VERSION
NOTES=dist/notes-$VERSION.md
NAME=ChaOS-Installer-$VERSION

PUBLISH=0
case "${1:-}" in
	--publish) PUBLISH=1 ;;
	"") ;;
	*) echo "usage: tools/release.sh [--publish]" >&2; exit 2 ;;
esac

say() { printf '\n== %s\n' "$*"; }
stop() { echo "release.sh: $*" >&2; exit 1; }

# A release is made from a commit, not from whatever is lying around
if [ $PUBLISH = 1 ]; then
	[ -z "$(git status --porcelain)" ] || stop "the working tree has changes: commit them first"
	git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null && stop "v$VERSION is already tagged"
	[ -f "$NOTES" ] || stop "write the release notes in $NOTES first"
	gh release view "v$VERSION" --repo $REPO >/dev/null 2>&1 && stop "$REPO already has a v$VERSION release"
fi

say "Third-party notices"
# The crate list is this build's: one that no longer matches would credit
# crates the apps don't carry, or miss ones they do
tools/third-party.py > /tmp/chaos-installer-third-party.md
cmp -s /tmp/chaos-installer-third-party.md THIRD-PARTY.md ||
	stop "THIRD-PARTY.md doesn't match the build's crates: run tools/third-party.py > THIRD-PARTY.md, check it and commit it"

say "Tests"
(cd src-tauri && cargo test --quiet)

mkdir -p "$DIST"

say "macOS: one app for Apple Silicon and Intel"
(cd src-tauri && cargo tauri build --target universal-apple-darwin --bundles app)
APP="src-tauri/target/universal-apple-darwin/release/bundle/macos/ChaOS Installer.app"
# ditto keeps the app's links and permissions, as Finder's own zip does
ditto -c -k --keepParent "$APP" "$DIST/$NAME-macOS.zip"

say "Windows: a portable exe, cross-built with cargo-xwin"
docker run --rm --platform linux/amd64 -v "$ROOT":/src \
	-v chaos-installer-cargo:/usr/local/cargo/registry \
	-v chaos-installer-xwin:/root/.cache/cargo-xwin \
	-v chaos-installer-rustup:/usr/local/rustup \
	-w /src/src-tauri -e CARGO_TARGET_DIR=/src/src-tauri/target/xwin \
	messense/cargo-xwin cargo xwin build --release --target x86_64-pc-windows-msvc
cp src-tauri/target/xwin/x86_64-pc-windows-msvc/release/chaos-installer.exe "$DIST/$NAME-Windows.exe"

say "Linux: a .deb and an .rpm, built on Ubuntu 22.04"
if [ -z "$(docker images -q chaos-installer-linux)" ]; then
	docker build --platform linux/amd64 -t chaos-installer-linux -f tools/linux.Dockerfile tools
fi
# By its ID: OrbStack won't run an amd64 image by name on an Apple Silicon Mac
IMAGE=$(docker images --no-trunc -q chaos-installer-linux | head -1)
docker run --rm -v "$ROOT":/src -v chaos-installer-cargo-linux:/root/.cargo/registry \
	-w /src/src-tauri -e CARGO_TARGET_DIR=target/linux \
	"$IMAGE" cargo tauri build --bundles deb,rpm
BUNDLE=src-tauri/target/linux/release/bundle
# Named chaos-installer by tauri.linux.conf.json: Tauri makes the package's
# name from the product's, and "ChaOS" would come out as cha-os
cp "$BUNDLE/deb/chaos-installer_${VERSION}_amd64.deb" "$DIST/$NAME-amd64.deb"
cp "$BUNDLE/rpm/chaos-installer-$VERSION-1.x86_64.rpm" "$DIST/$NAME-x86_64.rpm"

say "Checksums"
FILES="$NAME-macOS.zip $NAME-Windows.exe $NAME-amd64.deb $NAME-x86_64.rpm"
(cd "$DIST" && shasum -a 256 $FILES > SHA256SUMS && cat SHA256SUMS)
ls -l "$DIST"

if [ $PUBLISH = 0 ]; then
	echo
	echo "Built in $DIST. Nothing was published: tools/release.sh --publish does that."
	exit 0
fi

say "Publishing v$VERSION to $REPO"
git tag -a "v$VERSION" -m "ChaOS Installer $VERSION"
git push origin "v$VERSION"
(cd "$DIST" && gh release create "v$VERSION" $FILES SHA256SUMS --repo $REPO \
	--title "ChaOS Installer $VERSION" --notes-file "$ROOT/$NOTES" --verify-tag)
