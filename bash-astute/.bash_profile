# ~/.bash_profile — login wrapper around Debian defaults + drop-ins.

if [ -f ~/.profile ]; then
    . ~/.profile
fi

if [ -d "$HOME/.bash_profile.d" ]; then
    for f in "$HOME/.bash_profile.d"/*.sh; do
        [ -r "$f" ] && . "$f"
    done
fi
