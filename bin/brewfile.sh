if ! [ `which brew` ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Priority
brew install zsh
brew install git
brew install tmux
brew install vim
brew install tig
brew install lv
brew install exa

# Sub
brew install reattach-to-user-namespace
brew install imagemagick
brew install jq
brew install ag
brew install mycli
brew install thefuck
brew install n
