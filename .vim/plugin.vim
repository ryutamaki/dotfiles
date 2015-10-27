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

NeoBundle 'Shougo/vimproc.vim', {
\   'build' : {
\       'windows' : 'tools\\update-dll-mingw',
\       'cygwin' : 'make -f make_cygwin.mak',
\       'mac' : 'make -f make_mac.mak',
\       'linux' : 'make',
\       'unix' : 'gmake',
\   },
\}


NeoBundle 'Shougo/unite.vim'
NeoBundleLazy 'Shougo/neomru.vim', {
\   'depends': 'Shougo/unite.vim',
\   'autoload': {
\       'unite_sources': 'file_mru'
\   }
\}
let g:unite_source_history_yank_enable = 1
nnoremap [unite] <Nop>
nmap <leader>u [unite]
nnoremap [unite]f :<C-u>UniteWithBufferDir -buffer-name=files file<CR>
nnoremap [unite]m :<C-u>Unite file_mru<CR>
nnoremap [unite]b :<C-u>Unite buffer<CR>
nnoremap [unite]u :<C-u>Unite buffer file_mru<CR>
nnoremap [unite]y :<C-u>Unite history/yank<CR>


NeoBundleLazy 'hewes/unite-gtags', {
\   'depends': 'Shougo/unite.vim',
\   'autoload': {
\       'unite_sources': ['gtags/context', 'gtags/ref', 'gtags/def', 'gtags/grep', 'gtags/gtags/completion']
\   }
\}
nnoremap [unite]gcon :<C-u>Unite gtags/context<CR>
nnoremap [unite]gr :<C-u>Unite gtags/ref<CR>
nnoremap [unite]gd :<C-u>Unite gtags/def<CR>
nnoremap [unite]gg :<C-u>Unite gtags/grep<CR>
nnoremap [unite]gcom :<C-u>Unite gtags/completion<CR>


NeoBundleLazy 'rking/ag.vim', {
\   'depends': 'Shougo/unite.vim',
\   'autoload': {
\       'unite_sources': ['grep']
\   }
\}
nnoremap [unite]ag :<C-u>Unite grep:. -buffer-name=search-buffer<CR>
if executable('ag')
    let g:unite_source_grep_command = 'ag'
    let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
    let g:unite_source_grep_recursive_opt = ''
endif


if has('lua')
    NeoBundleLazy 'Shougo/neocomplete.vim', {
    \   'autoload': {
    \       'insert': '1'
    \   }
    \}
    let g:acp_enableAtStartup = 1
    let g:neocomplete#enable_at_startup  = 1
    let g:neocomplete#enable_smart_case  = 1
    let g:neocomplete#max_list = 10
    let g:neocomplete#enable_fuzzy_completion = 1
    let g:neocomplete#sources#syntax#min_keyword_length = 3
    inoremap <expr><CR>  pumvisible() ? neocomplete#close_popup() : "\<CR>"
else
    NeoBundleLazy 'Shougo/neocomplcache.vim', {
    \   'autoload': {
    \       'insert': '1'
    \   }
    \}
    let g:neocomplcache_enable_at_startup = 1
    let g:neocomplcache_enable_smart_case = 1
    let g:neocomplcache_enable_camel_case_completion = 1
    let g:neocomplcache_max_list = 10
    let g:neocomplcache_enable_underbar_completion = 1
    let g:neocomplcache_min_syntax_length = 3
    inoremap <expr><CR>  pumvisible() ? neocomplcache#smart_close_popup() : "\<CR>"
endif
inoremap <expr><TAB> pumvisible() ? "\<Down>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<Up>" : "\<S-TAB>"


NeoBundle 'scrooloose/syntastic'
let g:syntastic_check_on_open = 1
let g:syntastic_enable_signs = 1
let g:syntastic_error_symbol = 'E'
let g:syntastic_warning_symbol = 'W'
let g:syntastic_html_tidy_ignore_errors = [" proprietary attribute \"ng-"]
augroup AutoSyntastic
    autocmd!
    autocmd BufWritePost * call s:syntastic()
augroup END
function! s:syntastic()
    SyntasticCheck
    call lightline#update()
endfunction


NeoBundle 'itchyny/lightline.vim'
let g:lightline = {
\   'active': {
\       'left': [ [ 'mode', 'paste' ], [ 'readonly', 'dir', 'noname', 'modified' ] ],
\       'right': [ ['percent', 'lineinfo'], ['fileformat', 'filetype', 'fileencoding'], ['syntastic'] ],
\   },
\   'component': {
\       'dir': '%{fnamemodify(getcwd(), ":~") . "/" . expand("%")}',
\   },
\   'component_expand': {
\       'noname': 'NoName',
\       'syntastic': 'SyntasticStatuslineFlag',
\   },
\   'component_type': {
\       'noname': 'warning',
\       'syntastic': 'error',
\   },
\}
function! NoName()
    if '' == expand('%')
        return '[NO NAME]'
    else
        return ''
    fi
endfunction


NeoBundleLazy 'nathanaelkane/vim-indent-guides', {
\   'autoload': {
\       'mappings': '<Plug>IndentGuidesToggle',
\       'commands': 'IndentGuidesToggle'
\   }
\}
" Re-declare default key mappings to use NeoBundleLazy
nmap <leader>ig <Plug>IndentGuidesToggle
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  ctermbg=235
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven ctermbg=236
let g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1
let g:indent_guides_color_change_percent = 1


NeoBundle 'ntpeters/vim-better-whitespace'


NeoBundle 'tyru/caw.vim.git'
nmap <leader>/ <Plug>(caw:i:toggle)
vmap <leader>/ <Plug>(caw:i:toggle)


NeoBundleLazy 'junegunn/vim-easy-align', {
\   'autoload': {
\       'mappings': '<Plug>(EasyAlign)',
\       'commands': 'EasyAlign'
\   }
\}
vmap <Enter> <Plug>(EasyAlign)
nmap <Leader>a <Plug>(EasyAlign)


NeoBundleLazy 'thinca/vim-quickrun', {
\   'autoload': {
\       'commands': 'QuickRun'
\   }
\}


NeoBundleLazy 'mustache/vim-mustache-handlebars', {
\   'autoload': {
\       'filename_patterns': '.*\.hbs'
\   }
\}


call neobundle#end()

filetype plugin indent on

"" If there are uninstalled bundles found on startup,
"" this will conveniently prompt you to install them.
NeoBundleCheck
