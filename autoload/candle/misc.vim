function! candle#misc#yesno(msg) abort
  let l:choose = input(a:msg . ' (yes/no): ')
  echomsg ' '
  if index(['y', 'ye', 'yes'], l:choose) > -1
    return v:true
  endif
  return v:false
endfunction
