# ~/.profile (user)

# 1. pull in Debian's upstream default, if it exists
if [ -r /etc/skel/.profile ]; then
    . /etc/skel/.profile
fi

# 2. now add own global tweaks
# (things that should apply no matter which host / shell)
# e.g. Go
if [ -d "$HOME/go/bin" ]; then
    PATH="$HOME/go/bin:$PATH"
fi

# local env helper
if [ -r "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi
