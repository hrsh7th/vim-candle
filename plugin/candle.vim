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
let g:candle.global.start_delay = get(g:candle.global, 'start_delay', 20)

"
" test
"
command! -nargs=* CandleTest call candle#start({
      \   'source': 'item',
      \   'layout': 'floating',
      \   'winwidth': 24,
      \   'winheight': 3,
      \   'items': [{
      \     'id': 1,
      \     'title': 'test1'
      \   }, {
      \     'id': 2,
      \     'title': 'test2'
      \   }, {
      \     'id': 3,
      \     'title': 'test3'
      \   }, {
      \     'id': 4,
      \     'title': 'test4'
      \   }, {
      \     'id': 5,
      \     'title': 'test5'
      \   }]
      \ })

"
" start
"
command! -nargs=* -complete=customlist,s:complete Candle call s:start('<args>')
function! s:start(args) abort
  try
    let l:parser = candle#get_option_parser()
    let l:source = candle#get_source(l:parser.parse(a:args).source)
    call map(
    \   copy(l:source.get_options()),
    \   { _, option ->
    \     l:parser.on(option.name, option.description, option.extra)
    \   }
    \ )
    call candle#start(l:parser.parse(a:args))
  catch /.*/
    echomsg v:exception
  endtry
endfunction

"
" complete
"
function! s:complete(arglead, cmdline, cursorpos) abort
  let l:parser = candle#get_option_parser()
  try
    let l:source = candle#get_source(l:parser.parse(a:cmdline).source)
    call map(copy(l:source.get_options()), { _, o ->
    \   l:parser.on(o.name, o.description, o.extra)
    \ })
  catch /.*/
  endtry
  return l:parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

"
" built-in sources
"
call candle#register(candle#source#files#source#definition())
call candle#register(candle#source#grep#source#definition())
call candle#register(candle#source#mru_file#source#definition())
call candle#register(candle#source#item#source#definition())

doautocmd User candle#initialize
