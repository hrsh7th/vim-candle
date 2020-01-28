"
" candle#action#location#get
"
function! candle#action#location#get() abort
  return {
  \   'edit': function('s:edit'),
  \   'split': function('s:split'),
  \   'vsplit': function('s:vsplit'),
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
" open
"
function! s:open(candle, command) abort
  let l:item = a:candle.get_cursor_item()
  if empty(l:item)
    echomsg 'cursor item can''t detected'
    return
  endif

  call win_gotoid(a:candle.state.prev_winid)
  execute printf('%s %s', a:command, l:item.path)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', col('.'))])
  endif

  return {
  \   'quit': v:true
  \ }
endfunction


