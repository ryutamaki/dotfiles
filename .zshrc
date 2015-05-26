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
if [ -e ~/.zsh/fzf.zsh ]; then
    source ~/.zsh/fzf.zsh
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
