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
for [s:key, s:value] in items({
\   'layout': 'split',
\   'layout_keep': v:true,
\   'auto_action': '',
\   'start_input': v:false,
\   'maxwidth': float2nr(&columns * 0.3),
\   'minwidth': 1,
\   'maxheight': float2nr(&lines * 0.3),
\   'minheight': 1,
\   'action': {},
\ })
  let g:candle.option[s:key] = get(g:candle.option, s:key, s:value)
endfor

"
" built-in sources
"
call candle#register(candle#source#file#source#definition())
call candle#register(candle#source#grep#source#definition())
call candle#register(candle#source#mru_file#source#definition())
call candle#register(candle#source#mru_dir#source#definition())
call candle#register(candle#source#item#source#definition())
call candle#mapping#init()

"
" built-in actions
"

for s:action in candle#action#common#get()
  call candle#action#register(s:action)
endfor
for s:action in candle#action#location#get()
  call candle#action#register(s:action)
endfor

doautocmd <nomodeline> User candle#initialize


