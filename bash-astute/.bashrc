# ~/.bashrc: wrapper around Debian defaults + drop-ins.

case $- in
    *i*) ;;
      *) return;;
esac

if [ -r /etc/skel/.bashrc ]; then
    . /etc/skel/.bashrc
elif [ -r /etc/bash.bashrc ]; then
    . /etc/bash.bashrc
fi

if [ -d "$HOME/.bashrc.d" ]; then
    for f in "$HOME/.bashrc.d"/*.sh; do
        [ -r "$f" ] && . "$f"
    done
fi
