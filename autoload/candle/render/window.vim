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

  execute printf('keepalt botright %s %s',
  \   l:keepjumps ? 'keepjumps' : '',
  \   l:layout
  \ )
  execute printf('keepalt %sbuffer', bufnr(a:candle.bufname))

  let a:candle.winid = win_getid()

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
    call s:set_width(a:candle, float2nr(a:candle.option.maxwidth))
  endif

  " height
  if a:candle.option.layout !=# 'vsplit'
    call s:set_height(a:candle, len(a:candle.state.items))
  endif
endfunction

"
" set_width
"
function! s:set_width(candle, width) abort
  let l:width = a:width
  let l:width = max([float2nr(a:candle.option.minwidth), l:width])
  let l:width = min([float2nr(a:candle.option.maxwidth), l:width])

  if winwidth(win_id2win(a:candle.winid)) == l:width
    call candle#log('[SKIP] s:set_width')
    return
  endif

  if has('nvim')
    call nvim_win_set_width(a:candle.winid, l:width)
  else
    call win_execute(a:candle.winid, printf('vertical resize %s', l:width))
  endif
endfunction

"
" set_height
"
function! s:set_height(candle, height) abort
  let l:height = a:height
  let l:height = max([float2nr(a:candle.option.minheight), l:height])
  let l:height = min([float2nr(a:candle.option.maxheight), l:height])

  if winheight(win_id2win(a:candle.winid)) == l:height
    call candle#log('[SKIP] s:set_height')
    return
  endif

  if has('nvim')
    call nvim_win_set_height(a:candle.winid, l:height)
  else
    call win_execute(a:candle.winid, printf('resize %s', l:height))
  endif
endfunction

