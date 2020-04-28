if exists('g:loaded_candle')
  finish
endif
let g:loaded_candle = v:true

augroup candle#silent
  autocmd!
  autocmd User candle#initialize silent
  autocmd User candle#start silent
  autocmd User candle#iniput#start silent
augroup END

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
let g:candle.option = get(g:candle, 'option', {})
let g:candle.option.start_input = get(g:candle.option, 'start_input', v:false)

"
" built-in sources
"
call candle#register(candle#source#file#source#definition())
call candle#register(candle#source#grep#source#definition())
call candle#register(candle#source#mru_file#source#definition())
call candle#register(candle#source#mru_dir#source#definition())
call candle#register(candle#source#item#source#definition())

doautocmd User candle#initialize


