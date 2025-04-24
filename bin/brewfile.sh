if ! [ `which brew` ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Priority
brew install tmux
brew install tig
brew install lv

# Sub
brew install jq
brew install ag
