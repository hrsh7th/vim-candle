let s:dirname = expand('<sfile>:p:h')

"
" candle#source#items#source#definition
"
function! candle#source#items#source#definition() abort
  return {
        \   'name': 'items',
        \   'create': function('s:create', ['items'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  if len(a:args.items) == 0
    throw '[items] `items` is required.'
  endif
  if len(keys(a:args.actions)) == 0
    throw '[items] `actions` is required.'
  endif

  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'items': a:args.items,
  \     }
  \   },
  \   'actions': a:args.actions
  \ }
endfunction

