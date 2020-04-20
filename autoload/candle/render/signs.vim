if !hlexists('CandleCursorLine')
  highlight! link CandleCursorLine CursorLine
endif

if !hlexists('CandleSelectedLine')
  highlight! link CandleSelectedLine MoreMsg
endif

call sign_define('CandleCursorLine', {
      \   'text': '-',
      \   'linehl': 'CandleCursorLine'
      \ })

call sign_define('CandleSelectedLine', {
      \   'text': '*',
      \   'linehl': 'CandleSelectedLine',
      \ })

"
" candle#render#signs#cursor
"
function! candle#render#signs#cursor(candle) abort
  call sign_unplace('CandleCursorLine', {
  \   'buffer': a:candle.bufname,
  \ })
  call sign_place(0, 'CandleCursorLine', 'CandleCursorLine', a:candle.bufname, {
  \   'priority': 100,
  \   'lnum': a:candle.state.cursor,
  \ })
endfunction

"
" candle#render#signs#selected_ids
"
function! candle#render#signs#selected_ids(candle) abort
  try
    call sign_unplace('CandleSelectedLine', {
    \   'buffer': a:candle.bufname,
    \ })
    if a:candle.state.is_selected_all
      for l:lnum in range(1, winheight(bufwinnr(a:candle.bufname)) + 1)
        call sign_place(0, 'CandleSelectedLine', 'CandleSelectedLine', a:candle.bufname, {
        \   'priority': 200,
        \   'lnum': l:lnum
        \ })
      endfor
    else
      let l:item_ids = map(copy(a:candle.state.items), { _, item -> item.id })
      for l:selected_id in a:candle.state.selected_ids
        let l:idx = index(l:item_ids, l:selected_id)
        if l:idx >= 0
          call sign_place(0, 'CandleSelectedLine', 'CandleSelectedLine', a:candle.bufname, {
          \   'priority': 200,
          \   'lnum': l:idx + 1,
          \ })
        endif
      endfor
    endif
  catch /.*/
  endtry
endfunction

