" =============================================================================
" Plugin Settings
" =============================================================================

"{{{ 外部ファイル変更検知（nvim専用）
set updatetime=500
augroup nvim-checktime-extra
  autocmd!
  autocmd BufEnter * checktime
augroup END
"}}}

"{{{ QuickFix navigation (nvim専用)
" Ctrl-j/k でQuickFixのエントリ間を移動
nnoremap <silent> <C-j> :cnext<CR>
nnoremap <silent> <C-k> :cprevious<CR>
"}}}

"{{{ quickhl
nmap ,m <Plug>(quickhl-manual-this)
xmap ,m <Plug>(quickhl-manual-this)
nmap ,M <Plug>(quickhl-manual-reset)
xmap ,M <Plug>(quickhl-manual-reset)

function! s:add_quickhl_manual_color(r, g, b, isFgWhite)
    call add(g:quickhl_manual_colors, ManualBgColor(a:r, a:g, a:b, a:isFgWhite))
endfunction

let g:quickhl_manual_colors = []
call s:add_quickhl_manual_color(233,  30,  99, 1)
call s:add_quickhl_manual_color(255,  86,  34, 1)
call s:add_quickhl_manual_color(156,  39, 176, 1)
call s:add_quickhl_manual_color(  0, 137, 123, 1)
call s:add_quickhl_manual_color( 84, 139,  47, 1)
call s:add_quickhl_manual_color(  0, 188, 212, 0)
call s:add_quickhl_manual_color( 63,  81, 181, 0)
call s:add_quickhl_manual_color(139, 195,  74, 0)
call s:add_quickhl_manual_color(194,  24,  91, 0)
call s:add_quickhl_manual_color(240,  98, 146, 0)
call s:add_quickhl_manual_color(251, 192,  45, 0)
call s:add_quickhl_manual_color(205, 220,  73, 1)
call s:add_quickhl_manual_color(103,  58, 183, 1)
call s:add_quickhl_manual_color( 33, 150, 243, 1)
call s:add_quickhl_manual_color( 48,  63, 159, 1)
call s:add_quickhl_manual_color( 76, 175,  80, 1)
call s:add_quickhl_manual_color(  0, 169, 244, 0)
call s:add_quickhl_manual_color(255, 235,  59, 0)
call s:add_quickhl_manual_color(230,  74,  25, 1)
call s:add_quickhl_manual_color(255, 238,  88, 0)
"}}}

"{{{ lightline
let g:lightline = {
            \ 'colorscheme': 'my_wombat',
            \ 'active': {
            \   'left' : [ [ 'mode', 'paste' ], [ 'filename', 'fugitive', 'modified', 'readonly' ] ],
            \   'right': [
            \         ['lineinfo'],
            \         [ 'mycharvaluehex', 'lspCondCheck', 'percent', 'filetype', 'myfileformat', 'myfileencoding', 'lspCondCheck' ] ],
            \ },
            \ 'inactive': {
            \   'left' : [ [ 'fullpath'] ],
            \   'right': [ [ ] ],
            \ },
            \ 'component': {
            \   'mycharvaluehex': '0x%B',
            \   'modified': '%#ModifiedColor#%{MyModified()}',
            \   'readonly': '%#ROColor#%{MyReadonly()}',
            \   'pwd'     : '%#Normal#%{MyPwd()}',
            \   'fullpath'  : '%F',
            \   'myfileencoding'  : '%#FileEncodingColor#%{MyFileEncoding()}',
            \   'myfileformat'    : '%#FileFormatColor#%{MyFileFormat()}',
            \   'lspCondCheck'    : '%{LspCondCheck()}',
            \ },
            \ 'component_function': {
            \   'fugitive' : 'MyFugitive',
            \ },
            \ 'separator': { 'left': '', 'right': '' },
            \ 'subseparator': { 'left': '', 'right': '' },
            \ 'tabline_separator': { 'left': "", 'right': "" },
            \ 'tabline_subseparator': { 'left': "", 'right': "" },
            \ 'tabline' :  { 'right': [ ['pwd'] ] },
            \ 'tab'     : {
            \   'active': [ 'tabnum', 'filename' ],
            \   'inactive': [ 'tabnum', 'filename' ],
            \ },
            \ }

function! MyFugitive()
    try
        if &ft !~? 'vimfiler\|gundo' && exists('*fugitive#head') && strlen(fugitive#head())
            return ' ' . fugitive#head()
        endif
    catch
    endtry
    return ''
endfunction

function! MyFileFormat()
    if &ff == 'unix'
        call SetManualBgColor("FileFormatColor", 121, 134, 202, 0)
        return ' LF (unix)'
    elseif &ff == 'dos'
        call SetManualBgColor("FileFormatColor", 205, 220, 57, 0)
        return ' CRLF (win)'
    elseif &ff == 'mac'
        call SetManualBgColor("FileFormatColor", 255, 0, 0, 0)
        return ' CR'
    else
        call SetManualBgColor("FileFormatColor", 255, 0, 0, 0)
        return ' ?'
    endif
endfunction

function! LspCondCheck()
    let error_msg = " LSP not running"
    if &filetype == "typescriptreact"
        if executable("typescript-language-server")
            return ""
        elseif executable("npm")
            return " npm not executable..."
        else
            return $error_msg
        endif
    elseif &filetype == "go"
        if executable("gopls")
            return ""
        else
            return $error_msg
        endif
    else
        return ""
    endif
endfunction

function! MyFileEncoding()
    if &fenc == "utf-8"
        call SetManualBgColor("FileEncodingColor", 121, 134, 202, 0)
    elseif &fenc == 'ascii'
        call SetManualBgColor("FileEncodingColor", 121, 134, 202, 0)
    elseif &fenc == 'cp932'
        call SetManualBgColor("FileEncodingColor", 205, 220, 57, 0)
    elseif &fenc == ''
        call SetManualBgColor("FileEncodingColor", 245, 245, 245, 0)
        return ' -'
    else
        call SetManualBgColor("FileEncodingColor", 255, 0, 0, 0)
    endif
    return ' ' . &fenc
endfunction

function! MyModified()
    if &modified
        execute 'hi ModifiedColor ctermbg=darkred guibg=#ff0000 term=bold cterm=bold'
        return ' +'
    else
        if &modifiable
            execute 'hi ModifiedColor ctermbg=238 guibg=#444444'
            return '  '
        else
            execute 'hi ModifiedColor ctermbg=darkred guibg=#ff0000 term=bold cterm=bold'
            return ' -'
        endif
    endif
endfunction

function! MyReadonly()
    execute 'hi ROColor ctermfg=196 ctermbg=238 guifg=#ff0000 guibg=#444444 term=bold cterm=bold'
    return ' ' . (&ft !~? 'help' && &readonly ? 'RO' : '')
endfunction

function! MyPwd()
    return " " . fnamemodify(getcwd(), ":~")
endfunction

let s:base03 = [ '#242424', 235 ]
let s:base023 = [ '#353535 ', 236 ]
let s:base02 = [ '#444444 ', 238 ]
let s:base01 = [ '#585858', 240 ]
let s:base00 = [ '#666666', 242  ]
let s:base0 = [ '#808080', 244 ]
let s:base1 = [ '#969696', 247 ]
let s:base2 = [ '#a8a8a8', 248 ]
let s:base3 = [ '#d0d0d0', 252 ]
let s:black = [ '#000000', 0 ]
let s:yellow = [ '#cae682', 180 ]
let s:orange = [ '#e5786d', 173 ]
let s:red = [ '#e5786d', 203 ]
let s:magenta = [ '#f2c68a', 216 ]
let s:blue = [ '#8ac6f2', 117 ]
let s:dodgerblue = [ '#1e90ff', 27 ]
let s:cyan = s:blue
let s:green = [ '#95e454', 119 ]
let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}
let s:p.normal.left = [ [ s:base02, s:blue ], [ s:base3, s:base01 ] ]
let s:p.normal.right = [ [ s:base3, s:base01], [ s:base3, s:base01 ] ]
let s:p.inactive.left =  [ [ s:base1, s:base02 ], [ s:base00, s:base023 ] ]
let s:p.inactive.right = [ [ s:base023, s:base01 ], [ s:base00, s:base02 ] ]
let s:p.insert.left = [ [ s:base02, s:green ], [ s:base3, s:base01 ] ]
let s:p.replace.left = [ [ s:base023, s:red ], [ s:base3, s:base01 ] ]
let s:p.visual.left = [ [ s:base02, s:magenta ], [ s:base3, s:base01 ] ]
let s:p.normal.middle = [ [ s:base2, s:base02 ] ]
let s:p.inactive.middle = [ [ s:base1, s:base023 ] ]
let s:p.tabline.left = [ [ s:base3, s:base00 ] ]
let s:p.tabline.tabsel = [ [ s:base3, s:dodgerblue ] ]
let s:p.tabline.middle = [ [ s:base02, s:base1 ] ]
let s:p.tabline.right = [ [ s:base2, s:base01 ] ]
let s:p.normal.error = [ [ s:base03, s:red ] ]
let s:p.normal.warning = [ [ s:base023, s:yellow ] ]

let g:lightline#colorscheme#my_wombat#palette = lightline#colorscheme#flatten(s:p)
"}}}

"{{{ ag.vim
let g:ag_mapping_message = 0
let g:ag_apply_qmappings = 0

function! s:AG()
    let here = expand('<sfile>:p:h')
    let cmd = input(printf(":Ag %s [%s]", expand("<cword>"), here))
    execute cmd
endfunction

command! -nargs=0 AG call s:AG()
"}}}

"{{{ oil.nvim
nnoremap <silent> ,vv <cmd>lua require('oil').open(); vim.defer_fn(function() require('oil').open_preview({ horizontal = true }) end, 100)<CR>
"}}}

"{{{ obsidian.nvim
nnoremap <silent> ,uh :<C-u>ObsidianTodayWithTemplate<CR>
"}}}

" =============================================================================
" Colorscheme & Highlight Settings
" =============================================================================

"{{{ dante.vim
syntax on
set laststatus=2
set t_Co=256
set background=dark
colorscheme dante

" nvim のデフォルトハイライトを dante.vim のリンクで上書き
hi clear String
hi clear Character
hi clear Number
hi clear Boolean
hi! link String Constant
hi! link Character Constant
hi! link Number Constant
hi! link Boolean Constant
"}}}

"{{{ Color Overrides (colorscheme の後に上書き)
" Function
call SetManualFgColor("Function",  33, 150, 243, 0)
call SetManualBgColor("ALEError",  255, 193,   7, 0)

" LSP
highlight LspErrorHighlight term=underline cterm=underline gui=underline
highlight LspWarningHighlight term=underline cterm=underline gui=underline

" Go syntax
hi def link goFunctionCall Function
hi def link goMethodCall   Function
function! s:EnhanceGoSyntax()
    hi GoError term=none cterm=bold ctermfg=214 gui=none guifg=gold3
    match goError /\<err\>/
endfunction
augroup GoSyntax
    autocmd!
    autocmd FileType go call s:EnhanceGoSyntax()
augroup END

" C++ syntax
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

" Markdown syntax
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

" StatusLine
hi StatuslineRed   cterm=none ctermfg=black ctermbg=red   gui=none guibg=red   guifg=#ffffff
hi StatuslineWhite cterm=none ctermfg=black ctermbg=white gui=bold guibg=white guifg=black
highlight StatusLine  cterm=none ctermbg=blue ctermfg=black  gui=bold guibg=dodgerblue3 guifg=black
augroup StatusColor
    au!
    au InsertEnter * highlight StatusLine  cterm=none ctermbg=red   ctermfg=black            guibg=red3        guifg=black
    au InsertLeave * highlight StatusLine  cterm=none ctermbg=blue  ctermfg=black   gui=bold guibg=dodgerblue3 guifg=black
augroup END

" CursorLine
hi CursorLine guibg=#303030 ctermbg=none

" Normal, SignColumn
highlight Normal     cterm=none ctermfg=white ctermbg=none gui=none guifg=#dddddd guibg=#111111
highlight SignColumn cterm=none ctermfg=white ctermbg=black gui=none guifg=#dddddd guibg=#111111

" Pmenu
execute 'highlight Pmenu                  ' . ManualBgColor(200, 200, 200, 0)
execute 'highlight PmenuSel               ' . ManualBgColor(255, 171, 145, 0)
execute 'highlight PreProc term=underline ' . ManualFgColor(206, 147, 216, 0)

" markdownError
highlight link markdownError Normal

" Diff
highlight DiffAdd    cterm=bold ctermfg=10 ctermbg=22
highlight DiffDelete cterm=bold ctermfg=10 ctermbg=52
highlight DiffChange cterm=bold ctermfg=10 ctermbg=17
highlight DiffText   cterm=bold ctermfg=10 ctermbg=21
"}}}
