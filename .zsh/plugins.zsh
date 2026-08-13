##-----------------------------------------------
#  zsh plugins
#
#  All installed through Homebrew (see Brewfile). There is no plugin manager:
#  `brew bundle` already is one, and it is the same mechanism that installs
#  everything else on a fresh machine.
#
#  Load order matters -- zsh-syntax-highlighting has to come last.
##-----------------------------------------------

brew_prefix=${HOMEBREW_PREFIX:-/opt/homebrew}

## z -- jump to a frequently used directory. Wrapped with fzf in .zsh/fzf.zsh,
## which needs the _z function defined here.
if [ -f "$brew_prefix/etc/profile.d/z.sh" ]; then
    source "$brew_prefix/etc/profile.d/z.sh"
fi

## zsh-autosuggestions -- suggests a completion from history as you type
if [ -f "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$brew_prefix/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

## zsh-syntax-highlighting -- must be sourced last
if [ -f "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$brew_prefix/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

unset brew_prefix
