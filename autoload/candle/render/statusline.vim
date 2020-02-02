"
" candle#render#statusline#update
"
function! candle#render#statusline#update(candle) abort
  setlocal statusline=%!candle#render#statusline#_update()
endfunction

"
" candle#render#statusline#_update
"
function! candle#render#statusline#_update() abort
  if !has_key(b:, 'candle')
    return ''
  endif

  return printf(
  \   '[%s] %s/%s | %s | `%s`',
  \   b:candle.source.source.name,
  \   b:candle.state.filtered_total,
  \   b:candle.state.total,
  \   b:candle.state.status,
  \   b:candle.state.query
  \ )
endfunction

