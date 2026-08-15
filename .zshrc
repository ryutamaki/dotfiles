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


##------------------------------------------------
#  starship -- the prompt
#  Configured in config/starship.toml, which is a whitelist: any module it does
#  not name is off, including ones a future release adds.
#
#  Last on purpose. This is what sets PROMPT, and it registers a precmd hook of
#  its own -- so anything above that also touches the prompt has already had
#  its say. mise in particular hooks precmd too, and starship reads the PATH
#  mise sets when it asks node and ruby for their versions.
##------------------------------------------------
if command -v starship > /dev/null; then
    eval "$(starship init zsh)"
fi
