let s:timer_id = -1

"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  doautocmd User candle#input#start

  augroup printf('candle#render#input:%s', a:candle.bufname)
    autocmd!
    autocmd CmdlineChanged <buffer> call s:on_query_change()
  augroup END

  " NOTE: redraw causes cursor flicker so should use redrawstatus in here.
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

    call b:candle.refresh()

    " NOTE: redraw causes cursor flicker so should use redrawstatus in here.
    redrawstatus

    let s:timer_id = -1
  endfunction

  if s:timer_id == -1
    let s:timer_id = timer_start(0, { -> l:ctx.callback() })
  endif
endfunction

