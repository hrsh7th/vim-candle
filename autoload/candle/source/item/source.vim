let s:dirname = expand('<sfile>:p:h')

"
" candle#source#item#source#definition
"
function! candle#source#item#source#definition() abort
  return {
        \   'name': 'item',
        \   'create': function('s:create', ['item'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  if len(a:args) == 0
    throw '[items] items is required.'
  endif

  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'items': a:args,
  \     }
  \   },
  \ }
endfunction

