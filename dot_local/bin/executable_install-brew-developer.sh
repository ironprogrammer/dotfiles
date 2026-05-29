#!/usr/bin/env bash
#
# install-brew-developer.sh
# -----------------------------------------------------------------------------
# Lean developer toolchain. Run this on any machine you write/run/test code on.
# Pairs with install-brew-general.sh (desktop apps, media, productivity).
#
# NOTE: PHP itself (php@8.x, imagick, etc.) is intentionally NOT here — that
#       stack is managed via PHP Monitor, not Homebrew, across machines.
#
# Usage:  ./install-brew-developer.sh
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
# Formulae (CLI tools + local dev infrastructure)
# ----------------------------------------------------------------------------
formulae=(
  # --- Core terminal / shell ---
  bat                     # cat with syntax highlighting
  tree                    # directory tree view
  ripgrep                 # fast recursive grep (rg)
  git                     # Homebrew git (newer than system/Xcode git)
  git-delta               # nicer git diffs
  gh                      # GitHub CLI
  gnupg                   # GPG signing/encryption
  pinentry-mac            # GPG pinentry on macOS
  thefuck                 # corrects the previous mistyped command
  glow                    # markdown renderer in the terminal
  chezmoi                 # dotfile management (this repo)
  zsh-autosuggestions     # shell QoL
  zsh-syntax-highlighting # shell QoL

  # --- Editors & runtimes ---
  helix                   # modal terminal editor
  node                    # Node.js runtime
  deno                    # Deno runtime

  # --- AI / agent tooling ---
  llm                     # Simon Willison's LLM CLI
  gemini-cli              # Google Gemini CLI
  agent-browser           # browser automation for agents
  skills                  # Claude skills tooling

  # --- Web / local dev servers & DB ---
  nginx                   # local web server
  httpd                   # Apache (alternative local web server)
  mariadb                 # local MySQL-compatible DB
  dnsmasq                 # local DNS for *.test domains etc.
  mkcert                  # locally-trusted dev TLS certs
  mailpit                 # local SMTP capture / email testing UI
  wp-cli                  # WordPress CLI

  # --- Build / source / profiling ---
  subversion              # svn
  pkgconf                 # build-time pkg-config
  pipx                    # install Python CLI apps in isolation
  graphviz                # dot / graph rendering
  qcachegrind             # callgrind/profiler GUI viewer
  chroma                  # syntax highlighter
  pygments                # syntax highlighter (pygmentize)
  grip                    # local GitHub-flavored README preview
  vhs                     # scripted terminal GIF/recording
)

echo "==> Installing developer formulae"
brew install "${formulae[@]}"

# ----------------------------------------------------------------------------
# Casks (developer GUI apps)
# ----------------------------------------------------------------------------
casks=(
  # --- Editors / IDEs ---
  cursor
  visual-studio-code
  sublime-text
  t3-code

  # --- Git / diff ---
  sublime-merge
  meld
  git-credential-manager
  github

  # --- Terminal ---
  ghostty
  cmux

  # --- AI coding assistants ---
  claude-code
  codex
  codex-app

  # --- API / DB clients ---
  postman
  beekeeper-studio

  # --- Networking / hosts (dev-adjacent) ---
  tailscale-app
  switchhosts            # quick /etc/hosts switching for local sites

  # --- Coding fonts ---
  font-fira-code-nerd-font
  font-fira-mono-nerd-font
  font-jetbrains-mono-nerd-font
  font-heavy-data-nerd-font
)

echo "==> Installing developer casks"
brew install --cask "${casks[@]}"

echo "==> Developer setup complete."
