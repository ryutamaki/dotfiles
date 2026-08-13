##-----------------------------------------------
#  Login shell settings
#
#  macOS /etc/zprofile runs path_helper, which rebuilds PATH with the system
#  directories first. That happens after .zshenv, so the path definition is
#  re-sourced here to restore the intended order for login shells.
#
#  This file is tracked in the dotfiles repo on purpose: installers love to
#  append `export PATH=...` here, and tracking it makes that show up in
#  `git status` instead of silently becoming load-bearing config that a new
#  machine never gets. If you find an appended line, move it to
#  .zsh/path.zsh and delete it from here.
##-----------------------------------------------

if [ -e ~/.zsh/path.zsh ]; then
    source ~/.zsh/path.zsh
fi

# Ruby version manager. Replaced by mise in a later commit.
if command -v rbenv > /dev/null; then
    eval "$(rbenv init - --no-rehash zsh)"
fi
