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

# Get best audio quality song track from YouTube videos
getsong() {
  yt-dlp -f bestaudio -o "%(title)s.%(ext)s" "$@"
}
getsongpart() {
  yt-dlp -f bestaudio --download-sections "*$2-$3" -o "%(title)s.%(ext)s" "$1"
}
# Make any audio a ringtone
2m4a() {
  ffmpeg -i "$1" -t 30 -c:a aac "${1%.*}.m4a"
}

claudecontinue() {
    local target_input=""
    local mins_mode=false
    local secs=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--minutes)
                mins_mode=true
                shift
                target_input=$1
                shift
                ;;
            *)
                target_input=$1
                shift
                ;;
        esac
    done

    if [[ -z "$target_input" ]]; then
        echo "Usage:"
        echo "  claudecontinue 15:30       (Wait until next 3:30 PM)"
        echo "  claudecontinue 17          (Wait until next 5:00 PM)"
        echo "  claudecontinue -m 120      (Wait 120 minutes)"
        return 1
    fi

    if $mins_mode; then
        # Traditional minutes logic
        secs=$(( target_input * 60 ))
    else
        # Time-of-day logic
        local now=$(date +%s)
        
        # Normalize input: remove colons, then pad to 4 digits (e.g., 5 -> 0500, 1730 -> 1730)
        local clean_time="${target_input//:/}"
        if [[ ${#clean_time} -le 2 ]]; then
            # If user typed '5' or '17', treat as '0500' or '1700'
            clean_time="$(printf "%02d00" $clean_time)"
        else
            # Ensure it's 4 digits for the date parser (e.g., 900 -> 0900)
            clean_time="$(printf "%04d" $clean_time)"
        fi

        # Get the epoch for that time TODAY
        # -j = don't set time, -f = input format
        local target_epoch=$(date -j -f "%H%M" "$clean_time" +%s 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            echo "Error: Invalid time format. Use HH, HHMM, or HH:MM (24-hr)."
            return 1
        fi

        # If target is in the past, add 1 day (86400 seconds)
        if (( target_epoch <= now )); then
            target_epoch=$(( target_epoch + 86400 ))
        fi
        
        secs=$(( target_epoch - now ))
    fi

    # --- Timer UI Logic (Modified from your original) ---
    local start_time=$(date +%s)
    local end_time=$(( start_time + secs ))
    local resume_time=$(date -r "$end_time" +"%H:%M:%S")

    echo "Target time: $resume_time (Waiting $(( secs / 60 ))m $(( secs % 60 ))s)"

    while [ $(date +%s) -lt $end_time ]; do
        local now=$(date +%s)
        local left=$(( end_time - now ))
        local elapsed=$(( now - start_time ))
        
        # Prevent division by zero if secs is 0
        local percent=100
        [[ $secs -gt 0 ]] && percent=$(( elapsed * 100 / secs ))
        
        local filled=$(( percent / 5 ))
        local empty=$(( 20 - filled ))
        local bar_in="${(l:filled::#:)}"
        local bar_out="${(l:empty::-:)}"
        
        printf "\r[%s%s] %d%% (%02d:%02d:%02d left)" \
            "$bar_in" "$bar_out" "$percent" \
            $(( left / 3600 )) $(( (left % 3600) / 60 )) $(( left % 60 ))
        
        sleep 1
    done

    echo -e "\n\aTime's up! Resuming Claude session..."
    claude --continue --permission-mode acceptEdits "continue"
}

# Copies ~/.claude/settings.local.json to local .claude/settings.local.json
# If local file or symlink already exists, ask for confirmation before overwriting
# Rerun to update local copy from shared template
claudeme () {
	local src="$HOME/.claude/settings.local.json" # shared template file
	local dest="$PWD/.claude/settings.local.json" # local copy

	# Ensure source file exists
	if [ ! -f "$src" ]; then
		echo "Error: Source file $src does not exist"
		echo "Create it first with your shared settings."
		return 1
	fi

	# Check for existing symlink or file
	if [ -L "$dest" ] || [ -e "$dest" ]; then
		cat "$dest"
		read "confirm?$dest already exists. Overwrite with fresh copy? (y/N) "
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
			echo "Aborting."
			return 1
		fi

		echo "Removing existing file at $dest"
		rm "$dest"
	fi

	# Ensure destination directory exists
	mkdir -p "$(dirname "$dest")"

	cp "$src" "$dest" \
		&& echo "Copied $src to $dest"

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
		&& echo "Created symlink at $dest to $src"

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
					&& echo "Created symlink at $claude_dest to $src"
			fi
		else
			ln -s "$src" "$claude_dest" \
				&& echo "Created symlink at $claude_dest to $src"
		fi
	fi

	echo "You might want to add AGENTS.md and CLAUDE.md to .gitignore."
}

# Function: checkfeed
# Description: Fetches a given domain and scans the HTML head for
# standard RSS/Atom/JSON feed auto-discovery links.
# Usage: checkfeed <domain> (e.g., checkfeed example.com)
checkfeed() {
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a domain name (e.g., checkfeed example.com)"
        return 1
    fi

    local raw_domain="${1#http://}"
    raw_domain="${raw_domain#https://}"
    local base_url="https://$raw_domain"
    local html_content
    local attempts=("https://$raw_domain" "http://$raw_domain")
    local user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    echo "Attempting to fetch $raw_domain..."

    # Loop through HTTPS and HTTP attempts
    for url in "${attempts[@]}"; do
        # -L: Follow redirects, -s: Silent, -m 10: Max time 10 seconds
        # -A: Set User-Agent to appear as a browser
        # We redirect errors to /dev/null to keep the output clean.
        html_content=$(curl -L -s -m 10 -A "$user_agent" "$url" 2>/dev/null)
        if [[ -n "$html_content" ]]; then
            base_url="$url"
            echo "Successfully fetched from: $base_url"
            break
        fi
        echo "Failed to fetch $url. Trying next protocol..."
    done

    if [[ -z "$html_content" ]]; then
        echo "Error: Could not retrieve content from $raw_domain using HTTP or HTTPS."
        return 1
    fi

    # Check for bot protection / challenge pages
    if echo "$html_content" | grep -qiE "(Just a moment|Enable JavaScript and cookies to continue|checking your browser|cloudflare|cf-chl)"; then
        echo "ℹ️  Note: Bot protection detected. Auto-discovery may be limited."
    fi

    # Check if the URL itself points directly to a feed
    if echo "$html_content" | grep -qiE "(<rss|<feed|<rdf:RDF|\"@context\".*\"@type\".*\"(Blog|WebSite)\")"; then
        echo "\n✅ This URL is a feed!"
        echo "   -> $base_url"
        return 0
    fi

    # 1. Extract feed links from the HTML head.
    # We look for <link> tags with rel="alternate" and feed-related MIME types.
    # This includes: application/rss+xml, application/atom+xml, application/feed+json,
    # application/xml, text/xml, and other variations.
    local feeds_found
    feeds_found=$(
        # Find all relevant link tags (case-insensitive)
        # Match rel="alternate" with type containing feed-related keywords
        echo "$html_content" | \
        grep -oEi '<link[^>]*rel="alternate"[^>]*type="[^"]*((application|text)/(rss|atom|feed|xml)|feed\+json)[^"]*"[^>]*href="[^"]+"[^>]*>' | \
        # Extract only the href attribute value
        grep -oEi 'href="[^"]+"' | \
        sed -E 's/href="([^"]+)".*/\1/' | \
        sort -u
    )

    if [[ -n "$feeds_found" ]]; then
        echo "\n✅ Auto-discovery Feeds Found on $raw_domain:"
        local feed_url
        while read -r feed_path; do
            # Handle relative paths (starting with /)
            if [[ "$feed_path" == /* ]]; then
                # Prepend the base URL scheme and domain, removing any trailing slash if present
                feed_url="${base_url%%/}${feed_path}"
            else
                feed_url="$feed_path"
            fi
            echo "   -> $feed_url"
        done <<< "$feeds_found"
    else
        echo "\n⚠️ No standard auto-discovery feeds found in the HTML head."
        echo "   (Checked for rel='alternate' with RSS, Atom, XML, and JSON feed types)"
        echo "\n🔍 Probing common feed URLs..."

        # Common feed paths to check
        local feed_paths=("/feed/" "/feed" "/rss" "/atom.xml" "/index.xml")
        local probed_feeds=()

        for feed_path in "${feed_paths[@]}"; do
            local test_url="${base_url%%/}${feed_path}"
            # Use HEAD request (-I) to check content type without downloading full content
            # -A: Set User-Agent to appear as a browser
            local content_type=$(curl -I -L -s -m 10 -A "$user_agent" "$test_url" 2>/dev/null | grep -i "^content-type:" | head -n 1)

            # Check if content type indicates a feed
            # Match: application/rss+xml, application/atom+xml, application/xml, text/xml,
            # application/feed+json, or any content-type containing feed-related keywords
            if echo "$content_type" | grep -qiE "(application|text)/(rss|atom|xml|feed)(\+xml|\+json)?|feed\+json"; then
                probed_feeds+=("$test_url")
            fi
        done

        if [[ ${#probed_feeds[@]} -gt 0 ]]; then
            echo "\n✅ Feeds Found via Direct Probing:"
            for feed in "${probed_feeds[@]}"; do
                echo "   -> $feed"
            done
        else
            echo "\n❌ No feeds found via direct probing either."
            echo "\n💡 You may want to manually check these common paths:"
            echo "   -> ${base_url%%/}/feed"
            echo "   -> ${base_url%%/}/rss"
            echo "   -> ${base_url%%/}/atom.xml"
        fi
    fi
}

# Convert JPG to clean B&W PDF (document scan style)
jpg2pdf() {
  if [[ -z "$1" ]]; then
    echo "Usage: jpg2pdf input.jpg [output.pdf]"
    return 1
  fi

  local input="$1"
  local output="${2:-${input:r}.pdf}"

  if [[ ! -f "$input" ]]; then
    echo "Error: File '$input' not found"
    return 1
  fi

  magick "$input" \
    -colorspace Gray \
    -normalize \
    -contrast-stretch 2%x1% \
    -trim +repage \
    -sharpen 0x1.0 \
    -density 300 \
    "$output"

  echo "Created: $output"
}

2wav() {
    for file in "$@"; do
        # Extract filename without extension
        filename="${file%.*}"
        # Convert to WAV using your specific flags
        #ffmpeg -err_detect ignore_err -i "$file" -vn -acodec pcm_s16le "${filename}.wav"
        ffmpeg -err_detect ignore_err -i "$file" -vn -acodec pcm_s24le -ar 44100 -ac 1 "${filename}.wav"
    done
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

# Scan all local branches and delete those that have been merged into main.
# Uses two signals per branch (most efficient — checks local branches, not full PR history):
#   1. git branch --merged <main>        — free local check; catches direct/regular merges
#   2. gh pr list --state merged --head  — per-branch GitHub check; catches squash/rebase PRs
# Requires: gh CLI (https://cli.github.com). Falls back to signal 1 only if gh is unavailable.
# Usage: gbrclean [-n]  (-n = dry run, preview only)
gbrclean() {
    git rev-parse --abbrev-ref HEAD &>/dev/null || { echo "Not in a git repo."; return 1; }

    local dry_run=false
    [[ "$1" == "-n" ]] && dry_run=true

    # Detect the repo's actual default branch — never delete this under any circumstances
    local main_branch
    main_branch=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
    [[ -z "$main_branch" ]] && main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||')
    [[ -z "$main_branch" ]] && main_branch="main"

    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD)

    local has_gh=false
    command -v gh &>/dev/null && has_gh=true
    $has_gh || echo "  (gh CLI not found — using git signal only)"

    echo "Fetching remote refs..."
    echo ""
    git fetch --prune origin

    # All local branches except the protected main branch
    local local_branches=()
    while IFS= read -r b; do
        b="${b//\* /}"      # strip leading "* " from current branch marker
        b="${b// /}"        # trim whitespace
        [[ "$b" == "$main_branch" ]] && continue   # hard exclude — never touch main
        local_branches+=("$b")
    done < <(git branch | sed 's/^[* ]*//')

    if [[ ${#local_branches[@]} -eq 0 ]]; then
        echo "No local branches to check (only $main_branch exists)."
        return 0
    fi

    local candidates=()
    typeset -A source_map

    local total=${#local_branches[@]}
    local i=0

    for b in "${local_branches[@]}"; do
        (( i++ ))
        printf "\033[2K\r  Checking [%d/%d] %s" "$i" "$total" "$b"

        local reason=""

        # Signal 1: free local check
        if git branch --merged "$main_branch" | grep -qx "  $b\|* $b"; then
            reason="merged"
        fi

        # Signal 2: gh per-branch check (only if not already caught by signal 1)
        if [[ -z "$reason" ]] && $has_gh; then
            gh pr list --state merged --head "$b" --limit 1 --json number --jq '.[0].number' 2>/dev/null \
                | grep -q . && reason="PR merged"
        fi

        if [[ -n "$reason" ]]; then
            local sha=$(git rev-parse --short refs/heads/"$b" 2>/dev/null)
            candidates+=("$b")
            source_map[$b]="$reason $sha"
        fi
    done
    printf "\033[2K\r"  # clear the progress line

    if [[ ${#candidates[@]} -eq 0 ]]; then
        echo "No merged branches found. Nothing to clean up."
        return 0
    fi

    echo "Branches to clean up:"
    for b in "${candidates[@]}"; do
        local note=""
        [[ "$b" == "$current_branch" ]] && note=" (current — will switch to $main_branch first)"
        printf "  %-40s [%s]%s\n" "$b" "${source_map[$b]}" "$note"
    done
    echo ""
    echo "💡 Tip: git show <ref> to inspect any branch above before deleting."
    echo ""

    if $dry_run; then
        echo "Dry run — no branches deleted. Remove -n to proceed."
        return 0
    fi

    read "confirm?Delete all ${#candidates[@]} branch(es) above (local + remote where applicable)? [y/N] "
    [[ ! "$confirm" =~ ^[Yy]$ ]] && echo "Aborted." && return 0
    echo ""

    # Switch away if current branch is being deleted
    for b in "${candidates[@]}"; do
        if [[ "$b" == "$current_branch" ]]; then
            echo "Switching to '$main_branch'..."
            git checkout "$main_branch" || return 1
            echo ""
            break
        fi
    done

    local green='\033[32m'
    local red='\033[31m'
    local dim='\033[2m'
    local reset='\033[0m'
    local deleted_count=0

    for b in "${candidates[@]}"; do
        local sha="${source_map[$b]##* }"  # last word of "PR merged abc1234"
        local scope="local"

        git branch -D "$b" &>/dev/null
        if git ls-remote --exit-code --heads origin "$b" &>/dev/null; then
            git push -d origin "$b" &>/dev/null && scope="local + remote"
        fi

        printf "${green}✓${reset} %-42s ${dim}%s  %s${reset}\n" "$b" "$sha" "$scope"
        (( deleted_count++ ))
    done

    echo ""
    echo "Done. ${deleted_count} branch(es) deleted."
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

# Check redirects with enhanced diagnostics
function redir() {
	if [[ -z "$1" ]]; then
		echo "Usage: redir <url>"
		echo "  Shows redirect chain and diagnostic information"
		return 1
	fi

	local url="$1"
	local max_time="${2:-15}"  # Default 15 second timeout

	echo "🔍 Inspecting redirect chain for: $url"
	echo ""

	# Try HEAD request first (faster, less bandwidth)
	local head_response=$(curl -sIL "$url" --max-time "$max_time" -w "\nFINAL_URL:%{url_effective}\nHTTP_CODE:%{http_code}\nREDIRECTS:%{num_redirects}\nTOTAL_TIME:%{time_total}" 2>&1)
	local head_exit_code=$?

	# Check if HEAD request failed with 405 or other errors
	if [[ $head_exit_code -ne 0 ]] || echo "$head_response" | grep -q "HTTP/[12].[01] 405"; then
		echo "⚠️  HEAD request failed (Method Not Allowed or timeout)"
		echo "   Falling back to GET request..."
		echo ""

		# Fall back to GET request
		local get_response=$(curl -sL "$url" --max-time "$max_time" -D /dev/stderr -o /dev/null -w "\nFINAL_URL:%{url_effective}\nHTTP_CODE:%{http_code}\nREDIRECTS:%{num_redirects}\nTOTAL_TIME:%{time_total}" 2>&1)
		local get_exit_code=$?

		if [[ $get_exit_code -ne 0 ]]; then
			echo "❌ GET request also failed"
			echo "   Exit code: $get_exit_code"
			echo "   This may indicate:"
			echo "   - Network connectivity issues"
			echo "   - DNS resolution failure"
			echo "   - Connection timeout (try increasing timeout)"
			echo "   - Server is blocking requests"
			return 1
		fi

		# Parse and display GET results
		local response="$get_response"
		local method="GET"
	else
		# HEAD request succeeded
		local response="$head_response"
		local method="HEAD"
	fi

	# Extract metadata from curl output
	local final_url=$(echo "$response" | grep "FINAL_URL:" | cut -d':' -f2-)
	local http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d':' -f2)
	local num_redirects=$(echo "$response" | grep "REDIRECTS:" | cut -d':' -f2)
	local total_time=$(echo "$response" | grep "TOTAL_TIME:" | cut -d':' -f2)

	# Display redirect chain
	echo "📊 Redirect Chain:"
	echo "$response" | egrep -i "^(HTTP|location:)" | while read -r line; do
		if [[ "$line" =~ ^HTTP ]]; then
			echo "   $line"
		elif [[ "$line" =~ ^[Ll]ocation: ]]; then
			echo "   └─> $(echo "$line" | cut -d' ' -f2-)"
		fi
	done

	echo ""
	echo "📈 Summary:"
	echo "   Method Used: $method"
	echo "   Redirect Count: $num_redirects"
	echo "   Final URL: $final_url"
	echo "   Final Status: $http_code"
	echo "   Total Time: ${total_time}s"

	# Additional diagnostics
	if [[ "$num_redirects" -gt 3 ]]; then
		echo ""
		echo "⚠️  Warning: $num_redirects redirects detected (>3 may impact SEO and performance)"
	fi

	if (( $(echo "$total_time > 5" | bc -l 2>/dev/null || echo 0) )); then
		echo ""
		echo "⚠️  Warning: Redirect chain took ${total_time}s (>5s may impact user experience)"
	fi

	# Show server and security headers
	echo ""
	echo "🔒 Headers:"
	echo "$response" | egrep -i "^(server|x-powered-by|strict-transport-security|x-frame-options|x-content-type-options):" | sed 's/^/   /'
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

# Function: checkcanonical
# Description: Fetches a given URL and checks for canonical link tags in the HTML head.
# Usage: checkcanonical <url> (e.g., checkcanonical https://brianalexander.com/?cst)
checkcanonical() {
    if [[ -z "$1" ]]; then
        echo "Error: Please provide a URL (e.g., checkcanonical https://example.com)"
        return 1
    fi

    local url="$1"
    local html_content
    local user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    echo "Fetching $url..."

    # Fetch the URL content
    html_content=$(curl -L -s -m 10 -A "$user_agent" "$url" 2>/dev/null)

    if [[ -z "$html_content" ]]; then
        echo "Error: Could not retrieve content from $url"
        return 1
    fi

    # Extract canonical links
    local canonical_tags
    canonical_tags=$(
        echo "$html_content" | \
        grep -oEi '<link[^>]*rel="canonical"[^>]*href="[^"]+"[^>]*>' | \
        grep -oEi 'href="[^"]+"' | \
        sed -E 's/href="([^"]+)".*/\1/'
    )

    if [[ -n "$canonical_tags" ]]; then
        local tag_count=$(echo "$canonical_tags" | wc -l | tr -d ' ')

        if [[ "$tag_count" -gt 1 ]]; then
            echo "\n⚠️  WARNING: Multiple canonical tags found (should only have one):"
            echo "$canonical_tags" | while read -r tag; do
                echo "   -> $tag"
            done
        else
            echo "\n✅ Canonical URL found:"
            echo "   -> $canonical_tags"

            # Compare with input URL
            if [[ "$canonical_tags" == "$url" ]]; then
                echo "\n📌 This page is its own canonical (self-referencing)"
            else
                echo "\n📌 This is an alternate page pointing to the canonical above"
            fi
        fi
    else
        echo "\n❌ No canonical tag found"
        echo "   This page does not specify a canonical URL"
    fi
}
