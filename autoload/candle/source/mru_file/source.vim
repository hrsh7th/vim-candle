let s:dirname = expand('<sfile>:p:h')

"
" candle#source#mru_file#source#definition
"
function! candle#source#mru_file#source#definition() abort
  return {
        \   'name': 'mru_file',
        \   'script': s:dirname . '/source.go',
        \   'get_options': { -> s:get_options() }
        \ }
endfunction

"
" get_options
"
function! s:get_options() abort
  return [{
        \   'name': '--filepaths',
        \   'description': '',
        \   'extra': {
        \     'default': v:oldfiles
        \   }
        \ }]
endfunction

