"
" candle#render#highlight#initialize
"
function! candle#render#highlight#initialize(candle) abort
"  if a:candle.layout ==# 'floating'
"    call s:extend('NormalFloat', 'SignColumn')
"  else
"    call s:extend('Normal', 'SignColumn')
"  endif
endfunction

function! s:extend(parent, highlight) abort
  let l:cmds = [printf('highlight! %s', a:highlight)]
  for l:name in [
        \   'gui',
        \   'guifg',
        \   'guibg',
        \   'guisp',
        \   'bg',
        \   'fg'
        \ ]
    let l:value = synIDattr(synIDtrans(hlID(a:parent)), l:name)
    if !empty(l:value)
      let l:cmds += [printf('%s=%s', get({
      \   'bg': 'guibg',
      \   'fg': 'guifg'
      \ }, l:name, l:name), l:value)]
    endif
  endfor
  execute join(l:cmds, ' ')
endfunction
