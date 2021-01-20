if !hlexists('CandleCursorSign')
  highlight! link CandleCursorSign Question
endif

if !hlexists('CandleCursorLine')
  highlight! link CandleCursorLine CursorLine
endif

if !hlexists('CandleSelectedLine')
  highlight! link CandleSelectedLine QuickFixLine
endif

call sign_define('CandleCursorLine', {
      \   'text': '>',
      \   'texthl': 'CandleCursorSign',
      \   'numhl': 'CandleCursorLine',
      \   'linehl': 'CandleCursorLine',
      \ })

call sign_define('CandleSelectedLine', {
      \   'text': '*',
      \   'texthl': 'CandleSelectedLine',
      \   'numhl': 'CandleSelectedLine',
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
" candle#render#signs#selected
"
function! candle#render#signs#selected(candle) abort
  try
    call sign_unplace('CandleSelectedLine', {
    \   'buffer': a:candle.bufname,
    \ })
    for l:i in range(0, len(a:candle.state.items))
      if a:candle.state.is_selected_all || has_key(a:candle.state.selected_id_map, a:candle.state.items[l:i].id)
        call sign_place(0, 'CandleSelectedLine', 'CandleSelectedLine', a:candle.bufname, {
        \   'priority': 200,
        \   'lnum': l:i + 1,
        \ })
      endif
    endfor
  catch /.*/
  endtry
endfunction

