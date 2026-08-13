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
##-----------------------------------------------

export LANG=ja_JP.UTF-8
export LC_ALL=$LANG


##------------------------------------------------
##  include .zshenv.local
###------------------------------------------------

if [ -e ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
