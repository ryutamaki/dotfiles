if has('vim_starting')
  set nocompatible
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

""----------------
"  plugins
""----------------

""----------------


""----------------
"  colorschemes
""----------------

" molokai
NeoBundle 'tomasr/molokai'
" solarized
NeoBundle 'altercation/vim-colors-solarized'


" Unite -- colorscheme picker
" [usage]:Unite colorscheme -auto-preview
"        press j and k to pick a color
NeoBundle 'Shougo/unite.vim'
NeoBundle 'ujihisa/unite-colorscheme'

""----------------



call neobundle#end()

filetype plugin indent on

" If there are uninstalled bundles found on startup,
" this will conveniently prompt you to install them.
NeoBundleCheck


" The width of tab on the display
set tabstop=4
" The width of tab when you insert one
set shiftwidth=4
" Expant tab to spaces
set expandtab


syntax on
" Display a title of an editing file
set title
" 256 colors
set t_Co=256
" Color scheme
colorscheme molokai
" Display number of lines
set number
" Display ruler
set ruler
" Display special characters
set list
