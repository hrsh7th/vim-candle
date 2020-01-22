"
" candle#render#window#open
"
function! candle#render#window#open(candle) abort
  let l:bufname = a:candle.bufname
  let l:bufnr = bufnr(a:candle.bufname, v:true)
  let l:width = a:candle.maxwidth
  let l:height = a:candle.maxheight

  if a:candle.layout ==# 'floating' && exists('*nvim_open_win')
    let l:winid = nvim_open_win(l:bufnr, v:true, {
          \   'relative': 'editor',
          \   'width': l:width,
          \   'height': l:height,
          \   'col': float2nr(&columns / 2 - l:width / 2),
          \   'row': float2nr(&lines / 2 - l:height / 2),
          \   'focusable': v:true,
          \   'style': 'minimal',
          \ })
    call candle#utils#highlight#extend('NormalFloat', 'CandleSignColumn', {})
    call setwinvar(l:winid, '&winhighlight', 'SignColumn:CandleSignColumn')
  else
    execute printf('botright %s #%s', a:candle.layout, l:bufnr)
  endif

  let b:candle = a:candle
  let b:candle.winid = win_getid()
  call candle#render#window#resize(l:bufname, l:width, l:height)
endfunction

"
" candle#render#window#resize
"
function! candle#render#window#resize(bufname, width, height) abort
  let l:winnr = bufwinnr(a:bufname)
  let l:candle = getbufvar(a:bufname, 'candle')

  " width
  if l:candle.layout !=# 'split'
    call s:set_width(l:winnr, a:width)
  endif

  " height
  if l:candle.layout !=# 'vsplit'
    let l:screenpos = win_screenpos(l:winnr)
    if winheight(l:winnr) != (&lines - s:get_offset_height())
      call s:set_height(l:winnr, a:height)
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

function! s:set_width(winnr, width) abort
  if has('nvim')
    call nvim_win_set_width(win_getid(a:winnr), a:width)
  else
  endif
endfunction

function! s:set_height(winnr, height) abort
  if has('nvim')
    call nvim_win_set_height(win_getid(a:winnr), a:height)
  else
  endif
endfunction
