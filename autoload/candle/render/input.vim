"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  try
    new
    if winheight(0) != 1
      execute printf('resize %s', 1)
    endif
  catch /.*/
  endtry
  call setbufvar('%', 'candle', a:candle)
  call setbufvar('%', '&buftype', 'nofile')
  call setbufvar('%', '&bufhidden', 'delete')
  setlocal winheight=1
  setlocal winfixheight
  startinsert!

  augroup printf('candle#render#input:%s', l:candle.bufname)
    autocmd!
    autocmd TextChanged,TextChangedI,TextChangedP <buffer> call s:on_text_changed()
    autocmd WinLeave <buffer> call s:on_win_leave()
  augroup END

  inoremap <silent><buffer> <CR> <Esc>:<C-u>call <SID>on_CR()<CR>

  call setline('.', a:candle.state.query)
  call cursor([1, strlen(a:candle.state.query) + 1])
  call candle#render#refresh({
        \   'bufname': a:candle.bufname,
        \   'sync': v:true
        \ })
endfunction

"
" on_text_changed
"
function! s:on_text_changed() abort
  let l:candle = getbufvar(b:candle.bufname, 'candle')
  let l:candle.state.index = 0
  let l:candle.state.cursor = 1
  let l:candle.state.query = getline('.')
  call candle#render#refresh({
        \   'bufname': l:candle.bufname,
        \   'sync': v:true,
        \ })
endfunction

"
" on_win_leave
"
function! s:on_win_leave() abort
  let l:candle = getbufvar(b:candle.bufname, 'candle')
  for l:winid in win_findbuf(bufnr(l:candle.bufname))
    call execute('bdelete!')
    call win_gotoid(l:winid)
    break
  endfor
endfunction

"
" s:on_CR
"
function! s:on_CR() abort
  quit
endfunction

