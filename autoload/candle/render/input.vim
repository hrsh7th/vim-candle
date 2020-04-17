let s:state = {
\   'running': v:false,
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
    call timer_start(16, { -> s:on_query_change() })
    let s:state.running = v:true
    call input('$ ', a:candle.state.query)
  finally
    let s:state.running = v:false
  endtry

endfunction

"
" s:on_query_change
"
function! s:on_query_change() abort
  if empty(getbufvar('%', 'candle', {})) || !s:state.running
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

  if s:state.running
    call timer_start(16, { -> s:on_query_change() })
  endif
endfunction

