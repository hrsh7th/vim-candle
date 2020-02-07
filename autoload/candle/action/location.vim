"
" candle#action#location#get
"
" expected each items has below keys.
"
" - path (required)
" - lnum (optional)
" - col  (optional)
"
function! candle#action#location#get() abort
  return [{
  \   'name': 'edit',
  \   'accept': function('s:accept_open'),
  \   'invoke': function('s:invoke_open', ['edit']),
  \ }, {
  \   'name': 'split',
  \   'accept': function('s:accept_open'),
  \   'invoke': function('s:invoke_open', ['split']),
  \ }, {
  \   'name': 'vsplit',
  \   'accept': function('s:accept_open'),
  \   'invoke': function('s:invoke_open', ['vsplit']),
  \ }, {
  \   'name': 'delete',
  \   'accept': function('s:accept_delete'),
  \   'invoke': function('s:invoke_delete'),
  \ }]
endfunction

"
" accept_open
"
function! s:accept_open(candle) abort
  let l:items = a:candle.get_action_items()
  if len(l:items) != 1
    return v:false
  endif

  return has_key(l:items[0], 'path')
endfunction

"
" invoke_open
"
function! s:invoke_open(command, candle) abort
  " Close candle window.
  quit
  call win_gotoid(a:candle.prev_winid)

  " Open item.
  let l:item = a:candle.get_action_items()[0]
  execute printf('%s %s', a:command, l:item.path)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', col('.'))])
  endif
endfunction

"
" accept_delete
"
function! s:accept_delete(candle) abort
  for l:item in a:candle.get_action_items()
    if !has_key(l:item, 'path')
      return v:false
    endif
  endfor
  return v:true
endfunction

"
" invoke_delete
"
function! s:invoke_delete(candle) abort
  let l:items = a:candle.get_action_items()

  " Create confirm message.
  let l:msgs = ['Following files will be deleted.']
  for l:item in l:items
    let l:msgs += ['  ' . l:item.path]
  endfor

  " Confirm.
  if !candle#yesno(l:msgs)
    throw 'Cancel.'
  endif

  " Delete.
  for l:item in l:items
    call delete(l:item.path)
  endfor

  call a:candle.start()
endfunction

