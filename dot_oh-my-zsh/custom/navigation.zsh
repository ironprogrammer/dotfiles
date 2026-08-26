# Helper to jump to specific project in ~/Sites
site () { cd ~/Sites/"$@"; }
alias sites=site # Shortcut to Sites root
# Enable completion for the site function
_site() {
	local -a sites
	sites=(~/Sites/*(/:t))
	_describe 'site' sites
}
compdef _site site

alias md='mkd'

# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$_";
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# `o` with no arguments opens the current directory, otherwise opens the given location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

# Quick Look one or more files, detached so the shell stays usable
function ql() {
	if [ $# -eq 0 ]; then
		echo "usage: ql <file> [file ...]" >&2
		return 1
	fi
	qlmanage -p "$@" >/dev/null 2>&1 &!
}
