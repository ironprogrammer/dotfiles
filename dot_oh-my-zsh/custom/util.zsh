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

# Convert source file audio to MP3
tomp3() {
  ffmpeg -i "$1" -vn -ab 128k -ar 44100 -y "${1%.*}.mp3"
}

# Convert source file video to 720p MP4 with fast compression
tomp4() {
  ffmpeg -i "$1" -vf "scale=-2:720" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -y "${1%.*}.mp4"
}

# Creates symlink pointing local .claude/settings.local.json to ~/.claude/settings.local.json (shared)
# If local symlink already exists, removes it (clean up)
# If local file already exists (not a symlink), ask for confirmation before replacing with symlink (overwrites)
claudeme () {
	local src="$HOME/.claude/settings.local.json" # file to symlink to (immutable)
	local dest="$PWD/.claude/settings.local.json" # local file or symlink

	# Check for symlink
	if [ -L "$dest" ]; then
		cat "$dest"
		read "confirm?$dest symlink already exists. Delete? (y/N) "
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
			echo "Aborting."
			return 1
		fi

		# User wishes to remove the symlink
		echo "Removing existing symlink at $dest"
		rm "$dest"
		return 0
	fi

	# Check for local file
	if [ -e "$dest" ]; then
		cat "$dest"
		read "confirm?$dest already exists. Overwrite with symlink? (y/N) "
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
			echo "Aborting."
			return 1
		fi

		# User wishes to replace existing file with symlink
		echo "Removing existing file at $dest"
		rm "$dest"
	fi

	# Ensure destination directory exists
	mkdir -p "$(dirname "$dest")"

	ln -s "$src" "$dest" \
		&& echo "Created symlink from $src to $dest"

	echo "You might want to add the .claude directory to .gitignore."
}

# Creates symlink pointing local AGENTS.md to ~/.config/agents/AGENTS.md (shared)
# If .claude directory exists, also creates CLAUDE.md symlink for Claude Code compatibility
# If local symlink already exists, removes it (clean up)
# If local file already exists (not a symlink), ask for confirmation before replacing with symlink (overwrites)
agentsme () {
	local src="$HOME/.config/agents/AGENTS.md" # file to symlink to (immutable)
	local dest="$PWD/AGENTS.md" # local file or symlink

	# Ensure source file exists
	if [ ! -f "$src" ]; then
		echo "Error: Source file $src does not exist"
		echo "Create it first or initialize with: mkdir -p ~/.config/agents && touch $src"
		return 1
	fi

	# Check for symlink
	if [ -L "$dest" ]; then
		cat "$dest"
		read "confirm?$dest symlink already exists. Delete? (y/N) "
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
			echo "Aborting."
			return 1
		fi

		# User wishes to remove the symlink
		echo "Removing existing symlink at $dest"
		rm "$dest"
		return 0
	fi

	# Check for local file
	if [ -e "$dest" ]; then
		cat "$dest"
		read "confirm?$dest already exists. Overwrite with symlink? (y/N) "
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
			echo "Aborting."
			return 1
		fi

		# User wishes to replace existing file with symlink
		echo "Removing existing file at $dest"
		rm "$dest"
	fi

	# Create AGENTS.md symlink
	ln -s "$src" "$dest" \
		&& echo "Created symlink from $src to $dest"

	# If .claude directory exists, also create CLAUDE.md symlink for Claude Code
	if [ -d "$PWD/.claude" ]; then
		local claude_dest="$PWD/CLAUDE.md"
		
		# Check if CLAUDE.md already exists
		if [ -L "$claude_dest" ]; then
			echo "CLAUDE.md symlink already exists, skipping"
		elif [ -e "$claude_dest" ]; then
			cat "$claude_dest"
			read "confirm?CLAUDE.md already exists. Overwrite with symlink? (y/N) "
			if [[ "$confirm" =~ ^[Yy]$ ]]; then
				rm "$claude_dest"
				ln -s "$src" "$claude_dest" \
					&& echo "Created symlink from $src to $claude_dest"
			fi
		else
			ln -s "$src" "$claude_dest" \
				&& echo "Created symlink from $src to $claude_dest"
		fi
	fi

	echo "You might want to add AGENTS.md and CLAUDE.md to .gitignore."
}

# Converts decimal seconds to MM:SS.ss format
alias convt=convert_to_time
convert_to_time() {
	local total=$1
	local minutes=$((int(total / 60)))
	local seconds=$(printf "%.2f" $((total % 60)))
	printf "%02d:%05.2f\n" $minutes $seconds
}

# Converts MM:SS.ss format to decimal seconds
alias convs=convert_to_seconds
convert_to_seconds() {
	local time=$1
	local minutes=${time%%:*}
	local seconds=${time##*:}
	printf "%.2f\n" $((minutes * 60.0 + seconds))
}

# Get external IP (including IPv6)
ip () { curl --silent -4 http://icanhazip.com; curl --silent -6 http://icanhazip.com; }

# Flush Directory Service cache
#alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
# Script via https://a8c.slack.com/archives/C02A76B714Z/p1736392280906459?thread_ts=1736391437.472249&cid=C02A76B714Z
flush() {
	echo "🧹 Flushing macOS DNS cache..."
	sudo dscacheutil -flushcache
	sudo killall -HUP mDNSResponder
	echo "✅ MacOS DNS cache cleared!"

	echo "\n🌐 Opening Chrome DNS settings..."
	# Try to open Chrome to the DNS page
	# The open command will use the default browser if Chrome isn't found
	open -a "Google Chrome" "chrome://net-internals/#dns" 2>/dev/null || \
	(echo "⚠️  Couldn't open Chrome directly. Opening in default browser..." && \
	 open "chrome://net-internals/#dns")

	echo "👉 Please click the 'Clear host cache' button in the Chrome tab"
}

# Shortcut for AnyBar https://github.com/tonsky/AnyBar
# Also see:
# 	~/bin/anybar-calypso
# 	https://github.com/Automattic/wp-calypso/blob/a3a09a982389b47cbeffa2357e0f7c5954ebe725/docs/development-workflow.md
anybar() {
	local port=1738
	if ! lsof -iUDP:$port > /dev/null 2>&1; then
		open -a AnyBar \
		&& echo AnyBar launched.
	fi

	case "$1" in
		"")
			set -- "hollow"
		;;
	esac

	# send command to AnyBar
	echo -n "$1" | nc -4u -w0 localhost $port
	#bash -c "echo -n '$1' > /dev/udp/localhost/$port" # alt, though both output a blank line
}

# Delete current local git branch, and optionally remote branch
gbrd() {	
	local branch=$(git rev-parse --abbrev-ref HEAD)
	local head_branch=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
	if [ ${branch} = ${head_branch} ]; then
		echo You can\'t delete branch \'${branch}\'. && return 1
	fi
	[[ "$(echo -n "Delete local branch '${branch}'? [y/N] " >&2; read -q; echo $REPLY)" == [Yy]* ]] \
		&& echo && git checkout ${head_branch} && git branch -D ${branch}
	# bail out if anything fails
	if [ "$?" -ne 0 ]; then return 1; fi
	# @todo: check if remote exists before asking to delete
	[[ "$(echo -n 'Delete remote branch? [y/N] ' >&2; read -q; echo $REPLY)" == [Yy]* ]] \
		&& echo && git push -d origin ${branch}
}

# Clears out Composer's vendor/ folder, preserving .gitignore if present
cleanvendor() {
	if [ -d "vendor" ]; then
		cd vendor \
			&& find . -mindepth 1 -not -name '.gitignore' -depth -exec rm -rf {} + \
			&& cd .. \
			&& echo Vendor files cleared.
	else
		echo There\'s no vendor folder here.
	fi
}

phpcs() {
	if [ -f "vendor/bin/phpcs" ]; then
		# call phpcs and pass in all args
		vendor/bin/phpcs $@
	else
		~/.composer/vendor/bin/phpcs $@
	fi
}

# PHPStorm alias: https://www.jetbrains.com/help/phpstorm/opening-files-from-command-line.html#7521fd2d
alias phpstorm='open -na "PhpStorm.app" --args "$@"'

# Show `man` output in Preview: https://ericasadun.com/2021/08/19/piping-stdout-and-stderr-to-preview/
mman() {
	man -t $1 | open -fa Preview
}


# Side-by-side shortcut in Sublime Merge
smdiff() {
	smerge mergetool "$@"
}


# Set Xdebug variables for CLI debugging, e.g. for phpunit: https://getgrav.org/blog/macos-monterey-apache-mysql-vhost-apc
xdebug-cli() {
	export XDEBUG_MODE=debug
	export PHP_IDE_CONFIG=serverName=localhost
	export XDEBUG_CONFIG=idekey=PHPSTORM remote_port=9000 remote_host=localhost remote_enable=1 remote_handler=dbgp
}

# From https://github.com/iandunn/dotfiles/blob/02762ec864127ba8b4fc0b25fa030aabfcd8db4d/.bashrc#L60-L70
# find all files in the current folder and below, then grep each of them for the given string
# this could _almost_ be an alias, but then $QUERY would have to be at the end of the command, so you couldn't remove the binary files
function findgrep {
	local QUERY=$1
	local MATCHES=$(find . -type f ! -name "*.svn*" ! -name "*.git*" -follow |xargs grep --ignore-case --line-number --no-messages $QUERY)
	# ! -path '*/.svn/*' ! -path '*/.git/*' might be better ?
	local OUTPUT=$(printf '%s\n' "${MATCHES[@]}" | grep -v "Binary file")
	# also add build, vendor, etc folders to exclude?

	printf '%s\n' "${OUTPUT[@]}"
}

# Toggle network adapter by name
network-toggle() {
	if [ -z "$1" ]; then
		echo You must specify the network service to toggle.
		echo -
		echo Current services:
		networksetup -listallnetworkservices
		return 1
	fi

	local adapter=$1
	local lan=( $(networksetup -getnetworkserviceenabled ${adapter}) )

	if [ ${lan} = 'Enabled' ]
	then
		networksetup -setnetworkserviceenabled "${adapter}" off \
		&& echo ${adapter} disabled.
	else
		networksetup -setnetworkserviceenabled "${adapter}" on \
		&& echo ${adapter} enabled.
	fi
}
alias belkin='network-toggle "Belkin USB-C LAN"'
alias lan=belkin
alias wifi='network-toggle "Wi-Fi"'

# Start a PHP server from a directory, optionally specifying the port
function phpserver() {
	local port="${1:-4000}";
	local ip=$(ipconfig getifaddr en0);
	sleep 1 && open "http://${ip}:${port}/" &
	php -S "${ip}:${port}";
}

# Create a new directory and enter it
alias md='mkd'
function mkd() {
	mkdir -p "$@" && cd "$_";
}

# One of @janmoesen’s ProTip™s
export PERL_LWP_SSL_VERIFY_HOSTNAME=0
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	alias "${method}"="lwp-request -m '${method}'"
done

# Check redirects
function redir() {
	echo Inspecting redirect chain for $1...
	curl -sIL "$@" | egrep -i "^([[:space:]]*$|HTTP|server|location|x-powered-by)";
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')";
}

# take this repo and copy it to somewhere else minus the .git stuff
function gitexport() {
	mkdir -p "$1"
	git archive master | tar -x -C "$1"
}

# `o` with no arguments opens the current directory, otherwise opens the given location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

alias check-cert=cert
# Function to get SSL certificate domains
cert() {
	local show_all=false
	local domain=""
	local port="443"

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case $1 in
			-a|--all)
				show_all=true
				shift
				;;
			-p|--port)
				port="$2"
				shift 2
				;;
			-h|--help)
				echo "Usage: cert [-a|--all] [-p|--port PORT] <domain>"
				echo "  -a, --all    Show all Subject Alternative Names + Common Name"
				echo "  -p, --port   Specify port (default: 443)"
				echo "  -h, --help   Show this help"
				echo ""
				echo "Examples:"
				echo "  cert google.com              # Show common name only"
				echo "  cert -a google.com           # Show all domains"
				echo "  cert -p 8443 example.com     # Custom port"
				return 0
				;;
			-*)
				echo "Unknown option: $1"
				echo "Use 'cert --help' for usage information."
				return 1
				;;
			*)
				if [[ -z "$domain" ]]; then
					domain="$1"
				else
					echo "Error: Multiple domains specified"
					return 1
				fi
				shift
				;;
		esac
	done

	if [[ -z "$domain" ]]; then
		echo "Error: No domain specified"
		echo "Use 'cert --help' for usage information."
		return 1
	fi

	echo "Cert info for $domain:$port"

	if [[ "$show_all" == true ]]; then
		# Get certificate and extract all domains
		local cert_info=$(openssl s_client -connect "$domain:$port" -servername "$domain" -verify_return_error </dev/null 2>/dev/null)

		if [[ $? -ne 0 ]]; then
			echo "Error: Could not connect to $domain:$port"
			return 1
		fi

		# Extract Subject Alternative Names
		local sans=$(echo "$cert_info" | openssl x509 -noout -text 2>/dev/null | grep -A1 "Subject Alternative Name" | tail -1 | sed 's/DNS://g; s/,/\n/g; s/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$')

		# Extract Common Name
###        local cn=$(echo "$cert_info" | openssl x509 -noout -subject 2>/dev/null | sed 's/.*CN = //' | sed 's/,.*//')

		# Output all domains, removing duplicates
		{
			echo "$sans"
###            echo "$cn"
		} | grep -v '^$' | sort -u

	else
		# Just show Common Name
		local cert_info=$(openssl s_client -connect "$domain:$port" -servername "$domain" -verify_return_error </dev/null 2>/dev/null)

		if [[ $? -ne 0 ]]; then
			echo "Error: Could not connect to $domain:$port"
			return 1
		fi

		echo "$cert_info" | openssl x509 -noout -subject 2>/dev/null | sed -E 's/^.*CN\s*=\s*([^,]+).*$/\1/'
	fi
}

# NATO phonetic alphabet converter
function nato() {
	typeset -A DICTIONARY
	DICTIONARY=(
		a Alfa
		b Bravo
		c Charlie
		d Delta
		e Echo
		f Foxtrot
		g Golf
		h Hotel
		i India
		j Juliett
		k Kilo
		l Lima
		m Mike
		n November
		o Oscar
		p Papa
		q Quebec
		r Romeo
		s Sierra
		t Tango
		u Uniform
		v Victor
		w Whiskey
		x X-ray
		y Yankee
		z Zulu
		1 One
		2 Two
		3 Three
		4 Four
		5 Five
		6 Six
		7 Seven
		8 Eight
		9 Nine
		0 Zero
	)

	for word in "$@"; do
		letters=()
		# Convert word to lowercase and split into characters
		for char in ${(s::)${(L)word}}; do
			# Look up in dictionary, use char itself as fallback
			letters+=("${DICTIONARY[$char]:-$char}")
		done
		echo "${letters[*]}"
	done
}

# Get all IP addresses (IPv4 and IPv6)
ips() {
  ifconfig -a | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}|([a-fA-F0-9:]+:+)+[a-fA-F0-9]+'
}
