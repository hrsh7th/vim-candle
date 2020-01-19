let s:Promise = vital#candle#import('Async.Promise')

let s:tick = 200

call sign_define('CandleCursor', {
      \   'text': '>'
      \ })

call sign_define('CandleSelect', {
      \   'text': '*'
      \ })

"
" candle#render#start
"
function! candle#render#start(context) abort
  " init buffer (window#open must be first call)
  call candle#render#window#open(a:context)

  " init context
  let b:candle = a:context
  let b:candle.items = []
  let b:candle.total = 0
  let b:candle.state = {}
  let b:candle.state.query = ''
  let b:candle.state.index = 0
  let b:candle.state.cursor = 1
  let b:candle.state.selects = []
  let b:candle.prev_state = {}
  let b:candle.prev_state.query = ''
  let b:candle.prev_state.index = -1
  let b:candle.prev_state.cursor = -1
  let b:candle.prev_state.selects = []

  " init buffer.
  call candle#render#buffer#initialize(a:context)
  call candle#render#mapping#initialize(a:context)
  call candle#render#autocmd#initialize(a:context)

  " start
  call b:candle.source.start({ notification ->
        \   candle#render#on_notification(a:context.bufname, notification)
        \ })

  " refresh
  call candle#render#refresh({
        \   'bufname': a:context.bufname,
        \   'sync': v:true
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
    call s:update_items(l:candle, a:option)
    let l:candle.prev_state = copy(l:candle.state)
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
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
    echomsg printf('[CANDLE] process done. (total: %s)', l:candle.total)
  endif
  call candle#render#refresh({
        \   'bufname': a:bufname,
        \   'sync': v:false,
        \   'notification': a:notification
        \ })
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
  call sign_place(0, 'CandleCursor', 'CandleCursor', a:candle.bufname, {
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
" update_items
"
function! s:update_items(candle, option) abort
  if v:true
        \ && a:candle.state.query ==# a:candle.prev_state.query
        \ && a:candle.state.index ==# a:candle.prev_state.index
        \ && !has_key(a:option, 'notification')
        \ && !has_key(a:option, 'force')
    call candle#log('[SKIP]', 's:update_items')
    return
  endif

  " fetch
  let l:p = a:candle.source.fetch({
        \   'query': a:candle.state.query,
        \   'index': a:candle.state.index,
        \   'count': a:candle.winheight,
        \ }).then({ response ->
        \   s:on_response(a:option.bufname, response)
        \ })

  " sync.
  if get(a:option, 'sync', v:false)
    call candle#sync(l:p)
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
        \   min([l:candle.winheight, l:candle.total])
        \ )
endfunction

