let s:next_winid = -1

"
" candle#render#autocmd#initialize
"
function! candle#render#autocmd#initialize(context) abort
  execute printf('augroup candle#render:%s', a:context.bufname)
    autocmd!
    autocmd BufWinLeave * call s:on_buf_win_leave()
    autocmd CursorMoved <buffer> call s:on_cursor_moved()
    autocmd BufEnter <buffer> call s:on_buf_enter()
    autocmd WinEnter * call s:on_win_enter_all()
  augroup END
endfunction

"
" on_buf_win_leave
"
" It uses to detect `WinClose` to kill candle processes.
"
function! s:on_buf_win_leave() abort
  let l:ctx = {}
  function! l:ctx.callback() abort
    for l:bufnr in range(1, bufnr('$'))
      let l:candle = getbufvar(l:bufnr, 'candle', {})
      if empty(l:candle)
        continue
      endif

      if win_id2win(l:candle.state.winid) == 0
        execute printf('bdelete! %s', l:bufnr)
      endif
    endfor
  endfunction
  call timer_start(0, { -> l:ctx.callback() })
endfunction

"
" s:on_win_enter_all
"
function! s:on_win_enter_all() abort
  if s:next_winid == -1
    return
  endif
  call win_gotoid(s:next_winid)
  let s:next_winid = -1
endfunction

"
" on_buf_enter
"
function! s:on_buf_enter() abort
  call cursor([b:candle.state.cursor, col('.')])

  " NOTE: This refresh is needed to fix window height when left from query buffer.
  call b:candle.refresh()
endfunction

"
" on_cursor_moved
"
function! s:on_cursor_moved() abort
  call b:candle.set_cursor(line('.'))
endfunction

