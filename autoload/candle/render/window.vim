"
" candle#render#window#open
"
function! candle#render#window#initialize(candle) abort
  if a:candle.layout ==# 'floating'
    call nvim_open_win(bufnr(a:candle.bufname), v:true, {
    \   'relative': 'editor',
    \   'width': 1,
    \   'height': 1,
    \   'col': float2nr(&columns / 2 - a:candle.maxwidth / 2),
    \   'row': float2nr(&lines / 2 - a:candle.maxheight / 2),
    \   'focusable': v:true,
    \   'style': 'minimal',
    \ })
  else
    execute printf('botright %s #%s', a:candle.layout, bufnr(a:candle.bufname))
    call candle#render#window#resize(a:candle)
  endif
  call setwinvar(winnr(), '&number', 0)
  call setwinvar(winnr(), '&signcolumn', 'yes')
endfunction

"
" candle#render#window#resize
"
function! candle#render#window#resize(candle) abort
  let l:winnr = win_id2win(a:candle.state.winid)

  " width
  if a:candle.layout !=# 'split'
    call s:set_width(l:winnr, a:candle.maxwidth)
  endif

  " height
  if a:candle.layout !=# 'vsplit'
    let l:screenpos = win_screenpos(l:winnr)
    if winheight(l:winnr) != (&lines - s:get_offset_height())
      call s:set_height(l:winnr, len(a:candle.state.items))
    endif
  endif
endfunction

"
" get_offset_height
"
function! s:get_offset_height() abort
  let l:offset = 1

  " tabline.
  if &showtabline == 1 && tabpagenr('$') != 1 || &showtabline == 2
    let l:offset += 1
  endif

  " cmdline
  let l:offset += &cmdheight

  return l:offset
endfunction

"
" set_width
"
function! s:set_width(winnr, width) abort
  if winwidth(a:winnr) == a:width
    call candle#log('[SKIP] s:set_width')
    return
  endif

  if has('nvim')
    call nvim_win_set_width(win_getid(a:winnr), a:width)
  else
    if winnr() != a:winnr
      call win_execute(win_getid(a:winnr), printf('vertical resize %s', a:width))
    else
      execute printf('vertical resize %s', a:width)
    endif
  endif
endfunction

"
" set_height
"
function! s:set_height(winnr, height) abort
  if winheight(a:winnr) == a:height
    call candle#log('[SKIP] s:set_height')
    return
  endif

  if has('nvim')
    call nvim_win_set_height(win_getid(a:winnr), a:height)
  else
    if winnr() != a:winnr
      call win_execute(win_getid(a:winnr), printf('resize %s', a:height))
    else
      execute printf('resize %s', a:height)
    endif
  endif
endfunction

