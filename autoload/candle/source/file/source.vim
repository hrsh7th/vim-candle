let s:dirname = expand('<sfile>:p:h')

"
" candle#source#file#source#definition
"
function! candle#source#file#source#definition() abort
  return {
        \   'name': 'file',
        \   'create': function('s:create', ['file'])
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
  \       'sort_by': get(a:args, 'sort_by', ''),
  \       'ignore_patterns': get(a:args, 'ignore_patterns', []),
  \     }
  \   },
  \   'action': {
  \     'default': 'edit'
  \   }
  \ }
endfunction

