"
" candle#render#input#open
"
function! candle#render#input#open(candle) abort
  execute printf('new | resize %s', 1)
  call setbufvar('%', '&buftype', 'nofile')
  call setbufvar('%', '&bufhidden', 'delete')
  setlocal winheight=1
  setlocal winfixheight
  startinsert!

  let b:candle = a:candle

  augroup printf('candle#render#input:%s', l:candle.bufname)
    autocmd!
    autocmd TextChanged,TextChangedI,TextChangedP <buffer> call s:on_text_changed()
    autocmd InsertEnter <buffer> call s:on_insert_enter()
    autocmd InsertLeave <buffer> call s:on_insert_leave()
  augroup END
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
" on_insert_enter
"
function! s:on_insert_enter() abort
  let l:candle = getbufvar(b:candle.bufname, 'candle')
  let l:candle.state.query = getline('.')
  call candle#render#refresh({
        \   'bufname': l:candle.bufname,
        \   'sync': v:true,
        \ })
endfunction

"
" on_insert_leave
"
function! s:on_insert_leave() abort
  let l:candle = getbufvar(b:candle.bufname, 'candle')
  for l:winid in win_findbuf(bufnr(l:candle.bufname))
    call execute('bdelete!')
    call win_gotoid(l:winid)
    call candle#render#refresh({
          \   'bufname': l:candle.bufname,
          \   'sync': v:true,
          \   'force': v:true
          \ })
    break
  endfor
endfunction

