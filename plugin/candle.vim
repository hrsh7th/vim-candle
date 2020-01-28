if exists('g:loaded_candle')
  finish
endif
let g:loaded_candle = v:true

"
" config
"
let g:candle = get(g:, 'candle', {})
let g:candle.debug = get(g:candle, 'debug', v:false)
let g:candle.global = get(g:candle, 'global', {})
let g:candle.source = get(g:candle, 'source', {})

"
" built-in sources
"
call candle#register(candle#source#files#source#definition())
call candle#register(candle#source#grep#source#definition())
call candle#register(candle#source#mru_file#source#definition())
call candle#register(candle#source#item#source#definition())

doautocmd User candle#initialize

