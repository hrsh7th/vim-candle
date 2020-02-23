let s:debounce_timer_id = -1

"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  doautocmd User candle#input#start

  augroup printf('candle#render#input:%s', a:candle.bufname)
    autocmd!
    autocmd CmdlineChanged <buffer> call s:on_query_change()
  augroup END

  redraw
  call input("$ ", a:candle.state.query)

  augroup printf('candle#render#input:%s', a:candle.bufname)
    autocmd!
  augroup END

endfunction

"
" s:on_query_change
"
function! s:on_query_change() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    if empty(getbufvar('%', 'candle', {}))
      return
    endif

    if b:candle.state.query !=# getcmdline()
      call b:candle.top()
      call b:candle.query(getcmdline())
    endif

    " NOTE: This line is needed to fix window height when enter input buffer.
    call b:candle.refresh()

    redraw
  endfunction

  call timer_stop(s:debounce_timer_id)
  let s:debounce_timer_id = timer_start(0, { -> l:ctx.callback() })
endfunction

