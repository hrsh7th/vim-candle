"
" candle#action#location#get
"
" expected each items has below keys.
"
" - filename (required)
" - lnum (optional)
" - col  (optional)
" - text (optional)
"
function! candle#action#location#get() abort
  return [{
  \   'name': 'edit',
  \   'accept': function('candle#action#location#accept_single'),
  \   'invoke': function('s:invoke_open', ['edit']),
  \ }, {
  \   'name': 'split',
  \   'accept': function('candle#action#location#accept_single'),
  \   'invoke': function('s:invoke_open', ['split']),
  \ }, {
  \   'name': 'vsplit',
  \   'accept': function('candle#action#location#accept_single'),
  \   'invoke': function('s:invoke_open', ['vsplit']),
  \ }, {
  \   'name': 'delete',
  \   'accept': function('candle#action#location#accept_multiple'),
  \   'invoke': function('s:invoke_delete'),
  \ }]
endfunction

"
" candle#action#location#accept_single
"
function! candle#action#location#accept_single(candle) abort
  return candle#action#common#expect_keys_single(['filename'], a:candle)
endfunction

"
" candle#action#location#accept_multiple
"
function! candle#action#location#accept_multiple(candle) abort
  return candle#action#common#expect_keys_multiple(['filename'], a:candle)
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
  execute printf('%s %s', a:command, l:item.filename)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', col('.'))])
  endif
endfunction

"
" invoke_delete
"
function! s:invoke_delete(candle) abort
  let l:items = a:candle.get_action_items()

  " Create confirm message.
  let l:msgs = ['Following files will be deleted.']
  for l:item in l:items
    let l:msgs += ['  ' . l:item.filename]
  endfor

  " Confirm.
  if !candle#yesno(l:msgs)
    throw 'Cancel.'
  endif

  " Delete.
  for l:item in l:items
    call delete(l:item.filename)
  endfor

  call a:candle.start()
endfunction

