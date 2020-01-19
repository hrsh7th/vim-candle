let s:dirname = expand('<sfile>:p:h')

"
" candle#source#grep#source#definition
"
function! candle#source#grep#source#definition() abort
  return {
        \   'name': 'grep',
        \   'script': s:dirname . '/source.go',
        \   'get_options': { -> s:get_options() }
        \ }
endfunction

"
" get_options
"
function! s:get_options() abort
  return [{
        \   'name': '--pattern=VALUE',
        \   'description': 'Specify grep pattern.',
        \   'extra': {
        \     'required': 0
        \   }
        \ }, {
        \   'name': '--cwd=VALUE',
        \   'description': 'Specify grep cwd.',
        \   'extra': {
        \     'default': getcwd(),
        \   }
        \ }]
endfunction

