let s:input_debounce_timer_id = -1

"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  " NOTE: Error occur when split on window that's height less than 3
  if winheight(0) < 3
    resize 3
  endif

  " NOTE: This line is needs by right resize window when query changed.
  " Vim show cursor as much as possible when window resizing.
  " So cursor should be top at input window.
  normal! gg

  execute printf('new | resize %s', 1)
  call setbufvar('%', 'candle', a:candle)
  call setbufvar('%', '&filetype', 'candle.input')
  call setbufvar('%', '&buftype', 'nofile')
  call setbufvar('%', '&bufhidden', 'delete')
  setlocal winheight=1
  setlocal winfixheight
  startinsert!

  augroup printf('candle#render#input:%s', l:candle.bufname)
    autocmd!
    autocmd TextChanged,TextChangedI,TextChangedP <buffer> call s:on_text_changed()
    autocmd BufWinLeave <buffer> call s:on_buf_win_leave()
  augroup END

  inoremap <silent><buffer> <CR>  <Esc>:<C-u>call <SID>on_CR()<CR>
  inoremap <silent><buffer> <Esc> <Esc>:<C-u>call <SID>on_ESC()<CR>
  inoremap <silent><buffer> <C-y> <Esc>:<C-u>call <SID>on_ctrl_y()<CR>
  inoremap <silent><buffer> <C-n> <Esc>:<C-u>call <SID>on_ctrl_n()<CR>a
  inoremap <silent><buffer> <C-p> <Esc>:<C-u>call <SID>on_ctrl_p()<CR>a

  call setline('.', a:candle.state.query)
  call cursor([1, strlen(a:candle.state.query) + 1])

  doautocmd User candle#input#start
endfunction

"
" on_buf_win_leave
"
function! s:on_buf_win_leave() abort
  for l:winid in win_findbuf(bufnr(b:candle.bufname))
    call win_gotoid(l:winid)
    doautocmd BufEnter
    break
  endfor
endfunction

"
" on_text_changed
"
function! s:on_text_changed() abort
  let l:ctx = {}
  let l:ctx.candle = b:candle
  function! l:ctx.callback() abort
    if has_key(b:, 'candle') && self.candle.state.query !=# getline('.')
      call self.candle.top()
      call self.candle.query(getline('.'))
    endif
  endfunction
  call timer_stop(s:input_debounce_timer_id)
  let s:input_debounce_timer_id = timer_start(100, { -> l:ctx.callback() })

  call b:candle.refresh()
endfunction

"
" on_CR
"
function! s:on_CR() abort
  let l:candle = b:candle
  quit
  call win_gotoid(l:candle.state.winid)
endfunction

"
" on_ESC
"
function! s:on_ESC() abort
  let l:candle = b:candle
  quit
  call win_gotoid(l:candle.state.winid)
endfunction

"
" on_ctrl_y
"
function! s:on_ctrl_y() abort
  let l:candle = b:candle
  quit
  call win_gotoid(l:candle.state.winid)
  call candle#action('default')
endfunction

"
" on_ctrl_n
"
function! s:on_ctrl_n() abort
  call b:candle.down()
endfunction

"
" on_ctrl_p
"
function! s:on_ctrl_p() abort
  call b:candle.up()
endfunction
