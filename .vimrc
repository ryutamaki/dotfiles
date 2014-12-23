""-----------------------------------------------
"   Load global settings
""-----------------------------------------------
if filereadable(expand('~/.vim/vimrc'))
    source ~/.vim/vimrc
endif

if filereadable(expand('~/.vim/plugin.vim'))
    source ~/.vim/plugin.vim
endif

""-----------------------------------------------
"   Load local settings
""-----------------------------------------------
if filereadable(expand('~/.vimrc.local'))
    source ~/.vimrc.local
endif
