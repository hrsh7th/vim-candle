let s:next_winid = -1

"
" candle#render#autocmd#initialize
"
function! candle#render#autocmd#initialize(context) abort
  execute printf('augroup candle#render:%s', a:context.bufname)
    autocmd!
    autocmd BufWinLeave <buffer> call s:on_buf_win_leave()
    autocmd CursorMoved <buffer> call s:on_cursor_moved()
    autocmd BufEnter <buffer> call s:on_buf_enter()
    autocmd WinEnter * call s:on_win_enter_all()
  augroup END
endfunction

"
" on_buf_win_leave
"
function! s:on_buf_win_leave() abort
  call candle#log('[AUTOCMD] on_buf_win_leave')
  call b:candle.stop()
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
  call candle#log('[AUTOCMD] on_buf_enter')
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

