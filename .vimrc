""-----------------------------------------------
"   Load global settings
""-----------------------------------------------
if filereadable(expand('~/.vim/vimrc'))
    source ~/.vim/vimrc
endif

""-----------------------------------------------
"   Load local settings
""-----------------------------------------------
if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
