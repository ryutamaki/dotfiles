if ! [ `which brew` ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Priority
brew install git
brew install tmux
brew install vim
brew install tig
brew install lv
brew install exa

# Sub
brew install reattach-to-user-namespace
brew install jq
brew install ag
