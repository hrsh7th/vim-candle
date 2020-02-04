if exists('g:loaded_candle')
  finish
endif
let g:loaded_candle = v:true

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

