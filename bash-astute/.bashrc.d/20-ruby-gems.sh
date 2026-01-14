#!/usr/bin/env bash
# Add user gem executables to PATH when present.

gems_bin="$HOME/.local/share/gem/ruby/3.3.0/bin"
if [ -d "$gems_bin" ]; then
	case ":$PATH:" in
	*":$gems_bin:"*) ;;
	*)
		export PATH="$gems_bin:$PATH"
		;;
	esac
fi
