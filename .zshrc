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
export PATH="$HOME/.local/bin:$PATH"
# Volta を無効化して fnm に移行 (戻す場合は下 2 行のコメントを外し、fnm 行を消す)
# export VOLTA_HOME="$HOME/.volta"
# export PATH="$VOLTA_HOME/bin:$PATH"

# fnm (Node version manager) — .nvmrc / .node-version を読んで cd 時に自動切替
eval "$(fnm env --use-on-cd)"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/Users/ryutamaki/.local/bin:$PATH"
