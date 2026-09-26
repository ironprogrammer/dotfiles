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

# take this repo and copy it to somewhere else minus the .git stuff
function gitexport() {
	mkdir -p "$1"
	git archive master | tar -x -C "$1"
}

# Side-by-side shortcut in Sublime Merge
smdiff() {
	smerge mergetool "$@"
}

# View lines around code changes with syntax highlighting
batdiff() {
    git diff --name-only --relative --diff-filter=d -z | xargs -0 bat --diff
}
