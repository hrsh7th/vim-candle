let s:tick = 200

"
" candle#render#autocmd#initialize
"
function! candle#render#autocmd#initialize(context) abort
  execute printf('augroup candle#render:%s', a:context.bufname)
    autocmd!
    autocmd BufWinEnter <buffer> call s:on_buf_win_enter()
    autocmd BufWinLeave <buffer> call s:on_buf_win_leave()
    autocmd CursorMoved <buffer> call s:on_cursor_moved()
  augroup END

  call s:on_buf_win_enter()
endfunction

"
" on_buf_win_enter
"
function! s:on_buf_win_enter() abort
  let l:bufname = bufname('%')
  call b:candle.source.attach({ notification ->
        \   candle#render#on_notification(l:bufname, notification)
        \ })
endfunction

"
" on_buf_win_leave
"
function! s:on_buf_win_leave() abort
  call b:candle.source.detach()
endfunction

"
" on_cursor_moved
"
function! s:on_cursor_moved() abort
  if has_key(b:, 'candle') && b:candle.bufname ==# bufname('%')
    if b:candle.state.cursor != line('.')
      let b:candle.state.cursor = line('.')
      call candle#render#refresh({
            \   'bufname': b:candle.bufname,
            \   'sync': v:false,
            \ })
    endif
  endif
endfunction

