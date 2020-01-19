let s:dirname = expand('<sfile>:p:h')

"
" candle#source#item#source#definition
"
function! candle#source#item#source#definition() abort
  return {
        \   'name': 'item',
        \   'script': s:dirname . '/source.go',
        \   'get_options': { -> s:get_options() }
        \ }
endfunction

"
" get_options
"
function! s:get_options() abort
  return []
endfunction

