let s:state = {
\   'item_count': -1
\ }

"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  doautocmd User candle#input#start

  let s:state.item_count = len(a:candle.state.items)

  redrawstatus
  try
    let l:timer_id = timer_start(16, { timer_id -> s:on_query_change(timer_id) }, { 'repeat': -1 })
    call input('$ ', a:candle.state.query)
  finally
    call timer_stop(l:timer_id)
  endtry
endfunction

"
" s:on_query_change
"
function! s:on_query_change(timer_id) abort
  if empty(getbufvar('%', 'candle', {}))
    call timer_stop(a:timer_id)
    return
  endif

  if b:candle.state.query !=# getcmdline()
    call b:candle.top()
    call b:candle.query(getcmdline())
    redrawstatus
  elseif s:state.item_count != len(b:candle.state.items)
    redrawstatus
  endif

  let s:state.item_count = len(b:candle.state.items)
endfunction

