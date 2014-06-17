let mapleader=","

""-----------------------------------------------
"  NEOBundle
""-----------------------------------------------
if has('vim_starting')
  set nocompatible
  set runtimepath+=~/.vim/bundle/neobundle.vim/
endif

call neobundle#begin(expand('~/.vim/bundle/'))

NeoBundleFetch 'Shougo/neobundle.vim'

""-----------------------------------------------
"  NEOBundle > plugins
""-----------------------------------------------

NeoBundle 'Shougo/neocomplcache'
let g:acp_enableAtStartup=0
let g:neocomplcache_enable_at_startup=1


NeoBundle 'Shougo/neosnippet'
NeoBundle 'Shougo/neosnippet-snippets'
imap <C-k>     <Plug>(neosnippet_expand_or_jump)
smap <C-k>     <Plug>(neosnippet_expand_or_jump)
xmap <C-k>     <Plug>(neosnippet_expand_target)
" SuperTab like snippets behavior.
imap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: pumvisible() ? "\<C-n>" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ?
\ "\<Plug>(neosnippet_expand_or_jump)"
\: "\<TAB>"
" For snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif


NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'
nnoremap [unite] <Nop>
nmap <leader>f [unite]
nnoremap <silent> [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nnoremap <silent> [unite]m :<C-u>Unite file_mru<CR>
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
nnoremap <silent> [unite]u :<C-u>Unite buffer file_mru<CR>


NeoBundle 'scrooloose/syntastic'
let g:syntastic_enable_signs=1
let g:syntastic_auto_loc_list=1
let g:syntastic_html_tidy_ignore_errors=[" proprietary attribute \"ng-"]


NeoBundle 'itchyny/lightline.vim'
let g:lightline = {
\   'active': {
\       'left': [ [ 'mode', 'paste' ], [ 'cd', 'dir', 'filename', 'modified' ] ],
\   },
\   'component': {
\       'dir': '%.35(%{expand("%:h:s?\\S$?\\0/?")}%)',
\       'cd': '%.35(%{fnamemodify(getcwd(), ":~")}%)',
\   },
\}


NeoBundle 'tyru/caw.vim.git'
nmap <leader>/ <Plug>(caw:i:toggle)
vmap <leader>/ <Plug>(caw:i:toggle)


NeoBundle 'thinca/vim-quickrun'


""-----------------------------------------------
"  NEOBundle > colorschemes
""-----------------------------------------------

"" molokai
NeoBundle 'tomasr/molokai'
"" solarized
NeoBundle 'altercation/vim-colors-solarized'

"" Unite -- colorscheme picker
"" [usage]:Unite colorscheme -auto-preview
""        press j and k to pick a color
NeoBundle 'ujihisa/unite-colorscheme'

call neobundle#end()

filetype plugin indent on

"" If there are uninstalled bundles found on startup,
"" this will conveniently prompt you to install them.
NeoBundleCheck


""-----------------------------------------------
"  Editor settings
""-----------------------------------------------

"" The width of tab on the display
set tabstop=4
"" The width of tab when you insert one
set shiftwidth=4
"" Expand tab to spaces
set expandtab
"" Scroll with padding
set scrolloff=10
"" Enable to delete tabs or breaking lines using backspace
set backspace=start,eol,indent
"" Break a line with Enter key in normal mode
nmap <CR> i<CR><ESC>
nmap <C-h> ^
nmap <C-l> $
"" Do not use .swp files
set noswapfile
"" show corsorline
set cursorline


""-----------------------------------------------
"  Display settings
""-----------------------------------------------

syntax on
"" Display a title of an editing file
set title
"" 256 colors
set t_Co=256
"" Background
set background=dark
"" Color scheme
colorscheme molokai
"" Display number of lines
set number
"" Display ruler
set ruler
"" Display special characters
set list
"" Command line height
set cmdheight=2
"" Add statusline
set laststatus=2
"" Show commands on status line
set showcmd
"" Enable tab complement in cli
set wildmenu


""-----------------------------------------------
"  Auto check and set encoding
""-----------------------------------------------

"" copied from http://qiita.com/fl04t/items/57ebb0fe8009d00c8499
"" 文字コードの自動認識
if &encoding !=# 'utf-8'
  set encoding=japan
  set fileencoding=japan
endif
if has('iconv')
  let s:enc_euc = 'euc-jp'
  let s:enc_jis = 'iso-2022-jp'
  "" iconvがeucJP-msに対応しているかをチェック
  if iconv("\x87\x64\x87\x6a", 'cp932', 'eucjp-ms') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'eucjp-ms'
    let s:enc_jis = 'iso-2022-jp-3'
  "" iconvがJISX0213に対応しているかをチェック
  elseif iconv("\x87\x64\x87\x6a", 'cp932', 'euc-jisx0213') ==# "\xad\xc5\xad\xcb"
    let s:enc_euc = 'euc-jisx0213'
    let s:enc_jis = 'iso-2022-jp-3'
  endif
  "" fileencodingsを構築
  if &encoding ==# 'utf-8'
    let s:fileencodings_default = &fileencodings
    let &fileencodings = s:enc_jis .','. s:enc_euc .',cp932'
    let &fileencodings = &fileencodings .','. s:fileencodings_default
    unlet s:fileencodings_default
  else
    let &fileencodings = &fileencodings .','. s:enc_jis
    set fileencodings+=utf-8,ucs-2le,ucs-2
    if &encoding =~# '^\(euc-jp\|euc-jisx0213\|eucjp-ms\)$'
      set fileencodings+=cp932
      set fileencodings-=euc-jp
      set fileencodings-=euc-jisx0213
      set fileencodings-=eucjp-ms
      let &encoding = s:enc_euc
      let &fileencoding = s:enc_euc
    else
      let &fileencodings = &fileencodings .','. s:enc_euc
    endif
  endif
  "" 定数を処分
  unlet s:enc_euc
  unlet s:enc_jis
endif
