let s:dirname = expand('<sfile>:p:h')

"
" candle#source#grep#source#definition
"
function! candle#source#grep#source#definition() abort
  return {
        \   'name': 'grep',
        \   'create': function('s:create', ['grep'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  if strlen(a:args.pattern) == 0
    throw '[grep] `pattern` is required.'
  endif

  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'root_path': get(a:args, 'root_path', getcwd()),
  \       'pattern': get(a:args, 'pattern', ''),
  \     }
  \   },
  \   'actions': s:actions()
  \ }
endfunction

"
" actions
"
function! s:actions() abort
  let l:actions = {}
  let l:actions = extend(l:actions, candle#action#location#get())
  let l:actions.default = l:actions.edit
  return l:actions
endfunction

