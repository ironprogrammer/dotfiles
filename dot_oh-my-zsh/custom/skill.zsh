# skill.zsh
# `skill` opens an installed skill for hand-editing, plus its completion.

# Prints name<TAB>path for every installed skill, deduped by path.
_skill_index() {
	{ skills ls --json; skills ls -g --json } 2>/dev/null \
		| jq -rs 'add | unique_by(.path) | sort_by(.name) | .[] | "\(.name)\t\(.path)"'
}

# Opens a skill in $VISUAL/$EDITOR (override with $SKILL_EDITOR).
skill() {
	emulate -L zsh

	local -a ed
	ed=(${(z)${SKILL_EDITOR:-${VISUAL:-${EDITOR:-subl}}}})
	# The editor may be an alias (oh-my-zsh defines `subl` as one), which a
	# plain command lookup would miss.
	(( $+aliases[$ed[1]] )) && ed=(${(Q)${(z)${aliases[$ed[1]]}}} ${ed[2,-1]})
	# Inherited editor settings usually wait and open a new window, so commit
	# messages work; drop both so this lands in the window already open and
	# the shell comes straight back. $SKILL_EDITOR is used as-is.
	[[ -z "$SKILL_EDITOR" ]] && ed=(${ed:#(-n|-w|--wait|--new-window)})

	local index
	index="$(_skill_index)"
	if [[ -z "$index" ]]; then
		print -u2 "skill: no installed skills found"
		return 1
	fi

	# Bare name list, for shell completion.
	if [[ "$1" == --names ]]; then
		print -r -- "$index" | cut -f1 | sort -u
		return 0
	fi

	if [[ -z "$1" || "$1" == -h || "$1" == --help ]]; then
		print "Usage: skill <name>   # open a skill in \$VISUAL/\$EDITOR (override: \$SKILL_EDITOR)"
		print "\nInstalled skills:"
		print -r -- "$index" | cut -f1 | sort -u | sed 's/^/  /'
		return 0
	fi

	# Exact name wins; otherwise fall back to substring matching.
	local matches
	matches=$(print -r -- "$index" | awk -F'\t' -v q="$1" '$1 == q')
	[[ -z "$matches" ]] && matches=$(print -r -- "$index" | awk -F'\t' -v q="$1" 'index($1, q)')

	if [[ -z "$matches" ]]; then
		print -u2 "skill: no skill matching '$1' (try \`skill\` to list them)"
		return 1
	fi

	if [[ $(print -r -- "$matches" | wc -l) -gt 1 ]]; then
		print -u2 "skill: '$1' is ambiguous:"
		print -r -- "$matches" | awk -F'\t' '{printf "  %-24s %s\n", $1, $2}' >&2
		return 1
	fi

	if ! command -v "$ed[1]" >/dev/null; then
		print -u2 "skill: editor '$ed[1]' not found (set \$SKILL_EDITOR)"
		return 1
	fi

	# Open SKILL.md itself; anything else in the skill is a sidebar away.
	local dir="${matches#*$'\t'}"
	[[ -f "$dir/SKILL.md" ]] && ed+=("$dir/SKILL.md") || ed+=("$dir")
	"${ed[@]}"
}

# Completes installed skill names.
_skill() {
	local -a names
	names=(${(f)"$(skill --names 2>/dev/null)"})
	(( ${#names} )) && _describe -t skills 'skill' names
}
compdef _skill skill
