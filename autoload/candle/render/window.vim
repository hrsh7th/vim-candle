"
" candle#render#window#open
"
function! candle#render#window#initialize(candle) abort
  let l:prev_candle = getbufvar('%', 'candle', {})
  if !empty(l:prev_candle)
    let l:keepjumps = l:prev_candle.option.keepjumps
  else
    let l:keepjumps = v:false
  endif

  let l:layout = a:candle.option.layout
  if a:candle.option.layout_keep && !empty(l:prev_candle)
    let l:layout = 'edit'
  endif

  execute printf('botright %s %s',
  \   l:keepjumps ? 'keepjumps' : '',
  \   l:layout
  \ )
  execute printf('%sbuffer', bufnr(a:candle.bufname))

  call candle#render#window#resize(a:candle)
  call setwinvar(winnr(), '&number', 0)
  call setwinvar(winnr(), '&signcolumn', 'yes')
  call setwinvar(winnr(), '&winfixwidth', 1)
  call setwinvar(winnr(), '&winfixheight', 1)
endfunction

"
" candle#render#window#resize
"
function! candle#render#window#resize(candle) abort
  if !a:candle.is_visible()
    return
  endif

  " width
  if a:candle.option.layout !=# 'split'
    call s:set_width(a:candle.winid, a:candle.option.maxwidth)
  endif

  " height
  if a:candle.option.layout !=# 'vsplit'
    call s:set_height(a:candle.winid, len(a:candle.state.items))
  endif
endfunction

"
" set_width
"
function! s:set_width(winid, width) abort
  if winwidth(win_id2win(a:winid)) == a:width
    call candle#log('[SKIP] s:set_width')
    return
  endif

  if has('nvim')
    call nvim_win_set_width(a:winid, a:width)
  else
    call win_execute(a:winid, printf('vertical resize %s', a:width))
  endif
endfunction

"
" set_height
"
function! s:set_height(winid, height) abort
  if winheight(win_id2win(a:winid)) == a:height
    call candle#log('[SKIP] s:set_height')
    return
  endif

  if has('nvim')
    call nvim_win_set_height(a:winid, a:height)
  else
    call win_execute(a:winid, printf('resize %s', a:height))
  endif
endfunction

