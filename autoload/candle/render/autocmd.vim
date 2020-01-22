let s:next_winid = -1

"
" candle#render#autocmd#initialize
"
function! candle#render#autocmd#initialize(context) abort
  execute printf('augroup candle#render:%s', a:context.bufname)
    autocmd!
    autocmd BufWinEnter <buffer> call s:on_buf_win_enter()
    autocmd BufWinLeave <buffer> call s:on_buf_win_leave()
    autocmd BufEnter <buffer> call s:on_buf_enter()
    autocmd CursorMoved <buffer> call s:on_cursor_moved()
    autocmd WinEnter * call s:on_win_enter_all()
  augroup END
endfunction

"
" on_buf_win_enter
"
function! s:on_buf_win_enter() abort
  call candle#log('[AUTOCMD] on_buf_win_enter')
  let l:bufname = bufname('%')
  if len(b:candle.items) > 0
    call cursor([b:candle.state.cursor])
  endif
  call b:candle.source.attach({ notification ->
        \   candle#render#on_notification(l:bufname, notification)
        \ })
endfunction

"
" on_buf_win_leave
"
function! s:on_buf_win_leave() abort
  call candle#log('[AUTOCMD] on_buf_win_leave')
  let l:candle = b:candle
  call l:candle.source.stop()
  let s:next_winid = l:candle.prev_winid
endfunction

"
"
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
  let l:bufname = bufname('%')
  call cursor([b:candle.state.cursor, col('.')])
  call candle#render#refresh({
        \   'bufname': l:bufname,
        \   'sync': v:true
        \ })
endfunction

"
" on_cursor_moved
"
function! s:on_cursor_moved() abort
  if has_key(b:, 'candle') && b:candle.bufname ==# bufname('%')
    if b:candle.state.cursor != line('.')
      call candle#log('[AUTOCMD] on_cursor_moved')
      let b:candle.state.cursor = line('.')
      call candle#render#refresh({
            \   'bufname': b:candle.bufname,
            \   'sync': v:false,
            \ })
    endif
  endif
endfunction

