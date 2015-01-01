##------------------------------------------------
#  include .zsh/zshrc
##------------------------------------------------
if [ -e ~/.zsh/zshrc ]; then
    source ~/.zsh/zshrc
fi


##------------------------------------------------
#  include .zsh/antigen.zsh
##------------------------------------------------
if [ -e ~/.zsh/antigen.zsh ]; then
    source ~/.zsh/antigen.zsh
fi


##------------------------------------------------
#  include .zshenv.local
##------------------------------------------------

if [ -e ~/.zshenv.local ]; then
    source ~/.zshenv.local
fi
