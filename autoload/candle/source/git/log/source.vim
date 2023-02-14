let s:dirname = expand('<sfile>:p:h')

"
" candle#source#git#log#source#definition
"
function! candle#source#git#log#source#definition() abort
  return {
        \   'name': 'git/log',
        \   'create': function('s:create', ['git/log'])
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
  \     'reset --hard': function('s:action_reset_hard'),
  \     'reset --soft': function('s:action_reset_soft'),
  \   }
  \ }
endfunction

function! s:action_reset_hard(candle) abort
  let l:items = a:candle.get_action_items()
  if len(l:items) != 1
    echomsg 'the action must be called with only one item'
    return
  endif
  call candle#source#git#run(a:candle, 'reset', ['--hard', l:items[0].commit_hash])
  call a:candle.start()
endfunction

function! s:action_reset_soft(candle) abort
  let l:items = a:candle.get_action_items()
  if len(l:items) != 1
    echomsg 'the action must be called with only one item'
    return
  endif
  call candle#source#git#run(a:candle, 'reset', ['--soft', l:items[0].commit_hash])
  call a:candle.start()
endfunction
