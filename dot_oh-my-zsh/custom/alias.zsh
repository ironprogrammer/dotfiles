alias d="cd ~/Downloads/"
alias dl=d
alias p="cd ~/Plugins/"
alias pr="cd ~/Projects/"

alias copy='pbcopy'
alias pasta='pbpaste'
alias hoy='echo -n "$(date '+%Y-%m-%d')"'

# Use bat instead of cat: https://github.com/sharkdp/bat
alias cat=bat
# Use bat for syntax-highlighted help output
alias bathelp='bat --plain --language=help'

# Pipe a command's --help output through bat (syntax-highlighted)
help() {
    "$@" --help 2>&1 | bathelp
}

# Tried generalizing this via -h/--help global aliases, but those break cert's flag parsing @todo
#alias -g -- -h='-h 2>&1 | bathelp'
#alias -g -- --help='--help 2>&1 | bathelp'

# Pipe tail output through bat for syntax-highlighted logs
tail() {
    command tail "$@" | bat --paging=never -l log
}
# Backup for cat if ever needed
alias ccat=cat

# Pipe llm responses through bat for markdown-highlighted output
# Designed to be used like `q(uestion) 'enter your prompt here'`
# See https://fluffyandflakey.blog/2025/06/04/llm-syntax-highlighting/
# See https://llm.datasette.io/en/stable/usage.html
q() {
    llm "$@" | bat -l md -P --plain
}

alias cc='claude --dangerously-skip-permissions'
alias claudeup='brew upgrade --cask claude claude-code'

# Workaround for: zsh: correct 'test' to 'tests' [nyae]?
# Just has zsh skip autocorrection for npm command
alias npm='nocorrect npm'

# https://github.com/paulhammond/webkit2png/issues/90#issuecomment-180022208
alias webkit2png='webkit2png --ignore-ssl-check '
alias screencap=webkit2png
alias screenshot=webkit2png
alias shot=webkit2png
# https://github.com/JamieMason/ImageOptim-CLI#-usage
alias opt="imageoptim -a"
alias opta="imageoptim -a -I"
alias opto="imageoptim"
alias optj="imageoptim -j -I"

alias s=subl

alias fingerprint="ssh-keygen -lf "
alias fingerprintmd5="ssh-keygen -E md5 -lf "

alias localip="ipconfig getifaddr en0"

# Trim new lines and copy to clipboard
alias c="tr -d '\n' | pbcopy"

# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Reassign ownership when `brew cleanup` fails with: Error: Could not cleanup old kegs! Fix your permissions on...
alias brewclean="sudo chown -R $(whoami) $(brew --prefix)/Cellar/* && brew cleanup"

# Periodically delete and restart autoupdate to ensure latest features available: https://github.com/DomT4/homebrew-autoupdate
alias brewautoup="brew autoupdate delete && brew autoupdate start 43200 --upgrade --cleanup --immediate --sudo"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall inder"

alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# Reload Oh My Zsh
alias reload='omz reload && echo omz reloaded.'
alias rl=reload

# Fun thing from @andrei: https://a8c.slack.com/archives/G03LTST0U/p1643803058180189
alias yolo=echo git commit -m "$(curl -s http://whatthecommit.com/index.txt)"

# Ding! All done! e.g. brew upgrade ; ding
alias ding='afplay /System/Library/Sounds/Submarine.aiff -v 10'

# Use custom port of OpenAI Whisper: https://gist.githubusercontent.com/whileseated/3060010f6e2a948aa5b4231eef048da7/raw/5890365fe3f54385645a4deb64685d1353bde8e7/Easy%2520Whisper%2520AI%2520Audio%2520Transcription%2520for%2520MacOS
alias whisper='~/Code/whisper.cpp/main -m ~/Code/whisper.cpp/models/ggml-small.en.bin'

# List site links in use by Valet
alias vlinks="valet links | awk '$2 != "Site" && $2 != "" {print $2}'"

# Pretty debug for command line scripts
alias php='php -d display_errors=stderr -d xdebug.cli_color=1'
#alias wp="export WP_CLI_PHP_ARGS="-d display_errors=stderr -d xdebug.cli_color=1"; $HOME/public_html/bin/wp"

alias wget=wget2

# Check USB devices: https://sixcolors.com/post/2025/01/quick-tip-which-usb-devices-are-currently-attached/
alias usb="ioreg -p IOUSB -w0 | sed 's/[^o]*o //; s/@.*$//' | grep -v '^Root.*'"

# Cursor Agent
alias ca='cursor-agent'

# chezmoi
alias cz='chezmoi'

# Friendly alias for the cert script (bin/cert)
alias check-cert=cert

alias py=python
alias python=python3
alias pip=pip3
