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
  call a:candle.top()

  execute printf('new | resize %s', 1)
  call setbufvar('%', 'candle', a:candle)
  call setbufvar('%', '&filetype', 'candle.input')
  call setbufvar('%', '&buftype', 'nofile')
  call setbufvar('%', '&bufhidden', 'delete')
  call setline('.', a:candle.state.query)
  call cursor([1, strlen(a:candle.state.query) + 1])
  setlocal winheight=1
  setlocal winfixheight
  startinsert!

  augroup printf('candle#render#input:%s', l:candle.bufname)
    autocmd!
    autocmd TextChanged,TextChangedI,TextChangedP <buffer> call s:on_query_change()
  augroup END

  doautocmd User candle#input#start
endfunction

"
" s:on_query_change
"
function! s:on_query_change() abort
  if b:candle.state.query !=# getline('.')
    call b:candle.top()
    call b:candle.query(getline('.'))
  endif

  " NOTE: This line is needed to fix window height when enter input buffer.
  call b:candle.refresh()
endfunction

