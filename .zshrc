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
#  mise -- Node, Ruby and Terraform versions
#  Versions are pinned in config/mise/config.toml. Repositories with their own
#  .node-version, .nvmrc, .ruby-version or mise.toml override them on cd.
##------------------------------------------------
if command -v mise > /dev/null; then
    eval "$(mise activate zsh)"
fi
