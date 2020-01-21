if exists('g:loaded_candle')
  finish
endif
let g:loaded_candle = v:true

let s:OptionParser = vital#candle#import('OptionParser')

let s:parser = s:OptionParser.new()
call s:parser.on('--source=VALUE', '', {
      \   'required': 1,
      \   'completion': { -> keys(candle#sources()) }
      \ })
call s:parser.on('--layout', '', {})
call s:parser.on('--winwidth', '', {})
call s:parser.on('--winheight', '', {})
call s:parser.on('--no-quit', '', {})

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
  let l:sources = candle#sources()

  " source name.
  let l:option = s:parser.parse(a:args)
  if !has_key(l:sources, l:option.source)
    echomsg printf('candle#start: `%s` is not valid source-name.', l:option.source)
    return
  endif

  " source specific option.
  let l:parser = deepcopy(s:parser)
  call map(
        \   copy(l:sources[l:option.source].get_options()),
        \   { _, option ->
        \     l:parser.on(option.name, option.description, option.extra)
        \   }
        \ )

  try
    call candle#start(l:parser.parse(a:args))
  catch /.*/
    echomsg v:exception
  endtry
endfunction

"
" complete
"
function! s:complete(arglead, cmdline, cursorpos) abort
  let l:sources = candle#sources()
  let l:parser = deepcopy(s:parser)
  try
    let l:option = l:parser.parse(a:cmdline)
    if has_key(l:sources, l:option.source)
      call map(copy(l:sources[l:option.source].get_options()), { _, o ->
            \   l:parser.on(o.name, o.description, o.extra)
            \ })
    endif
  catch /.*/
  endtry
  return l:parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

"
" built-in sources
"
call candle#register(candle#source#grep#source#definition())
call candle#register(candle#source#item#source#definition())
call candle#register(candle#source#mru_file#source#definition())

