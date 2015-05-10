source $HOME/.zsh/pumice/pumice.zsh

# zsh-syntax-highlighting
pumice bundle zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting.zsh

# zsh-completions
pumice fpath zsh-users/zsh-completions src
# cdd
pumice bundle m4i/cdd cdd
typeset -ga chpwd_functions
chpwd_functions+=_cdd_chpwd
