# `wordpress-develop` contributor command line scripts for macOS
# Requires WP-CLI: https://wp-cli.org

# use local project's PHPunit
alias phpunit='vendor/bin/phpunit'
# PHPunit aliases, e.g. `puf name_of_test`
alias pu=phpunit
alias puf='phpunit --testdox --filter'
alias pug='phpunit --testdox --group'
alias pul='phpunit --list-groups'
alias pum='phpunit --testdox -c tests/phpunit/multisite.xml'
# Enable Xdebug to drop into tests
alias xpu='XDEBUG_TRIGGER=yes pu'
alias xpuf='XDEBUG_TRIGGER=yes puf'
alias xpug='XDEBUG_TRIGGER=yes pug'
alias xpul='XDEBUG_TRIGGER=yes pul'
alias xpum='XDEBUG_TRIGGER=yes pum'

# Run e2e tests using local wp-src env (rather than wp-env).
# See https://github.com/WordPress/wordpress-develop/tree/trunk/tests/e2e.
alias e2e='WP_BASE_URL="http://wp-src.test" WP_USERNAME=admin WP_PASSWORD=password npm run test:e2e'

alias admin='wp admin'

# Check git status including nested repos under current root
alias gitsts='find ./ -name .git -exec dirname {} \; | xargs -L 1 bash -c '\''echo -e "\033[1;34m==> $0\033[0m" && cd "$0" && git status'\'''

# Open PR for current branch (https://jeff.blog/2024/02/dude-wheres-my-pr/)
# Putting --web at end can cause incorrect PR to be opened in browser; moved before owner:branch
ghpr() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local user
    user=$(git config --get remote.origin.url | sed -n 's#.*github.com[:/]\([^/]*\)/.*#\1#p')
    if [[ -n "$user" ]]; then
      gh pr view --web "$user:$(git branch --show-current)"
    else
      echo "GitHub username could not be determined."
    fi
  else
    echo "Not a Git repository."
  fi
}

# Pull repos from upstream, push to origin, and rebuild -- depends on .nvmrc with version info
# `fe` param optionally rebuilds frontend scripts in `wordpress-develop`
# Assumes upstream is the main project, and origin is your personal fork
wp-update() {
	local repo=$(basename "$(git rev-parse --show-toplevel)")
	local branch=$(git branch --show-current) # alt: $(git rev-parse --abbrev-ref HEAD)

	# Prune unused remote tracking branches
	git remote prune upstream
	git remote prune origin

	# Prune local merged branches (except the current one) that begin with * (current), the default branch, or that match ${branch}
	#git branch --merged | grep -vE "^\*|trunk|main|master|${branch}" | xargs -r git branch -d

	# Restore lock files just in case they were modified
	git restore package-lock.json 2>/dev/null
	git restore composer.lock 2>/dev/null

	# Pull latest upstream, but bail if anything fails to merge
	git pull upstream "${branch}"
	if [ "$?" -ne 0 ]; then return 1; fi

	# Sync up with personal fork
	git push origin "${branch}"

	composer update -W

	nvm use

	if [ ${repo} = 'gutenberg' ]; then
		npm install && npm run build
	else
		npm install \
		&& if [ "$1" = "fe" ]; then
				npm run build:dev
		fi
	fi
}

wp-syncit() {
	local branch=`git rev-parse --abbrev-ref --symbolic-full-name @{u}`
	git reset --hard ${branch} && git pull
}

# Apply .diff patch to `wordpress-develop` by URL
# To unapply, run `git restore .`
wp-patch() {
	if [ "$1" != "" ]
	then
		local cmd="patch:$1"
		npm run grunt ${cmd}
	else
		echo Make sure to pass in the URL of a .diff file.
	fi
}

# Toggles a symlink to arbitrary plugin folder, e.g. if repo is outside `wordpress-develop`
# Run from WordPress root where you want plugin "installed" (e.g. in `wordpress-develop/src/`)
# Important: Assumes plugin root is under ~/Sites; update `src` var as necessary
wp-ln() {
	local plugin=$1
	local src="/Users/$(whoami)/Sites/${plugin}"
	local dest="$PWD/wp-content/plugins/${plugin}"

	if [ -L ${dest} ]; then
		wp plugin deactivate ${plugin} \
		&& rm ${dest} \
		&& echo Unlinked \"${plugin}\".
	else
		if [ -e ${dest} ]; then
			echo Plugin \"${plugin}\" is installed locally. Remove with `wp plugin uninstall ${plugin} --deactivate` and rerun this command.
		else
			ln -s ${src} ${dest} \
			&& wp plugin activate ${plugin} \
			&& echo Symlinked plugin \"${plugin}\".
		fi
	fi
}

# Toggles symlink to `gutenberg` plugin, e.g. if repo is outside `wordpress-develop`
# Run from WordPress root where you want plugin "installed" (e.g. in `wordpress-develop/src/`)
# Important: Update `src` var with path to `gutenberg` directory
wp-gut() {
	local src="/Users/$(whoami)/Sites/gutenberg"
	local gut="$PWD/wp-content/plugins/gutenberg"

	if [ -L ${gut} ]; then
		wp plugin deactivate gutenberg \
		&& rm ${gut} \
		&& echo Unlinked Gutenberg.
	else
		if [ -e ${gut} ]; then
			echo Gutenberg is installed locally. Remove with `wp plugin uninstall gutenberg --deactivate` and rerun this command.
		else
			ln -s ${src} ${gut} \
			&& wp plugin activate gutenberg \
			&& echo Symlinked Gutenberg.
		fi
	fi
}

# Get version info to copy/paste into test report -- geared toward macOS, depends on WP-CLI
wp-test() {
	wp core is-installed 2>/dev/null
	local wp_installed=`echo $?`
	local wp_path=''
	if [ ${wp_installed} = 1 ]; then wp_path='--path=src'; fi
	echo - - Hardware: $( system_profiler SPHardwareDataType | sed -nr 's/(Model Name|Chip):[[:space:]](.*)/\2/p' | tr -d '\n' )
	echo - - OS: macOS $( sw_vers -productVersion )
	echo - - Browser: Safari $( /usr/libexec/PlistBuddy -c "print :CFBundleShortVersionString" /Applications/Safari.app/Contents/Info.plist ) \
		/ $( /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version ) \
		/ $( /Applications/Firefox.app/Contents/MacOS/firefox -v )
	echo - - $( curl -sSL -D - $( wp option get siteurl ${wp_path} ) -o /dev/null | grep '^Server: *' )
	echo - - PHP: $( php -r "echo phpversion().PHP_EOL;" ) \($( php -m | grep -E "gd|imagick" | paste -sd ',' - )\)
	# Check if there's a wp-db.sqlite file to return the appropriate DB info.
	if [ -f "wp-db.sqlite" ]; then
		echo - - SQLite: $( sqlite3 --version 2>/dev/null | sed -n 's/\([^ ]*\).*/\1/p' )
	else
		echo - - MySQL: $( wp db check --version ${wp_path} 2>/dev/null | sed -n 's/.*Ver \([^ ]*\).*/\1/p' )
	fi
	echo - - WordPress: $( wp core version ${wp_path} 2>/dev/null ) / $( wp cli version ${wp_path} 2>/dev/null )
	echo - - Theme: $( wp theme status ${wp_path} | grep "  A " | sed 's/.*  A //' )
	echo - - Active Plugins: $( wp plugin status ${wp_path} | grep "  A " | sed 's/.*  A //' | tr '\n' ',' | sed 's/,/, /g; s/, $//' )
	echo - - Must Use Plugins: $( wp plugin status ${wp_path} | grep "  M " | sed 's/.*  M //' | tr '\n' ',' | sed 's/,/, /g; s/, $//' )
}

# Get current project's WordPress version, NOT dependent on WP-CLI (i.e. `wp core version`)
wp-version() {
	if [ -d "wp-includes" ]; then
		grep '^$wp_version' wp-includes/version.php
	else
		grep '^$wp_version' src/wp-includes/version.php
	fi
}

# Get current project's Gutenberg version, NOT dependent on WP-CLI
gb-version() {
	if [ -d "wp-content" ]; then
		grep '"version"' wp-content/plugins/gutenberg/package.json
	else
		# Assume we're in the gutenberg repo
		grep '"version"' package.json
	fi
}

# Jumps to root of current WP site
wp-root() {
	local root=`wp eval 'echo ABSPATH;'`
	if [ -d "${root}" ]; then
  		cd ${root};
	fi
}

# Kill untracked files that cause issue with $_old_files array, e.g. when running `npm run build`
wp-old() {
	for file in `git ls-files -o src/wp-admin`; do; rm $file; done
	for file in `git ls-files -o src/wp-includes`; do; rm $file; done
}

# Spin up a SQLite WP site, e.g.: `wp-sqlite wp-603 6.0.3`
# If omitted, version defaults to latest, and pins rollback to that version
# @TODO consider using https://developer.wordpress.org/cli/commands/cli/alias/ for locals?
wp-sqlite() {
	local wp_name=''
	local wp_ver='latest'

	# check required arg for site name
	if [ -z "$1" ]; then
		echo Usage: wp-sqlite site-name \[wp-version\]
		echo You must specify a site name.
		return 1
	fi
	wp_name="$1"

	# optional wordpress version
	if [ ! -z "$2" ]; then
		wp_ver="$2"
	fi

	# confirm whether to continue
	echo Site Name: ${wp_name}
	echo WordPress Version: ${wp_ver}
	[[ "$(echo -n 'Continue with installation? [y/N] ' >&2; read -q; echo $REPLY)" == [Nn]* ]] \
		&& echo && echo Aborted. && return 1

	# confirmed! do the deed...
	# set up folder
	echo && echo "Installing ${wp_name}..."
	mkdir ${wp_name} && cd ${wp_name}
	if [ "$?" -ne 0 ]; then return 1; fi

	# install wordpress files
	if [ ${wp_ver} != 'latest' ]; then
		wp core download https://wordpress.org/wordpress-${wp_ver}.zip
	else
		wp core download
		wp_ver=$(wp core version)
	fi
	if [ "$?" -ne 0 ]; then return 1; fi

	# create .env for `wp-reset` rollback option
	echo "wp_name=${wp_name}" > .env
	echo "wp_ver=${wp_ver}" >> .env

	# install sqlite
	curl https://raw.githubusercontent.com/aaemnnosttv/wp-sqlite-db/master/src/db.php -o wp-content/db.php
	# fix min required mysql version 5.5.5 introduced in 6.5; opt for 8.0 like canonical plugin uses
	# see https://make.wordpress.org/core/2023/12/08/raising-the-minimum-version-of-mysql-required-in-wordpress-6-5/
	sed -i '' "s/'5.5'/'8.0'/g" wp-content/db.php
	# not needed after merge of update pr, https://github.com/aaemnnosttv/wp-sqlite-db/pull/61

	# create database file
	touch wp-db.sqlite

	# create wp-config.php
	echo "<?php\n" >> wp-config.php
	echo "define( 'DB_DIR', __DIR__ );" >> wp-config.php
	echo "define( 'DB_FILE', 'wp-db.sqlite' );" >> wp-config.php
	echo -n "\n//$(cat wp-config-sample.php)" >> wp-config.php

	# prevent auto update for previous point versions
	wp config set WP_AUTO_UPDATE_CORE false --raw

	# set up site
	wp core install --url=${wp_name}.test --title=${wp_name} --admin_user=admin --admin_password=password --admin_email=admin@example.com --skip-email

	# FYI: valet still asks for password when checking `valet links`, so may as well just re-add
	echo "Gonna ask for sudo to set up Valet link..."
	valet >/dev/null 2>/dev/null && valet link ${wp_name}
	if [ "$?" -ne 0 ]; then return 1; fi

	# launch wp-admin
	wp admin
}

# Reset WordPress core to original version for this directory
wp-reset() {
	if [ ! -f ".env" ]; then
		echo Directory not set up for `wp-reset` rollback.
		return 1
	fi
	source .env

	if [ ${wp_ver} = '' ]; then
		echo There is no rollback \`wp_ver\` set.
		return 1
	fi

	[[ "$(echo -n "Upgrade/rollback to WordPress ${wp_ver}? [y/N] " >&2; read -q; echo $REPLY)" == [Nn]* ]] \
		&& echo && echo Aborted. && return 1

	echo
	wp core upgrade https://wordpress.org/wordpress-${wp_ver}.zip --force

	echo Make sure to reset or restore the database, if needed.
}

# Kills current throwaway site
wp-kill() {
	if [ ! -f ".env" ]; then
		echo Directory not set up for \`wp-kill\`.
		return 1
	fi
	source .env

	if [ ${wp_name} = '' ]; then
		echo There is no `wp_name` set.
		return 1
	fi

	cd ..
	rm -r ${wp_name} \
		&& echo Site killed.
}

# Backup, restore, or reset SQLite database file
alias db=wp-db
wp-db() {
	if [ -z "$1" ]; then
		echo Usage: db backup\|restore\|reset
		return 1
	fi

	local db_file="wp-db.sqlite"
	if [ $1 = 'restore' ]; then
		cp ${db_file}.bak ${db_file} \
			&& echo SQLite DB restored from ${db_file}.bak.
	elif [ $1 = 'backup' ]; then
		cp ${db_file} ${db_file}.bak \
			&& echo SQLite DB backed up to ${db_file}.bak.
	elif [ $1 = 'reset' ]; then
		source .env
		if [ ${wp_name} = '' ]; then
			echo There is no `wp_name` set.
			return 1
		fi
		mv ${db_file} ${db_file}.bak \
			&& echo SQLite DB backed up to ${db_file}.bak. \
			&& touch ${db_file} \
			&& wp core install --url=${wp_name}.test --title=${wp_name} --admin_user=admin --admin_password=password --admin_email=admin@example.com --skip-email
	else
		echo Command \"$1\" not recognized.
	fi
}

# Set/unset WP_DEBUG values
wp-debug() {
	local wp_debug=true
	if [ `wp config get WP_DEBUG` ]; then
		echo Debug enabled.
	else
		echo Debug disabled.
		wp_debug=false
	fi

	# check if in wordpress-develop repo
	local prefix=
	if [ -d "src/wp-content" ]; then
		prefix=src/
	fi

	if [ -z "$1" ]; then
		open -a Console.app ${prefix}wp-content/debug.log
		return 0
	elif [ $1 = 'roll' ]; then
		roll-debug
		return 0
	elif [ $1 = 'on' ]; then
		wp_debug=true
	elif [ $1 = 'off' ]; then
		wp_debug=false
	else
		return 1
	fi

	# swap the settings
	# @TODO look at adding new defines if not present, but only changing value of WP_DEBUG itself
	wp config set WP_DISABLE_FATAL_ERROR_HANDLER ${wp_debug} --raw
	wp config set WP_DEBUG ${wp_debug} --raw
	wp config set WP_DEBUG_DISPLAY ${wp_debug} --raw
	wp config set WP_DEBUG_LOG ${wp_debug} --raw
	wp config set SAVEQUERIES ${wp_debug} --raw
	wp config set SCRIPT_DEBUG ${wp_debug} --raw

	echo Debug set to ${wp_debug}.

	# if debug.log doesn't aleady exist, create one
	if [ ! -f "${prefix}wp-content/debug.log" ]; then
		touch ${prefix}wp-content/debug.log
		echo Created debug.log file.
	fi

	# open the log in Console
	open -a Console.app ${prefix}wp-content/debug.log
}

# Basic log roll
roll-debug() {
	local prefix=
	if [ -d "src/wp-content" ]; then
		prefix=src/
	fi
	echo Rolling log...
	mv -v ${prefix}wp-content/debug{,-$(date +%Y%m%d_%H%M%S)}.log
	touch ${prefix}wp-content/debug.log
	echo Opening new log...
	open -a Console.app ${prefix}wp-content/debug.log
}

# Create a list of Trac queries showing old/abandoned tickets from 2006 to 2022, for 2022 DM Bottle Pickup exercise
dateit() {
for i in {2006..2022}; do
	echo "<a href=\"https://core.trac.wordpress.org/query?status=accepted&status=assigned&status=new&status=reopened&status=reviewing&time=1%2F1%2F$i..12%2F31%2F$i&col=id&col=summary&col=status&col=owner&col=type&col=priority&col=milestone&order=priority\">$i</a>"
done
}

# Get test team weekly update post content; assumes running on Monday
test-update() {
	local where_am_i=$(pwd)
	cd ~/Sites/trac-query/src
	echo Please wait...
	php team-update.php | pbcopy
	echo This week\'s team update has been copied to the clipboard.
	cd ${where_am_i}
}

# Copies files from shared mu-plugins into current site
mu-me() {
	if [ ! -d "wp-content/mu-plugins" ]; then
		mkdir wp-content/mu-plugins
	fi
	cp ~/Sites/mu-plugins/*.php wp-content/mu-plugins/
}

# Toggles wp-config.php for both src and test envs
docker-toggle() {
	# Make sure this is the `wordpress-develop` directory, otherwise bail out.
	if [ `basename $(pwd)` != 'wordpress-develop' ]; then
		echo You must be in the \`wordpress-develop\` directory to toggle the Docker config.
		return 1
	fi

	local docker_on=false
	if [ -f 'wp-config.php.docker.bak' ]; then
		echo Docker config is off.
	else
		echo Docker config is on.
		local docker_on=true
	fi

	local enable=false
	if [ -z "$1" ]; then
		return 0
	elif [ $1 = 'on' ]; then
		enable=true
	elif [ $1 = 'off' ]; then
		enable=false
	else
		return 1
	fi

	if [[ ${enable} = true && ${docker_on} = false ]]; then
		mv wp-config.php wp-config.php.local.bak
		mv wp-config.php.docker.bak wp-config.php
		mv wp-tests-config.php wp-tests-config.php.local.bak
		mv wp-tests-config.php.docker.bak wp-tests-config.php

		echo Docker config is now ON.
		echo -
		echo Running
		echo - - Use \`npm run build:dev \&\& npm run env:start\` to build WP and launch the container.
		echo - - Use \`npm run env:install\` to \(re\)install WP to the container.
		echo - - Use \`npm run env:restart\` to reload after config changes.
		echo - - Use \`npm run env:stop\` when complete.
		echo -
		echo PHPUnit
		echo - - Use \`npm run test:php\` to run PHPunit tests.
		echo - - Use \`npm run test:php \-\- --filter testname'' to filter PHPunit tests.
		echo -
		echo E2E
		echo - - Use \`npm run test:e2e\` to run E2E tests.
		echo - - For interactive tests, use \`npm run dev\` and \`npm run test:e2e \-\- --ui\` in another terminal.
		echo -

		echo Opening http://localhost:8889...you may need to refresh after building the env.
		open http://localhost:8889
	elif [[ ${enable} = false && ${docker_on} = true ]]; then
		mv wp-config.php wp-config.php.docker.bak
		mv wp-config.php.local.bak wp-config.php
		mv wp-tests-config.php wp-tests-config.php.docker.bak
		mv wp-tests-config.php.local.bak wp-tests-config.php

		echo Docker config is now OFF.
	fi
}
