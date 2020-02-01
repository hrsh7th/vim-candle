let s:dirname = expand('<sfile>:p:h')

"
" candle#source#files#source#definition
"
function! candle#source#files#source#definition() abort
  return {
        \   'name': 'files',
        \   'create': function('s:create', ['files'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'root_path': get(a:args, 'root_path', getcwd()),
  \       'ignore_patterns': get(a:args, 'ignore_patterns', []),
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

