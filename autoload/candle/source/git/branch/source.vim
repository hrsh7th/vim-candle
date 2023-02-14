let s:dirname = expand('<sfile>:p:h')

"
" candle#source#git#branch#source#definition
"
function! candle#source#git#branch#source#definition() abort
  return {
        \   'name': 'git/branch',
        \   'create': function('s:create', ['git/branch'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  let l:working_dir = get(a:args, 'working_dir', getcwd())
  if l:working_dir ==# ''
    echoerr 'does not detect working dir'
  endif

  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'working_dir': get(a:args, 'working_dir', getcwd()),
  \     }
  \   },
  \   'action': {
  \     'default': function('s:action_switch')
  \   }
  \ }
endfunction

function! s:action_switch(candle) abort
  let l:items = a:candle.get_action_items()
  echomsg string(l:items)
  if len(l:items) != 1
    echomsg 'reset action must be called with only one item'
    return
  endif
  call candle#source#git#run(a:candle, 'switch', [l:items[0].name])
  call a:candle.start()
endfunction
