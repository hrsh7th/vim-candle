"
" candle#render#statusline#initialize
"
function! candle#render#statusline#initialize(candle) abort
  setlocal statusline=%!candle#render#statusline#update()
endfunction

"
" candle#render#statusline#update
"
function! candle#render#statusline#update() abort
  return printf(
  \   '%s/%s (%s)',
  \   b:candle.state.filtered_total,
  \   b:candle.state.total,
  \   b:candle.state.status
  \ )
endfunction

