"
" candle#action#location#get
"
function! candle#action#location#get() abort
  return {
  \   'edit': function('s:edit'),
  \   'split': function('s:split'),
  \   'vsplit': function('s:vsplit'),
  \   'delete': function('s:delete'),
  \ }
endfunction

"
" edit
"
function! s:edit(candle) abort
  return s:open(a:candle, 'edit')
endfunction

"
" split
"
function! s:split(candle) abort
  return s:open(a:candle, 'split')
endfunction

"
" vsplit
"
function! s:vsplit(candle) abort
  return s:open(a:candle, 'vsplit')
endfunction

"
" delete
"
function! s:delete(candle) abort
  let l:items = a:candle.get_action_items()
  if empty(l:items)
    throw 'Delete target is empty.'
  endif

  let l:msgs = ['Following files will be deleted.']
  for l:item in l:items
    let l:msgs += ['  ' . l:item.path]
  endfor

  if candle#yesno(l:msgs)
    for l:item in l:items
      call delete(l:item.path)
    endfor
    call a:candle.start()
  else
    throw 'Cancel.'
  endif
endfunction

"
" open
"
function! s:open(candle, command) abort
  let l:item = get(a:candle.get_action_items(), 0, {})
  if empty(l:item)
    echomsg 'cursor item can''t detected'
    return
  endif

  quit

  call win_gotoid(a:candle.state.prev_winid)
  execute printf('%s %s', a:command, l:item.path)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', col('.'))])
  endif
endfunction

