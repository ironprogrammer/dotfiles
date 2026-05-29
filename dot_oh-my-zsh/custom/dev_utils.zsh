# dev_utils.zsh
# Most tools have been moved to ~/.oh-my-zsh/custom/bin/

# Converts decimal seconds to MM:SS.ss format
alias convt=convert_to_time

# Converts MM:SS.ss format to decimal seconds
alias convs=convert_to_seconds

# One of @janmoesen’s ProTip™s
export PERL_LWP_SSL_VERIFY_HOSTNAME=0
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	alias "${method}"="lwp-request -m '${method}'"
done
