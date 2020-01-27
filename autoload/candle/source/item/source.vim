let s:dirname = expand('<sfile>:p:h')

"
" candle#source#item#source#definition
"
function! candle#source#item#source#definition() abort
  return {
        \   'name': 'item',
        \   'script': s:dirname . '/source.go',
        \   'get_actions': { -> s:get_actions() }
        \ }
endfunction

"
" get_actions
"
function! s:get_actions() abort
  return {}
endfunction

