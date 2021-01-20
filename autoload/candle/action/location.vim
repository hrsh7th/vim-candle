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
  \ }, {
  \   'name': 'preview',
  \   'accept': function('candle#action#location#accept_single'),
  \   'invoke': function('s:invoke_preview'),
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
  call a:candle.close()

  " Open item.
  let l:item = a:candle.get_action_items()[0]

  if bufnr('%') == bufnr(l:item.filename)
    let l:command = 'buffer'
  else
    let l:command = a:command
  endif

  execute printf('%s %s', l:command, l:item.filename)
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

"
" invoke_preview
"
function! s:invoke_preview(candle) abort
  let l:ctx = {}
  function! l:ctx.callback() abort closure
    let l:item = a:candle.get_cursor_item()
    if !empty(l:item)
      call a:candle.preview(l:item.filename, {
      \   'line': get(l:item, 'lnum', 1),
      \ })
    endif
  endfunction
  call candle#throttle('candle#action#location:invoke_preview', { -> l:ctx.callback() }, 200)
endfunction

