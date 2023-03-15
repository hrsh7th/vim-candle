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
  \     'default': function('s:action_switch'),
  \     'delete': function('s:action_delete'),
  \     'new': function('s:action_new'),
  \   }
  \ }
endfunction

function! s:action_new(candle) abort
  let l:items = a:candle.get_selected_items()
  if len(l:items) != 0
    echomsg 'the action must be called without items'
    return
  endif
  call candle#source#git#run(a:candle, 'branch', [input('branch: ')])
  call a:candle.start()
endfunction

function! s:action_switch(candle) abort
  let l:items = a:candle.get_action_items()
  if len(l:items) != 1
    echomsg 'the action must be called with only one item'
    return
  endif
  let l:item = l:items[0]
  if !l:item.local
    let l:local_names = map(filter(copy(a:candle.get_items()), 'v:val.local'), 'v:val.name')
    if index(l:local_names, l:item.name) != -1
      call candle#source#git#run(a:candle, 'switch', [l:item.name .. '_' .. l:item.origin, l:item.name])
    else
      call candle#source#git#run(a:candle, 'switch', [l:item.name])
    endif
  else
    call candle#source#git#run(a:candle, 'switch', [l:items[0].name])
  endif
  call a:candle.start()
endfunction

function! s:action_delete(candle) abort
  for l:item in a:candle.get_action_items()
    if l:item.local
      if candle#misc#yesno('delete local branch `' .. l:item.name .. '`')
        call candle#source#git#run(a:candle, 'branch', ['-d', l:item.name])
      endif
    endif
    if l:item.upstream !=# ''
      if candle#misc#yesno('delete remove branch `' .. l:item.refname .. '`')
        call candle#source#git#run(a:candle, 'push', ['--delete', l:item.origin, l:item.name])
      endif
    endif
  endfor
  call a:candle.start()
endfunction

