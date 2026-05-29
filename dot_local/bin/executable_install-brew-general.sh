#!/usr/bin/env bash
#
# install-brew-general.sh
# -----------------------------------------------------------------------------
# Everyday / non-dev machine setup: desktop apps, media & creative tools,
# communication, and general utilities.
# Pairs with install-brew-developer.sh (lean coding toolchain).
#
# On your primary daily-driver you'll likely run BOTH scripts; on a dedicated
# dev box, run only install-brew-developer.sh.
#
# Usage:  ./install-brew-general.sh
# Idempotent — Homebrew skips anything already installed.
# -----------------------------------------------------------------------------
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew not found. Install it first: https://brew.sh" >&2
  exit 1
fi

echo "==> Updating Homebrew"
brew update

# ----------------------------------------------------------------------------
# Formulae (general-purpose CLI / utilities)
# ----------------------------------------------------------------------------
formulae=(
  yt-dlp          # video/audio downloader
  ffmpeg          # media transcoding
  imagemagick     # image manipulation (convert/magick)
  syncthing       # continuous file sync (daemon)
  nut             # Network UPS Tools (battery/UPS monitoring)
  defaultbrowser  # set the default browser from the CLI
  magic-wormhole  # secure file transfer between machines
)

echo "==> Installing general formulae"
brew install "${formulae[@]}"

# ----------------------------------------------------------------------------
# Casks (desktop applications)
# ----------------------------------------------------------------------------
casks=(
  # --- Productivity / core ---
  1password
  alfred
  obsidian

  # --- Browsers ---
  firefox
  google-chrome
  finicky                 # rule-based browser router

  # --- Communication / AI assistants ---
  slack
  zoom
  chatgpt
  claude                  # Claude desktop app

  # --- Audio / music / video / creative ---
  bitwig-studio
  audio-hijack
  farrago
  fission
  loopback
  musescore
  macwhisper
  obs
  handbrake
  handbrake-app

  # --- Screen capture / sharing ---
  shottr
  licecap
  keycastr
  loom
  droplr

  # --- Files / sync / reading ---
  transmit                # FTP/SFTP/cloud file transfer
  syncthing-app           # menu-bar UI for syncthing
  netnewswire             # RSS reader

  # --- System utilities ---
  flux                    # screen color temperature
  flux-app
  imageoptim              # lossless image compression
  qlmarkdown              # Quick Look for markdown
  keybase                 # encrypted messaging / file sharing
)

echo "==> Installing general casks"
brew install --cask "${casks[@]}"

echo "==> General setup complete."
