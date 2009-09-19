set nocompatible
set showcmd
set incsearch
set hlsearch
set novisualbell
set t_vb=
set mouse=a
set mousemodel=popup
set mousehide
set termencoding=utf-8
set hidden
set ch=1
set autoindent
syntax enable
set number
set ruler
"set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set nocp
set nowrap
set showmatch
" set statusline=%<%f%h%m%r\ %b\ %{&encoding}\ 0x\ \ %l,%c%V\ %P
" set laststatus=2
set smartindent
set sessionoptions=curdir,buffers,tabpages
"set showfulltag
set lazyredraw
set noerrorbells
set visualbell t_vb=
autocmd GUIEnter * set visualbell t_vb=
set hidden

if ($TERM == "rxvt-unicode") && (&termencoding == "")
  set termencoding=utf-8
endif
if has('gui')
    set guioptions-=m
    " set guioptions+=m
    set guioptions-=T
    set guioptions-=l
    set guioptions-=L
    set guioptions-=r
    set guioptions-=R
end
if has("gui_running")
   "colo oceandeep
   "colo inkpot
   colo desert256
   "set guifont=Courier\ New\ 9
   "set guifont=Monospace\ 8
   set guifont=Liberation\ Mono\ 7.2
else
  if ($TERM == "linux")
    "colo desert
    colo default
  else
    set t_Co=256
    colo inkpot
  endif
endif
" Show tabs and trailing whitespace visually
if (&termencoding == "utf-8") || has("gui_running")
  "set list listchars=tab:»·,trail:·,extends:…,nbsp:<e2><80><97>
  set list listchars=tab:»·,trail:·,extends:…,precedes:…,nbsp:_
else
  set list listchars=tab:>-,trail:.,extends:>,precedes:<,nbsp:_
endif

syntax on
filetype on
filetype plugin on
filetype indent on

set autoread " reread buffer if changed
set autowrite " auto write

set backupdir=~/.vim/tmp,~/tmp,/tmp " backups(~)
set directory=~/.vim/tmp,~/tmp,/tmp " swap

set backup " enable backups

set fillchars=fold:\ " replace --- to space
"set foldenable
"set foldmethod=indent

set dictionary=/usr/share/dict/words

" words for completions
set complete=""
" current buffer
set complete+=.
" dictionary
"set complete+=k
" other buffers
set complete+=b
" tags
set complete+=t

set completeopt-=preview
"set completeopt-=longest
set mps-=[:]

function! Map_ex_cmd(key, cmd)
  execute "nmap ".a:key." " . ":".a:cmd."<CR>"
  execute "cmap ".a:key." " . "<C-C>:".a:cmd."<CR>"
  execute "imap ".a:key." " . "<C-O>:".a:cmd."<CR>"
  execute "vmap ".a:key." " . "<Esc>:".a:cmd."<CR>gv"
endfunction
function! Toggle_option(key, opt)
  call Map_ex_cmd(a:key, "set ".a:opt."! ".a:opt."?")
endfunction


function InsertSpaceWrapper()
  return "\<c-x>\<c-o>"
endfunction
imap <M-Space> <c-x><c-o>
imap <C-A> <C-X><C-O>
" CTRL-F for omni completion
imap <C-F> <C-X><C-O>

" autocompletion useing tab
function InsertTabWrapper()
     let col = col('.') - 1
     if !col || (getline('.')[col - 1] !~ '\k' && getline('.')[col - 1] != ':')
         return "\<tab>"
     else
         return "\<c-p>"
     endif
endfunction
imap <tab> <c-r>=InsertTabWrapper()<cr>

" auto completion if []
imap [ []<LEFT>
"imap ( ()<LEFT>
" autocompletion {
" imap {<CR> {<CR>}<Esc>O

" C-c and C-v - Copy/Paste в "глобальный клипборд"
vmap <C-C> "+yi
imap <C-V> <esc>"+gPi
" make shift-insert like in Xterm
map <S-Insert> <MiddleMouse>
" C-y - delete line
"nmap <C-y> dd
"imap <C-y> <esc>ddi
" C-d - dup line
imap <C-d> <esc>yypi


" set tags+=~/projects/technomagic/tags
set tags=""

"set pastetoggle=<S-F3>

call Toggle_option("<F1>", "nu")
call Map_ex_cmd("<F2>", "wa")
"call Map_ex_cmd("<S-F2>", "w")
call Map_ex_cmd("<F3>", "copen")
call Map_ex_cmd("<C-F9>", "make")
call Map_ex_cmd("<F4>", "tabnew")
"call Map_ex_cmd("<S-F4>", "tabclose")
call Map_ex_cmd("<F5>", "VCSStatus")
call Toggle_option("<S-F5>", "paste")
call Map_ex_cmd("<F6>", "tabprevious")
call Map_ex_cmd("<F7>", "tabnext")
call Map_ex_cmd("<S-F6>", "bp")
call Map_ex_cmd("<S-F7>", "bn")
call Map_ex_cmd("<F8>", "MarksBrowser")
call Map_ex_cmd("<S-F8>", "VCSDiff")
call Toggle_option("<S-F9>", "cursorcolumn")
call Toggle_option("<F9>", "spell")
call Map_ex_cmd("<F10>", "qa")
call Map_ex_cmd("<S-F10>", "q")
call Map_ex_cmd("<F11>", "TlistToggle")
call Map_ex_cmd("<F12>", "NERDTreeToggle")
call Map_ex_cmd("<S-F12>", "Ex")

" < & > - idention
vmap < <gv
vmap > >gv

" С-q - exit Vim
map <C-Q> <Esc>:qa<cr>

" Alternative
map <C-H> <Esc>:AT<cr>
imap <C-H> <C-O>:AT<cr>
map <C-J> <Esc>:IHT<cr>
imap <C-J> <C-O>:IHT<cr>

" php custom extensions
au BufRead,BufNewFile *.lib    set filetype=php
au BufRead,BufNewFile *.inc    set filetype=php
au BufRead,BufNewFile *.mod    set filetype=php
au BufRead,BufNewFile *.test    set filetype=php
au BufRead,BufNewFile *.admin    set filetype=php

let g:Tlist_Show_One_File = 1

let Tlist_Use_Right_Window=1
let Tlist_Auto_Open=0
let Tlist_Enable_Fold_Column=0

let Tlist_Exit_OnlyWindow=1
let Tlist_File_Fold_Auto_Close = 1


"let SessionMgr_AutoManage=0
"let SessionMgr_Dir="~/tmp/"

"let g:miniBufExplorerMoreThanOne=0

:ab eror error

au BufRead,BufNewFile COMMIT_EDITMSG     setf git
let g:git_diff_spawn_mode = 1

autocmd InsertEnter * set cursorline
autocmd InsertEnter * highlight StatusLine ctermbg=52
autocmd InsertLeave * highlight StatusLine ctermbg=236
autocmd InsertLeave * set nocursorline

autocmd CmdwinEnter * highlight StatusLine ctermbg=22
autocmd CmdwinLeave * highlight StatusLine ctermbg=236

" use x clipboard as unnamed
set clipboard+=unnamed
set backspace=indent,eol,start

set showcmd
set wildmenu

set shortmess+=I

set keymap=russian-jcukenwin
set iminsert=0
set imsearch=-1
set spelllang=en,ru

"imap jj <Esc>

" tab and trailing spaces fix
fun RemoveTabs()
  if ! &bin | silent! %s/\s\+$//ge | endif
  if ! &bin | silent! retab | endif
  if ! &bin | silent! set fileformat=unix | endif
endfun

"autocmd BufWrite *.cpp,*.hpp,*.lua,*.sh,*.php,*.lib,*.inc,*.mod,*.admin,*.js,*.CMakeLists.txt call RemoveTabs()
autocmd BufWrite * call RemoveTabs()

set statusline=%<%f%h%m%r\ %b\ %{&encoding}\ %{&fileformat}\ 0x\ \ %l,%c%V\ %P
set laststatus=2


:autocmd BufRead,BufNewFile *.cmake,CMakeLists.txt,*.cmake.in runtime! indent/cmake.vim
:autocmd BufRead,BufNewFile *.cmake,CMakeLists.txt,*.cmake.in setf cmake
:autocmd BufRead,BufNewFile *.ctest,*.ctest.in setf cmake
