if exists('g:loaded_candle')
  finish
endif
let g:loaded_candle = v:true

if has('nvim')
  if !exists('*deletebufline')
    echomsg '[CANDLE] candle disabled.'
    echomsg '[CANDLE] exists(''*deletebufline'') is not returns 1.'
    echomsg '[CANDLE] Please update nvim.'
    finish
  endif
endif

if !has('nvim')
  if !exists('*win_execute')
    echomsg '[CANDLE] candle disabled.'
    echomsg '[CANDLE] exists(''*win_execute'') is not returns 1.'
    echomsg '[CANDLE] Please update vim.'
    finish
  endif
endif

"
" config
"
let g:candle = get(g:, 'candle', {})
let g:candle.debug = get(g:candle, 'debug', '')

"
" built-in sources
"
call candle#register(candle#source#file#source#definition())
call candle#register(candle#source#grep#source#definition())
call candle#register(candle#source#mru_file#source#definition())
call candle#register(candle#source#mru_dir#source#definition())
call candle#register(candle#source#item#source#definition())

doautocmd User candle#initialize

