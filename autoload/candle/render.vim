let s:Promise = vital#candle#import('Async.Promise')

let s:tick = 200

call sign_define('CandleCursor', {
      \   'text': '>',
      \   'linehl': 'CursorLine'
      \ })

call sign_define('CandleSelect', {
      \   'text': '*'
      \ })

"
" candle#render#start
"
function! candle#render#start(context) abort
  let l:candle = a:context
  let l:candle.winid = -1
  let l:candle.prev_winid = win_getid()
  let l:candle.items = []
  let l:candle.total = 0
  let l:candle.state = {}
  let l:candle.state.query = ''
  let l:candle.state.index = 0
  let l:candle.state.cursor = 1
  let l:candle.state.selects = []
  let l:candle.prev_state = {}
  let l:candle.prev_state.query = ''
  let l:candle.prev_state.index = -1
  let l:candle.prev_state.cursor = -1
  let l:candle.prev_state.selects = []

  call candle#render#window#open(l:candle)
  call candle#render#buffer#initialize(l:candle)
  call candle#render#mapping#initialize(l:candle)
  call candle#render#autocmd#initialize(l:candle)
  let b:candle = l:candle
  doautocmd User candle#render#start

  " start
  call b:candle.source.start({ notification ->
        \   candle#render#on_notification(l:candle.bufname, notification)
        \ })

  sleep 50m
endfunction

"
" candle#render#on_notification
"
function! candle#render#on_notification(bufname, notification) abort
  let l:candle = getbufvar(a:bufname, 'candle')
  if a:notification.method ==# 'progress'
    let l:candle.total = a:notification.params.total
  elseif a:notification.method ==# 'done'
    let l:candle.total = a:notification.params.total
  endif
  call candle#render#refresh({
        \   'bufname': a:bufname,
        \   'sync': v:false,
        \   'notification': a:notification
        \ })
endfunction

"
" refresh
"
function! candle#render#refresh(option) abort
  try
    let l:candle = getbufvar(a:option.bufname, 'candle')
    call s:update_cursor(l:candle, a:option)
    call s:update_selects(l:candle, a:option)
    call s:update_window(l:candle, a:option)
    call s:update_items(l:candle, a:option)
    let l:candle.prev_state = copy(l:candle.state)
  catch /.*/
    call candle#echo({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" update_cursor
"
function! s:update_cursor(candle, option) abort
  if a:candle.state.cursor == a:candle.prev_state.cursor
    call candle#log('[SKIP]', 's:update_selects')
    return
  endif

  call sign_unplace('CandleCursor', { 'buffer': a:candle.bufname })
  call sign_place(1, 'CandleCursor', 'CandleCursor', a:candle.bufname, {
        \   'priority': 100,
        \   'lnum': a:candle.state.cursor
        \ })
  if bufname('%') == a:candle.bufname
    call cursor([a:candle.state.cursor, col('.')])
  endif
endfunction

"
" update_selects
"
function! s:update_selects(candle, option) abort
  if a:candle.state.selects == a:candle.prev_state.selects
    call candle#log('[SKIP]', 's:update_selects')
    return
  endif

  call sign_unplace('CandleSelect', { 'buffer': a:candle.bufname })
  for l:select in a:candle.state.selects
    call sign_place(0, 'CandleSelect', 'CandleSelect', a:candle.bufname, {
          \   'priority': 200,
          \   'lnum': index(map(copy(a:candle.items), 'v:val.id'), l:select) + 1
          \ })
  endfor
endfunction

"
" update_window
"
function! s:update_window(candle, option) abort
  let l:winnr = bufwinnr(a:candle.bufname)
  call candle#render#window#resize(
        \   a:candle.bufname,
        \   winwidth(l:winnr),
        \   len(a:candle.items)
        \ )
endfunction

"
" update_items
"
function! s:update_items(candle, option) abort
  if v:true
        \ && a:candle.state.query ==# a:candle.prev_state.query
        \ && a:candle.state.index ==# a:candle.prev_state.index
        \ && !has_key(a:option, 'notification')
    call candle#log('[SKIP]', 's:update_items')
    return
  endif

  " fetch
  let l:p = a:candle.source.fetch({
        \   'query': a:candle.state.query,
        \   'index': a:candle.state.index,
        \   'count': a:candle.maxheight,
        \ }).then({ response ->
        \   s:on_response(a:option.bufname, response)
        \ })

  " sync.
  if get(a:option, 'sync', v:false)
    try
      call candle#sync(l:p)
    catch /.*/
      call candle#echo({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endif
endfunction

"
" on_response
"
function! s:on_response(bufname, response) abort
  let l:candle = getbufvar(a:bufname, 'candle')
  let l:candle.total = a:response.total
  let l:candle.items = a:response.items

  call setbufline(a:bufname, 1, map(copy(l:candle.items), { _, item -> item.title }))
  call deletebufline(a:bufname, len(l:candle.items) + 1, '$')

  let l:winnr = bufwinnr(l:candle.bufname)
  call candle#render#window#resize(
        \   l:candle.bufname,
        \   winwidth(l:winnr),
        \   min([l:candle.maxheight, len(l:candle.items)])
        \ )
endfunction

