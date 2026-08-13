##------------------------------------------------
#  include .zsh/zshrc
##------------------------------------------------
if [ -e ~/.zsh/zshrc ]; then
    source ~/.zsh/zshrc
fi


##------------------------------------------------
#  include .zsh/plugins.zsh
##------------------------------------------------
if [ -e ~/.zsh/plugins.zsh ]; then
    source ~/.zsh/plugins.zsh
fi


##------------------------------------------------
#  fzf
#  Shell integration comes straight from the Homebrew binary, so there is no
#  generated ~/.fzf.zsh to keep in sync any more.
##------------------------------------------------
if command -v fzf > /dev/null; then
    source <(fzf --zsh)
fi
if [ -e ~/.zsh/fzf.zsh ]; then
    source ~/.zsh/fzf.zsh
fi


##------------------------------------------------
#  Node version manager. Replaced by mise in a later commit.
#  Reads .nvmrc / .node-version and switches on cd.
##------------------------------------------------
if command -v fnm > /dev/null; then
    eval "$(fnm env --use-on-cd)"
fi
