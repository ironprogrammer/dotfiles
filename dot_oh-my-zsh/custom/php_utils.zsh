# PHPStorm alias: https://www.jetbrains.com/help/phpstorm/opening-files-from-command-line.html#7521fd2d
alias phpstorm='open -na "PhpStorm.app" --args "$@"'

# Start a PHP server from a directory, optionally specifying the port
function phpserver() {
	local port="${1:-4000}";
	local ip=$(ipconfig getifaddr en0);
	sleep 1 && open "http://${ip}:${port}/" &
	php -S "${ip}:${port}";
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

# Run project-local phpcs if vendor/bin has it, else fall back to global Composer install
phpcs() {
	if [ -f "vendor/bin/phpcs" ]; then
		# call phpcs and pass in all args
		vendor/bin/phpcs $@
	else
		~/.composer/vendor/bin/phpcs $@
	fi
}

# Set Xdebug variables for CLI debugging, e.g. for phpunit
# See https://getgrav.org/blog/macos-monterey-apache-mysql-vhost-apc
xdebug-cli() {
	export XDEBUG_MODE=debug
	export PHP_IDE_CONFIG=serverName=localhost
	export XDEBUG_CONFIG=idekey=PHPSTORM remote_port=9000 remote_host=localhost remote_enable=1 remote_handler=dbgp
}
