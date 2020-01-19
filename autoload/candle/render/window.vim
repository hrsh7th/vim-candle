"
" candle#render#window#open
"
function! candle#render#window#open(context) abort
  let l:bufnr = bufnr(a:context.bufname, v:true)
  let l:width = get(a:context, 'winwidth', -1)
  let l:height = get(a:context, 'winheight', -1)
  if a:context.layout ==# 'floating' && exists('*nvim_open_win')
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
    execute printf('%s #%s', a:context.layout, l:bufnr)
    call candle#render#window#resize(l:bufnr, l:width, l:height)
  endif
endfunction

"
" candle#render#window#resize
"
function! candle#render#window#resize(bufnr, width, height) abort
  let l:winnr = bufwinnr(a:bufnr)

  " width
  call s:set_width(l:winnr, a:width)

  " height
  let l:screenpos = win_screenpos(l:winnr)
  if winheight(l:winnr) != (&lines - s:get_offset_height())
    call s:set_height(l:winnr, a:height)
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
