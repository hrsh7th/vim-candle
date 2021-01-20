let s:cache = {
\   'reltime': reltime(),
\   'statusline': '',
\ }

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

  if reltimefloat(reltime(s:cache.reltime)) * 1000 < 500
    return s:cache.statusline
  endif

  let s:cache.reltime = reltime()
  let s:cache.statusline = printf(
  \   '[%s] %s/%s | %s | `%s`',
  \   b:candle.source.name,
  \   b:candle.state.filtered_total,
  \   b:candle.state.total,
  \   b:candle.state.status,
  \   b:candle.state.query
  \ )
  return s:cache.statusline
endfunction

