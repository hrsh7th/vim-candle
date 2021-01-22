"
" candle#render#statusline#update
"
function! candle#render#statusline#update(candle, ...) abort
  let l:force = get(a:000, 0, v:false)
  let l:ctx = {}
  function! l:ctx.callback() abort
    if !exists('b:candle')
      return
    endif
    let &statusline = printf(
    \   '[%s] %s/%s | %s | `%s`',
    \   b:candle.source.name,
    \   b:candle.state.filtered_total,
    \   b:candle.state.total,
    \   b:candle.state.status,
    \   b:candle.state.query,
    \ )
    redrawstatus
  endfunction
  if l:force
    call l:ctx.callback()
  else
    call candle#throttle('candle#render#statusline#update', { -> l:ctx.callback() }, 200)
  endif
endfunction

