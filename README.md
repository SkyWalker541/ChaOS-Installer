# ChaOS Installer

Puts [ChaOS](https://github.com/SkyWalker541/ChaOS) on a microSD card for the
TrimUI Brick, or updates a card that already has it without touching the
games, music and saves on it.

ChaOS Installer is a fork of Eric Reinsmidt's
[TortOS Installer](https://github.com/ericreinsmidt/TortOS-Installer), made
for the Brick only and pointed at ChaOS's releases.

## Download

Get it from the [latest release](https://github.com/SkyWalker541/ChaOS-Installer/releases/latest):

| | |
|---|---|
| **macOS** (Apple Silicon and Intel) | `ChaOS-Installer-<version>-macOS.zip` |
| **Windows** 10 and 11 | `ChaOS-Installer-<version>-Windows.exe` |
| **Linux** (Debian, Ubuntu, Mint) | `ChaOS-Installer-<version>-amd64.deb` |
| **Linux** (Fedora) | `ChaOS-Installer-<version>-x86_64.rpm` |

The first time it opens:

- **macOS:** unzip it and open the app. It isn't signed by Apple, so macOS
  stops it the first time: open *System Settings > Privacy & Security*,
  scroll down, and choose *Open Anyway*. Writing a card asks for your
  password.
- **Windows:** the exe needs nothing installed. If Windows says it protected
  your PC, choose *More info* and *Run anyway*. It asks to run as
  administrator, which writing a card needs.
- **Linux:** install the package, `sudo apt install ./ChaOS-Installer-*.deb`
  or `sudo dnf install ./ChaOS-Installer-*.rpm`, and open ChaOS Installer
  from your apps. Writing a card asks for your password.

## Using it

Put the card in your computer. The installer finds it and reads what is on
it, then offers what fits:

- **Update** a Brick card that already has ChaOS, or TortOS: the newest ChaOS
  goes on, and the games, music, saves and settings stay.
- **Fresh install** on any card: it is erased, and ChaOS goes on.
- **Move to ChaOS**, in place of Fresh install on a Brick card with TortOS
  1.x on TrimUI's firmware: its saves, settings and BIOS files are kept on the
  computer, and when the card comes back after the Brick's first start, the
  installer offers to put them back. Games, music and audiobooks are erased
  with the card, so copy them off first.

ChaOS is downloaded from its latest release on GitHub
(`ChaOS-v<version>-brick.img.xz`) and checked against the release's
`SHA256SUMS` before anything is written, and everything written is read back.
When it's done, it ejects the card, or says why it couldn't.

To write a test image from a file instead of the latest release, start the
installer with `CHAOS_IMAGE=/path/to/ChaOS-…-brick.img.xz` in its environment.

## Building

GitHub Actions builds all four files (`.github/workflows/build.yml`): on every
push for a check, and on a tag `v<version>` (Cargo.toml's version) it makes the
GitHub release with the four files and their `SHA256SUMS`.

On a Mac it can also be built by hand as TortOS Installer is:

1. Install Rust with rustup, add the Intel target for the macOS app
   (`rustup target add x86_64-apple-darwin`), and install the Tauri CLI
   (`cargo install tauri-cli --version "^2"`).
2. Run `tools/release.sh`. It runs the tests, then builds all four files into
   `dist/<version>/` with their `SHA256SUMS` (the Windows and Linux ones in
   Docker).

The fonts in `ui/fonts` are Josefin Sans, under the SIL Open Font License
(`ui/fonts/OFL.txt`).

## License

ChaOS Installer is free software under the GNU General Public License,
version 3 or any later version; see `LICENSE`. It is TortOS Installer's code,
Copyright (c) 2026 Eric Reinsmidt, with ChaOS's changes, Copyright (c) 2026
SkyWalker541. What it's built from that isn't its own (Tauri, every Rust crate
in the apps, with their licenses, and the fonts) is in `THIRD-PARTY.md`.
