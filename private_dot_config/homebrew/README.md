# Homebrew

- `Brewfile.base`: every machine. Terminal, editors, AI tools, desktop apps, and utilities.
- `Brewfile.dev`: added on WordPress/PHP dev machines.

PHP, nginx, and dnsmasq are managed by Valet and PHP Monitor. Don't add them to either Brewfile.

## New machine

1. Install [Homebrew](https://brew.sh).
2. Install chezmoi and apply dotfiles (includes Homebrew tap trust):
   ```sh
   brew install chezmoi
   chezmoi init --apply ironprogrammer
   ```
3. Install packages:
   ```sh
   brew bundle --file=~/.config/homebrew/Brewfile.base
   brew bundle --file=~/.config/homebrew/Brewfile.dev   # dev machines only
   ```
4. Dev machines only: install Valet with `composer global require laravel/valet && valet install`, then add PHP versions in PHP Monitor.

## Existing machine

1. Pull dotfile changes: `chezmoi update`
2. Install anything missing: rerun the `brew bundle` commands from step 3 above.
3. Check for drift:
   ```sh
   cat ~/.config/homebrew/Brewfile.* | brew bundle cleanup --file=-
   ```
   Anything listed is installed but not declared. Add it to a Brewfile, or remove it by rerunning with `--force`.
4. Apps installed outside Homebrew: `brew install --cask --adopt <cask>`. If versions differ, update the app first or use `--force`.

## Changing packages

- Edit with `chezmoi edit ~/.config/homebrew/Brewfile.base` (commits and pushes automatically), then rerun `brew bundle` with that file.
- After trusting a new tap: `chezmoi re-add ~/.homebrew/trust.json`
