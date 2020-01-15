if exists('g:loaded_candle')
  finish
endif
let g:loaded_candle = v:true

let s:root = expand('<sfile>:p:h:h')

"
" command
"
command! -nargs=* -complete=customlist,s:complete Candle call s:command('<args>')
function! s:command(args) abort
  call candle#start({
        \   'script': s:root . '/source/grep.tengo',
        \   'params': {
        \     'cwd': s:root,
        \   }
        \ })
endfunction

"
" complete
"
function! s:complete(lead, len, pos) abort
endfunction

