"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  " NOTE: Error occur when split on window that's height less than 3
  if winheight(0) < 3
    resize 3
  endif
  execute printf('new | resize %s', 1)
  call setbufvar('%', 'candle', a:candle)
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

  inoremap <silent><buffer> <CR> <Esc>:<C-u>call <SID>on_CR()<CR>
  inoremap <silent><buffer> <C-y> <Esc>:<C-u>call <SID>on_ctrl_y()<CR>
  inoremap <silent><buffer> <C-n> <Esc>:<C-u>call <SID>on_ctrl_n()<CR>i
  inoremap <silent><buffer> <C-p> <Esc>:<C-u>call <SID>on_ctrl_p()<CR>i
  nnoremap <silent><buffer> <C-n> :<C-u>call <SID>on_ctrl_n()<CR>
  nnoremap <silent><buffer> <C-p> :<C-u>call <SID>on_ctrl_p()<CR>

  call setline('.', a:candle.state.query)
  call cursor([1, strlen(a:candle.state.query) + 1])
endfunction

"
" on_text_changed
"
function! s:on_text_changed() abort
  call b:candle.top()
  call b:candle.query(getline('.'))
  call b:candle.refresh()
endfunction

"
" on_buf_win_leave
"
function! s:on_buf_win_leave() abort
  let l:candle = getbufvar(b:candle.bufname, 'candle')
  for l:winid in win_findbuf(bufnr(l:candle.bufname))
    call win_gotoid(l:winid)
    doautocmd BufEnter
    break
  endfor
endfunction

"
" on_CR
"
function! s:on_CR() abort
  call execute('bdelete!')
  doautocmd BufEnter
endfunction

"
" on_ctrl_CR
"
function! s:on_ctrl_y() abort
  let l:candle = b:candle
  quit
  call win_gotoid(l:candle.winid)
  call candle#action('default')
endfunction

"
" on_ctrl_n
"
function! s:on_ctrl_n() abort
  call b:candle.down()
  call b:candle.refresh()
endfunction

"
" on_ctrl_p
"
function! s:on_ctrl_p() abort
  call b:candle.up()
  call b:candle.refresh()
endfunction
