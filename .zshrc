##------------------------------------------------
#  include .zsh/zshrc
##------------------------------------------------
if [ -e ~/.zsh/zshrc ]; then
    source ~/.zsh/zshrc
fi


##------------------------------------------------
#  include .zsh/pumice.zsh
##------------------------------------------------
if [ -e ~/.zsh/pumice.zsh ]; then
    source ~/.zsh/pumice.zsh
fi


##------------------------------------------------
#  include .zsh/fzf.zsh
##------------------------------------------------
if [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi
if [ -e ~/.zsh/fzf.zsh ]; then
    source ~/.zsh/fzf.zsh
fi

##------------------------------------------------
#  Paths that must be prepended in interactive shells
#  (moved into .zshenv in a later commit)
##------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# fnm (Node version manager) — .nvmrc / .node-version を読んで cd 時に自動切替
eval "$(fnm env --use-on-cd)"
