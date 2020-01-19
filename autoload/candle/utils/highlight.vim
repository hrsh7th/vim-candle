"
" candle#utils#highlight#extend
"
function! candle#utils#highlight#extend(parent, highlight, option) abort
  let l:cmds = [printf('highlight! %s', a:highlight)]
  for l:name in [
        \   'gui',
        \   'guifg',
        \   'guibg',
        \   'guisp',
        \   'bg',
        \   'fg'
        \ ]
    if has_key(a:option, l:name)
      let l:cmds += [printf('%s=%s', l:name, a:option[l:name])]
    else
      let l:value = synIDattr(synIDtrans(hlID(a:parent)), l:name)
      if !empty(l:value)
        let l:cmds += [printf('%s=%s', get({
              \   'bg': 'guibg',
              \   'fg': 'guifg'
              \ }, l:name, l:name), l:value)]
      endif
    endif
  endfor
  execute join(l:cmds, ' ')
endfunction

