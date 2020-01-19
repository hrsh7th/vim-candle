"
" candle#render#buffer#initialize
"
function! candle#render#buffer#initialize(context) abort
  let l:bufnr = bufnr(a:context.bufname)
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  call setbufvar(l:bufnr, '&number', 0)
  call setbufvar(l:bufnr, '&signcolumn', 'yes')
endfunction

