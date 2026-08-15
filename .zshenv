##-----------------------------------------------
#  Homebrew environment
#
#  Set statically instead of `eval "$(brew shellenv)"` so that no subprocess
#  is spawned for every zsh invocation. PATH itself lives in .zsh/path.zsh.
##-----------------------------------------------

if [ -d /opt/homebrew ]; then
    export HOMEBREW_PREFIX=/opt/homebrew
    export HOMEBREW_CELLAR=/opt/homebrew/Cellar
    export HOMEBREW_REPOSITORY=/opt/homebrew
    export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:"
    export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}"
fi


##-----------------------------------------------
#  Path settings
##-----------------------------------------------

if [ -e ~/.zsh/path.zsh ]; then
    source ~/.zsh/path.zsh
fi


##-----------------------------------------------
#  Language settings
#
#  LANG only. LC_ALL is deliberately not exported: it outranks every other
#  locale variable, including a `LANG=... command` prefix, so setting it here
#  silently disabled the `LANG=en_US.UTF-8 vcs_info` that .zsh/zshrc ran on
#  every prompt. Leaving it unset is what lets a single command ask for a
#  different locale.
#
#  That prefix is gone -- starship replaced vcs_info and parses no localized
#  output -- so nothing in this repo demonstrates the rule any more. The rule
#  is unchanged; only the proof of it left.
##-----------------------------------------------

export LANG=ja_JP.UTF-8


##------------------------------------------------
##  include .zshenv.local
###------------------------------------------------

if [ -e ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
