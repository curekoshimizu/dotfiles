
"{{{ color functions
" RGB values to '#rrggbb'.
function! s:rgb2hex(r, g, b)
    return printf("#%02x%02x%02x", a:r, a:g, a:b)
endfunction

" returns an approximate grey index for the given grey level
function! s:grey_level2number(x)
    if &t_Co == 88
        if a:x < 23
            return 0
        elseif a:x < 69
            return 1
        elseif a:x < 103
            return 2
        elseif a:x < 127
            return 3
        elseif a:x < 150
            return 4
        elseif a:x < 173
            return 5
        elseif a:x < 196
            return 6
        elseif a:x < 219
            return 7
        elseif a:x < 243
            return 8
        else
            return 9
        endif
    else
        if a:x < 14
            return 0
        else
            let l:n = (a:x - 8) / 10
            let l:m = (a:x - 8) % 10
            if l:m < 5
                return l:n
            else
                return l:n + 1
            endif
        endif
    endif
endfunction

" returns the actual grey level represented by the grey index
function! s:grey_number2level(n)
    if &t_Co == 88
        if a:n == 0
            return 0
        elseif a:n == 1
            return 46
        elseif a:n == 2
            return 92
        elseif a:n == 3
            return 115
        elseif a:n == 4
            return 139
        elseif a:n == 5
            return 162
        elseif a:n == 6
            return 185
        elseif a:n == 7
            return 208
        elseif a:n == 8
            return 231
        else
            return 255
        endif
    else
        if a:n == 0
            return 0
        else
            return 8 + (a:n * 10)
        endif
    endif
endfunction

" returns the palette index for the given grey index
function! s:grey_color2index(n)
    if &t_Co == 88
        if a:n == 0
            return 16
        elseif a:n == 9
            return 79
        else
            return 79 + a:n
        endif
    else
        if a:n == 0
            return 16
        elseif a:n == 25
            return 231
        else
            return 231 + a:n
        endif
    endif
endfunction

" returns an approximate color index for the given color level
function! s:rgb_level2number(x)
    if &t_Co == 88
        if a:x < 69
            return 0
        elseif a:x < 172
            return 1
        elseif a:x < 230
            return 2
        else
            return 3
        endif
    else
        if a:x < 75
            return 0
        else
            let l:n = (a:x - 55) / 40
            let l:m = (a:x - 55) % 40
            if l:m < 20
                return l:n
            else
                return l:n + 1
            endif
        endif
    endif
endfunction

" returns the actual color level for the given color index
function! s:rgb_number2level(n)
    if &t_Co == 88
        if a:n == 0
            return 0
        elseif a:n == 1
            return 139
        elseif a:n == 2
            return 205
        else
            return 255
        endif
    else
        if a:n == 0
            return 0
        else
            return 55 + (a:n * 40)
        endif
    endif
endfunction

" returns the palette index for the given R/G/B color indices
function! s:rgb_color2index(x, y, z)
    if &t_Co == 88
        return 16 + (a:x * 16) + (a:y * 4) + a:z
    else
        return 16 + (a:x * 36) + (a:y * 6) + a:z
    endif
endfunction

" returns the palette index to approximate the given R/G/B color levels
function! s:get_palette_index(r, g, b)
    " get the closest grey
    let l:gx = s:grey_level2number(a:r)
    let l:gy = s:grey_level2number(a:g)
    let l:gz = s:grey_level2number(a:b)

    " get the closest color
    let l:x = s:rgb_level2number(a:r)
    let l:y = s:rgb_level2number(a:g)
    let l:z = s:rgb_level2number(a:b)

    if l:gx == l:gy && l:gy == l:gz
        " there are two possibilities
        let l:dgr = s:grey_number2level(l:gx) - a:r
        let l:dgg = s:grey_number2level(l:gy) - a:g
        let l:dgb = s:grey_number2level(l:gz) - a:b
        let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
        let l:dr = s:rgb_number2level(l:gx) - a:r
        let l:dg = s:rgb_number2level(l:gy) - a:g
        let l:db = s:rgb_number2level(l:gz) - a:b
        let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
        if l:dgrey < l:drgb
            " use the grey
            return s:grey_color2index(l:gx)
        else
            " use the color
            return s:rgb_color2index(l:x, l:y, l:z)
        endif
    else
        " only one possibility
        return s:rgb_color2index(l:x, l:y, l:z)
    endif
endfunction

function! ManualBgColor(r, g, b, isFgWhite)
    let cterm = s:get_palette_index(a:r, a:g, a:b)
    let gterm = s:rgb2hex(a:r, a:g, a:b)

    let body = printf("ctermbg=%d guibg=%s", cterm, gterm)

    if a:isFgWhite
        return body . " ctermfg=white guifg=#ffffff"
    else
        return body . " ctermfg=black guifg=#222222"
    endif
endfunction

function! ManualFgColor(r, g, b, isBgWhite)
    let cterm = s:get_palette_index(a:r, a:g, a:b)
    let gterm = s:rgb2hex(a:r, a:g, a:b)

    let body = printf("ctermfg=%d guifg=%s", cterm, gterm)

    if a:isBgWhite
        return body . " ctermbg=white guibg=#ffffff"
    else
        return body . " ctermbg=black guibg=#222222"
    endif
endfunction

function! SetManualBgColor(name, r, g, b, isFgWhite)
    execute printf("highlight %s ", a:name) . ManualBgColor(a:r, a:g, a:b, a:isFgWhite)
endfunction

function! SetManualFgColor(name, r, g, b, isFgWhite)
    execute printf("highlight %s ", a:name) . ManualFgColor(a:r, a:g, a:b, a:isFgWhite)
endfunction

"}}}

"""======== Windows Kaoriya settings start ============="
""if has('win32')
""    let s:script_path = expand('<sfile>:p:h')
""    let s:kaoriya_settings_path = s:script_path . '/.vimrc.kaoriya'
""    if filereadable(s:kaoriya_settings_path)
""        execute 'source ' s:kaoriya_settings_path
""    endif
""
""    let $PATH = s:script_path . 'winbin;' . $PATH
""endif
"""======== Windows Kaoriya settings end ==============="

let s:script_path = expand('<sfile>:p:h')
"======== NeoBundle settings start ==================="
let s:neobundle_settings_path = s:script_path . '/.vimrc.neobundle'
let use_neobundle = 0
if filereadable(s:neobundle_settings_path) && use_neobundle
    execute 'source ' s:neobundle_settings_path
endif
"======== NeoBundle settings end ===================="
"======== Plug settings start ==================="
let s:plug_settings_path = s:script_path . '/.vimrc.plug'
let use_plug = 1
if filereadable(s:plug_settings_path) && use_plug
    execute 'source ' s:plug_settings_path
endif
"======== Plug settings end ===================="

"{{{ QuickFix Settings
map <silent> <CS-j> <ESC>:cn<CR>
map <silent> <CS-k> <ESC>:cp<CR>

map <silent> ,q <ESC>:QFix<CR>
map <silent> ,Q <ESC>:QFix<CR>
command -bang -nargs=? QFix call QFixToggle(<bang>0)
function! QFixToggle(forced)
    if exists("g:qfix_win") && a:forced == 0
        cclose
        unlet g:qfix_win
    else
        bot copen 10
        call AdjustWindowHeight(3, 10)
        let g:qfix_win = bufnr("$")
    endif

   autocmd FileType qf call AdjustWindowHeight(3, 10)
endfunction

function! AdjustWindowHeight(minheight, maxheight)
   let l = 1
   let n_lines = 0
   let w_width = winwidth(0)
   while l <= line('$')
       " number to float for division
       let l_len = strlen(getline(l)) + 0.0
       let line_width = l_len/w_width
       let n_lines += float2nr(ceil(line_width))
       let l += 1
   endw
   exe max([min([n_lines, a:maxheight]), a:minheight]) . "wincmd _"
endfunction

function! s:del_entry() range
    let qf = getqflist()
    let history = get(w:, 'qf_history', [])
    call add(history, copy(qf))
    let w:qf_history = history
    unlet! qf[a:firstline - 1 : a:lastline - 1]
    call setqflist(qf, 'r')
    execute a:firstline
endfunction

function! s:undo_entry()
    let history = get(w:, 'qf_history', [])
    if !empty(history)
        call setqflist(remove(history, -1), 'r')
    endif
endfunction

augroup QuickFixClose
    autocmd!
    autocmd FileType qf nnoremap <silent> <buffer> q          :ccl<CR>
    autocmd FileType qf nnoremap <silent> <buffer> dd :call <SID>del_entry()<CR>
    autocmd FileType qf nnoremap <silent> <buffer> u  :call <SID>undo_entry()<CR>
augroup END
ccl
"}}}


"{{{ tab settings
set tabstop=4
set shiftwidth=4
set expandtab
augroup NoExpandTab
    autocmd!
    autocmd FileType make setlocal noexpandtab
    " lancelot ...
    autocmd FileType c++ setlocal noexpandtab
augroup END
"}}}


"{{{ color settings (loading .vim/my_color_settings.vim)
syntax on
"""""""""""""set synmaxcol=1500
set laststatus=2
set t_Co=256
set background=dark
"}}}


"{{{ encoding settings
set fileformats=unix,dos,mac
"set fileencodings=iso-2022-jp,euc-jp,utf-8,cp932,ascii
set fileencodings=utf-8,iso-2022-jp,euc-jp,cp932,ascii
if has("win32")
    set encoding=cp932
else
    set encoding=utf-8
endif

function! ReEstimateFenc()
    if &fileencoding =~# 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
        let &fileencoding=&encoding
    endif
endfunction

augroup auto-encode
    autocmd BufReadPre COMMIT_EDITMSG setlocal fileencodings=utf-8
    autocmd BufReadPost * call ReEstimateFenc()
augroup END
"}}}

"{{{ Color Settings

function! s:EnhanceGoSyntax()
    hi GoError term=none cterm=bold ctermfg=214 gui=none guifg=gold3
    match goError /\<err\>/
endfunction

hi def link goFunctionCall Function
hi def link goMethodCall   Function

augroup GoSyntax
    autocmd!
    autocmd FileType go call s:EnhanceGoSyntax()
augroup END


"call SetManualFgColor("Function", 100, 181, 246, 0)
"call SetManualFgColor("Function", 121, 134, 203, 0)
call SetManualFgColor("Function",  33, 150, 243, 0)
"call SetManualBgColor("Function",  255, 193,   7, 0)
"call SetManualFgColor("Function",  233,  30,  99, 0)
"call SetManualBgColor("Function",   92, 107, 192, 1)
"call SetManualBgColor("Function",   61,  90, 254, 1)
"call SetManualFgColor("Function", 255,  87,  34, 0)

highlight LspErrorHighlight term=underline cterm=underline gui=underline
highlight LspWarningHighlight term=underline cterm=underline gui=underline
function! s:EnhanceCppSyntax()
    syntax match cCustomFunc '[a-zA-Z_]\+\w*\s*(\@='
    syntax match cCustomScope    "::"
    syntax match cCustomClass    "\w\+\s*::" contains=cCustomScope
    hi def link cCustomFunc Function 
    hi def link cCustomClass Function 
    syntax keyword cCustomType ULONG USHORT UINT UCHAR SLONG SINT SCHAR BOOL
    hi def link cCustomType Type
endfunction
augroup CppSyntax
    autocmd!
    autocmd FileType c,cpp call s:EnhanceCppSyntax()
augroup END

" For Markdown
" TODO: bold 化したい (拡張すること)
"execute 'highlight MarkdownLevelX ' . ManualBgColor(255, 152, 0, 0)
execute 'highlight MarkdownLevelX ' . ManualBgColor(255, 167, 38, 0)
function! s:EnhanceMarkdownSyntax()
    syntax match cMarkdownLevel1 '^# .*$'
    syntax match cMarkdownLevel2 '^## .*$'
    syntax match cMarkdownLevel3 '^### .*$'
    syntax match cMarkdownLevel4 '^#### .*$'
    syntax match cMarkdownLevel5 '^##### .*$'
    highlight def link cMarkdownLevel1 MarkdownLevelX
    highlight def link cMarkdownLevel2 MarkdownLevelX
    highlight def link cMarkdownLevel3 MarkdownLevelX
    highlight def link cMarkdownLevel4 MarkdownLevelX
    highlight def link cMarkdownLevel5 MarkdownLevelX
endfunction
augroup MarkdownSyntax
    autocmd!
    autocmd FileType markdown call s:EnhanceMarkdownSyntax()
augroup END

augroup YamlSyntax
    autocmd! BufNewFile,BufReadPost *.{yaml,yml} set filetype=yaml foldmethod=indent
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
    autocmd FileType js setlocal ts=2 sts=2 sw=2 expandtab
augroup END

highlight cQuickRunColor term=none ctermbg=blue gui=none guibg=dodgerblue4
function! s:EnhanceQuickRunSyntax()
    syntax match cQuickRunColor '^\[.*\] % .*$'
    syntax match cQuickRunColor '^Now\ Running\ ...$'
endfunction
augroup QuickRunSyntax
    autocmd!
    autocmd FileType quickrun call s:EnhanceQuickRunSyntax()
augroup END

"highlight SpellBad ctermfg=red guifg=gray10 guibg=gold2
"}}}


"{{{ color settings
hi StatuslineRed   cterm=none ctermfg=black ctermbg=red   gui=none guibg=red   guifg=#ffffff
hi StatuslineWhite cterm=none ctermfg=black ctermbg=white gui=bold guibg=white guifg=black

highlight StatusLine  cterm=none ctermbg=blue ctermfg=black  gui=bold guibg=dodgerblue3 guifg=black
augroup StatusColor
    au!
    au InsertEnter * highlight StatusLine  cterm=none ctermbg=red   ctermfg=black            guibg=red3        guifg=black
    au InsertLeave * highlight StatusLine  cterm=none ctermbg=blue  ctermfg=black   gui=bold guibg=dodgerblue3 guifg=black
augroup END

" CursorLine に ctermbg を設定していないのは意図どおり
"hi CursorLine guibg=#303030 ctermbg=black
hi CursorLine guibg=#303030 ctermbg=none

"highlight Normal     cterm=none ctermfg=white ctermbg=black gui=none guifg=#dddddd guibg=#111111
"highlight Normal     cterm=none ctermfg=white ctermbg=16 gui=none guifg=#dddddd guibg=#111111
highlight Normal     cterm=none ctermfg=white ctermbg=none gui=none guifg=#dddddd guibg=#111111
highlight SignColumn cterm=none ctermfg=white ctermbg=black gui=none guifg=#dddddd guibg=#111111
" highlight SignColumn cterm=none ctermfg=white ctermbg=16 gui=none guifg=#dddddd guibg=#111111

execute 'highlight Pmenu                  ' . ManualBgColor(200, 200, 200, 0)
execute 'highlight PmenuSel               ' . ManualBgColor(255, 171, 145, 0)
execute 'highlight PreProc term=underline ' . ManualFgColor(206, 147, 216, 0)


highlight link markdownError Normal
"}}}

"{{{ FileType
augroup FileTypeSettings
    autocmd!
    autocmd BufNewFile,BufRead *.{md,mdwn,mkd,mkdn,mark*} set filetype=markdown
    autocmd BufNewFile,BufRead *.tml set filetype=toml
augroup END
"}}}


""if exists('g:my_vimrc_neobundle_settings')
""    call NeoBundleColorSettings()
""endif


if has("gui_running")
    set guioptions+=a
    set guioptions-=T
    set guioptions-=r
    set guioptions-=e
    set guioptions-=m
    set guicursor=a:blinkon0
    if has('unix')
        set guifont=Ricty\ Discord\ 13
    endif
endif
set mouse=a

set nobackup
set noswapfile

if has('persistent_undo')
    let s:undo_dir = expand('~/.vim/temp/')
    if !isdirectory(s:undo_dir)
        call mkdir(s:undo_dir)
    endif
    execute "set undodir=" . s:undo_dir
    set undofile
endif

" 検索設定
set nowrapscan
set hlsearch
set incsearch
"set ignorecase " 大文字と小文字の違いを無視
"set smartcase  " 大文字を含む検索を行った場合には 大文字・小文字を区別する

set backspace=indent,eol,start

set notitle
set number
set wrap
set showmatch
set scrolloff=5
set cursorline
set nofoldenable

set smartindent
set listchars=
set nolist
set wildmode=longest,list,full

" 改行時に コメントが続くのを防止
augroup FormatOptions
    autocmd!
    autocmd Filetype * setlocal formatoptions-=ro
augroup END


set noerrorbells visualbell t_vb=
augroup NoVisualBell
    autocmd!
    autocmd GUIEnter * set visualbell t_vb=
augroup END
augroup Transparency
    autocmd!
    " (疑問) Kaoriya Vim だと transparency は 0-255 のようだが
    " Mac Vim は 255 まで設定値がないもよう... Help があればよいのだが...
    if has("win32")
        autocmd GUIEnter * set transparency=235
    else
        autocmd GUIEnter * set transparency=10
    endif
augroup END

set iminsert=0
set imsearch=-1

set history=1000
set undolevels=1000

"開いているファイルに変更があった場合に再ロードをかける設定
set autoread
" autoread (Vim Hack #206)
augroup vimrc-checktime
  autocmd!
  autocmd CursorHold,WinEnter,FocusGained * checktime
augroup END
"最終行まで収まらなくとも表示させる設定
set display=lastline

"{{{ mapping settings
noremap <expr> <C-b> max([winheight(0) - 2, 1]) . "\<C-u>" . (line('.') < 1         + winheight(0) ? 'H' : 'L')
noremap <expr> <C-f> max([winheight(0) - 2, 1]) . "\<C-d>" . (line('.') > line('$') - winheight(0) ? 'L' : 'H')


nnoremap Y y$
nnoremap <C-d> xa
inoremap <C-l> ^
inoremap <C-j> \
inoremap <C-d> <Del>

noremap  <C-e> <ESC>
inoremap <C-e> <Esc>
"NOTE: (CMD-LINE で ESC はキャンセルにならない. https://github.com/vim-jp/issues/issues/282
cnoremap <C-e> <C-c> 

inoremap <C-h> <BackSpace>
nnoremap + <C-a>
nnoremap - <C-x>

nmap <silent> <ESC><ESC> :nohlsearch<CR>

nnoremap <silent> ,w <ESC>:call ToggleWrap()<CR>

nnoremap ,,b :<C-u>bnext<CR>
nnoremap ,,B :<C-u>bprev<CR>

nnoremap ,,t :tabnew<CR>
nnoremap ,t :<C-u>tabnext<CR>
nnoremap ,T :<C-u>tabprev<CR>

" Y を D, C のような設定にする
nnoremap Y y$ 

" Vim Hack #62: カーソル下のキーワードをバッファ内全体で置換する 
"nnoremap <expr> s* ':s/\<' . expand('<cword>') . '\>/'
nnoremap <expr> s* ':%s/\<' . expand('<cword>') . '\>/'
vnoremap <expr> s* ':%s/\<'  . expand('<cword>') . '\>/'

vnoremap <expr> s^ ':s/^/'

" vim-users.jp Hack #104
vnoremap <silent> * "vy/\V<C-r>=substitute(escape(@v,'\/'),"\n",'\\n','g')<CR><CR> -a<CR>

nnoremap <silent> <S-Left>  :4wincmd <<CR>
nnoremap <silent> <S-Right> :4wincmd ><CR>
nnoremap <silent> <S-Up>    :wincmd -<CR>
nnoremap <silent> <S-Down>  :wincmd +<CR>

" Vim Hack 91
cnoremap <expr> /  getcmdtype() == '/' ? '\/' : '/'
cnoremap <expr> ?  getcmdtype() == '?' ? '\?' : '?'


""  + register ("+) : X11 clipboard               <--- set clipboard+=unnamedplus
""  * register ("*) : X11 primary (middle button) <--- set clipboard+=unnamed
"" (TODO: display above registers) : echo $+
nnoremap <A-c> "+y
inoremap <A-c> <ESC><ESC>"+y
nnoremap <A-v> "+gP
command! -nargs=0 Paste normal! "+gP


function! s:set_gdb_break()
    let l:str = 'break ' . expand('%:p') . ':' . line('.')
    let @+ = l:str
    let @* = l:str
    echo l:str
endfunction

function s:copy_path()
    let @*=expand('%:p')
    " copy unnamed register.
    let @"=expand('%:p')
endfunction

function s:copy_filename()
    let @*=expand('%:t')
    " copy unnamed register.
    let @"=expand('%:t')
endfunction

command! -nargs=0 CopyPath     call s:copy_path()
command! -nargs=0 CopyFileName call s:copy_filename()

command! -nargs=0 CopyBreak call s:set_gdb_break()
"command! GdbBreak :let @+ = 'b ' . expand('%:p') . ':' . line('.')

"}}}

" ref : http://pocke.hatenablog.com/entry/2014/10/26/145646
"if $TMUX == ''
if has("clipboard") && !exists('g:use_neovim')
    set clipboard^=autoselect
    set clipboard^=unnamedplus
    set clipboard^=unnamed
endif
"end

augroup MoveDir
    autocmd!
    autocmd BufEnter * silent! lcd %:p:h
augroup END
augroup MovePos
    autocmd!
    autocmd BufReadPost *
        \ if line("'\"") > 0 && line("'\"") <= line("$") |
        \   exe "normal g`\"" |
        \ endif
augroup END

"set splitbelow
"set splitright

"{{{ statusline settings
set statusline=%=
set statusline+=\|\ ASCII:0x%B\ 
set statusline+=\|\ %{&ff}\ 
set statusline+=\|\ %{&fenc!=''?&fenc:&enc}\ 
set statusline+=\|\ %Y\ 
set statusline+=\|\ LN\ %3p%%\ 

set statusline+=%#StatuslineRed#%m
set statusline+=%#StatuslineWhite#\ %t%h%w
if &readonly
    set statusline+=%#StatuslineRed#%t
endif
"}}}

"{{{ tab settings
set showtabline=2
set tabline=%!MakeTabLine()
"}}}



"{{{ window size settings
if has("gui_running")
    let g:save_window_file = expand('~/.vimwinpos')
    augroup SaveWindow
      autocmd!
      autocmd VimLeavePre * call s:save_window()
      function! s:save_window()
        let options = [
          \ 'set columns=' . &columns,
          \ 'set lines=' . &lines,
          \ 'winpos ' . getwinposx() . ' ' . getwinposy(),
          \ ]
        call writefile(options, g:save_window_file)
      endfunction
    augroup END

    if filereadable(g:save_window_file)
        execute 'source' g:save_window_file
    endif
endif
"}}}

"{{{ MyFunctions
function! ToggleWrap()
    if (&wrap == 1)
        setlocal nowrap
    else
        setlocal wrap
    endif
endfunction

function! MakeTabLine() "{{{
  let titles = map(range(1, tabpagenr('$')), 's:tabpage_label(v:val)')
  let sep = ' '
  let tabpages = join(titles, sep) . sep . '%#TabLineFill#%T'
  let info = '' 

  if exists('*FoldCCnavi')
    let info .= '%#TabLineInfo#'.substitute(FoldCCnavi()[-60:],'\s>\s','%#TabLineFill#> %#TabLineInfo#','g').'%0* '
  endif

  let info .= '%#TabPathColor#['.fnamemodify(getcwd(), ":~") . ']'

  return tabpages . '%=' . info 
endfunction "}}}


function! s:tabpage_label(tabpagenr)
  let title = gettabvar(a:tabpagenr, 'title')
  if title !=# ''
    return title
  endif

  let bufnrs = tabpagebuflist(a:tabpagenr)

  let hi = a:tabpagenr is tabpagenr() ? '%#TabLineSel#' : '%#TabLine#'

  let no = len(bufnrs)
  if no is 1
    let no = ''
  endif
  let mod = len(filter(copy(bufnrs), 'getbufvar(v:val, "&modified")')) ? '+' : ''
  let nomod = (no . mod) ==# '' ? '' : '['.no.mod.']'

  let curbufnr = bufnrs[tabpagewinnr(a:tabpagenr) - 1]
  let fname = fnamemodify(bufname(curbufnr), ':t')
  let fname = fname is '' ? '[No Name]' : fname

  return '%' . a:tabpagenr . 'T' . hi . " " . fname . " " . '%T%#TabLineFill#'
endfunction "}}}
"}}}

"{{{
" Usage : t1 : 1番目のタブへ t2 : 2番目のタブへ ....
for n in range(1, 9)
    execute 'nnoremap <silent> t' . n . ' :<C-u>tabnext' . n . '<CR>'
endfor
"}}}

" MEMO: write command result into vim buffer
"   :r! date
"   -->   2018年  1月  1日 月曜日 22:59:41 JST

function! s:Pulse()
    redir => old_hi
        silent execute 'hi CursorLine'
    redir END
    let old_hi = split(old_hi, '\n')[0]
    let old_hi = substitute(old_hi, 'xxx', '', '')

    let steps = 12
    let width = 1
    let start = width
    let end = steps * width
    let color = 233

    for i in range(start, end, width)
        execute "hi CursorLine ctermbg=" . (color + i)
        redraw
        sleep 5m
    endfor
    for i in range(end, start, -1 * width)
        execute "hi CursorLine ctermbg=" . (color + i)
        redraw
        sleep 5m
    endfor

    execute 'hi ' . old_hi
endfunction
command! -nargs=0 Pulse call s:Pulse()

if executable("git")

    " $ git add
    function! Gadd()
        !git add %
    endfunction
    command! Gadd call Gadd()

    " $ git push
    function! Gpush()
        !git push
    endfunction
    command! Gpush call Gpush()

endif


"{{{ CSV のハイライト設定

" csvファイルハイライト「:Csv [数値]」 と打つと、csvファイルで[数値]カラム目のハイライトをしてくれる
function! s:CSVH(x)
   execute 'match Keyword /^\([^,]*,\)\{'.a:x.'}\zs[^,]*/'
   execute 'normal ^'.a:x.'f,'
endfunction

" 「:Csvs」と打つと、現在のカラムをハイライトしてくれる
command! CsvHighlight :call s:CSVH(strlen(substitute(getline('.')[0:col('.')-1], "[^,]", "", "g")))

" Csv系のコマンドのハイライトを消す
command! CsvHighlightClear execute 'match none'

"}}}


function! s:EnhanceCrLf()
    " NOTE: dos になっているときにはこの設定は効かない
    "       unix のときに CRLF がでるということはおかしいことなので
    "       赤色に設定した
    highlight CrLf ctermfg=DarkRed guifg=DarkRed
    match CrLf /\r\n/
endfunction

augroup highlightCrLf
    autocmd!
    autocmd VimEnter,WinEnter,BufWinEnter,BufNew * call s:EnhanceCrLf()
augroup END

function! s:clang_format()
    let now_line = line(".")
    exec ':%!clang-format -style="{BasedOnStyle: Webkit, IndentWidth: 4, AlignOperands : true, AlwaysBreakTemplateDeclarations : true }"'
    exec ":" . now_line
endfunction

function! s:json_format()
    execute '%!python -m json.tool'
endfunction

function! s:vim_format()
    let view = winsaveview()
    normal gg=G
    silent call winrestview(view)
endfunction

function! s:format()
    if &filetype == "c" || &filetype == "cpp"
        if executable("clang-format")
            call s:clang_format()
            echomsg "clang-format done."
        else
            call s:vim_format()
            echomsg "Please Install clang-format"
        endif
    elseif &filetype == "json"
        call s:json_format()
        echomsg "json-format done."
    else
        call s:vim_format()
    endif
endfunction

command! Format call s:format()
command! JsonFormat call s:json_format()
command! ClangFormat call s:clang_format()

" Delete ANSI
"command! DeleteAnsi %s/<1b>\[[0-9;]*m//g
command! DeleteAnsi %s/\%x1B\[[0-9]\{1,3}[mK]//g


function! s:delete_trailing_white_space()
    " delete trailing white space
    silent! execute '%s/\v\s+$//'
    " delete the last empty lines
    while getline('$') == ""
        $delete _
    endwhile
endfunction

command! DeleteTrailingWhiteSpace call s:delete_trailing_white_space()

function! s:testClangCompletion()
    let l:line = line(".")
    let l:col = col(".")
    let l:src = join(getline(1, '$'), "\n") . "\n"
    " shorter version, without redirecting stdout and stderr
    let l:cmd = printf('%s -fsyntax-only -Xclang -code-completion-macros -Xclang -code-completion-at=-:%d:%d %s -',
                      \ "clang", l:line, l:col, "-x c++")
    echo system(l:cmd, l:src)
endfunction

command! TestClangCompletion call s:testClangCompletion()


function! PecoOpen()
  for filename in split(system("find . -type f | peco"), "\n")
    execute "e" filename
  endfor
endfunction
command! -nargs=0 PecoOpen call PecoOpen()

""augroup format
""autocmd!
""    if has("clang-format")
""        autocmd BufNewFile *.cpp command! -args=0 Format call s:clang_format()
""        autocmd BufNewFile *.c   command! -args=0 Format call s:clang_format()
""    endif
""augroup END


set completeopt-=noselect
set completeopt+=noinsert

" {{
function! s:FindGtagsDir()
    let curpath = getcwd()
    let findpath =findfile('GTAGS', curpath . ';')
    if findpath != ''
        " NOTE: findfile だけでは windows では 「C:」などが付かない
        "       絶対パスにならないので fnamemodify() で展開する.
        let findpath = fnamemodify(findpath , ':p:h')
    endif
    return findpath
endfunction

function! s:UpdateGtags(path)
    if executable("gtags")
        let ret = system("cd " . a:path . " && gtags " . a:path)
    else
        echoerr 'gtags : not installed'
    endif
endfunction

function! s:UpdateCtagsAndSetTags(path)
    if executable("ctags")
        let ctagsAbsPath = a:path . "\/tags"
        let ret = system("ctags -R -f" . ctagsAbsPath . " " . a:path)
        execute "set tags+=" . ctagsAbsPath
    else
        echoerr 'ctags : not installed'
    endif
endfunction

function! s:MakeTags(path)
    let choice = confirm("Make Gtags and Ctags ? : " . a:path, "&Yes\n&No")
    if choice == 1
        "TODO: 下の Running message を上書きする方法を調べる
        echo "Running..."
        " Gtags の Update 処理
        call s:UpdateGtags(a:path)
        " Ctags の Update 処理
        call s:UpdateCtagsAndSetTags(a:path)
        echomsg "FINISH : Make Tags. (" . a:path . ")"
    else
        echomsg "Canceled."
    endif
endfunction

function! s:UpdateTags()
    let myProjectPath = s:FindGtagsDir()
    if myProjectPath == ''
        echoerr "Cannot Find GTAGS Files."
        return
    endif

    call s:MakeTags(myProjectPath)
endfunction

command! -nargs=0 UpdateTags  call s:UpdateTags()
" }}

highlight DiffAdd    cterm=bold ctermfg=10 ctermbg=22
highlight DiffDelete cterm=bold ctermfg=10 ctermbg=52
highlight DiffChange cterm=bold ctermfg=10 ctermbg=17
highlight DiffText   cterm=bold ctermfg=10 ctermbg=21

augroup load_templates
autocmd!
    let s:load_templates_dir = s:script_path . '/template'
    let s:load_templates_command="0read ".s:load_templates_dir
    autocmd BufNewFile *.c execute s:load_templates_command ."/template.c"
    autocmd BufNewFile *.cpp execute s:load_templates_command ."/template.cpp"
    autocmd BufNewFile *.py execute s:load_templates_command ."/template.py"
    autocmd BufNewFile .gitignore execute s:load_templates_command ."/.gitignore"
    autocmd BufNewFile *.html execute s:load_templates_command ."/template.html"
augroup END

" How to Usage
" $ vim +'call ProfileCursorMove()' heavy_file.txt
" ----->  take a look at '~/.vim-profile.log'
function! ProfileCursorMove() abort
  let profile_file = expand('~/.vim-profile.log')
  if filereadable(profile_file)
    call delete(profile_file)
  endif

  normal! gg
  normal! zR

  execute 'profile start ' . profile_file
  profile func *
  profile file *

  augroup ProfileCursorMove
    autocmd!
    autocmd CursorHold <buffer> profile pause | q
  augroup END

  for i in range(100)
    call feedkeys('j')
  endfor
endfunction


"delcommand Gtabedit
"=========== TEST CODE ============================================

