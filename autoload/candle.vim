let s:Promise = vital#candle#import('Async.Promise')
let s:OptionParser = vital#candle#import('OptionParser')
let s:Server = candle#server#import()
let s:Source = candle#source#import()

let s:state = {
      \   'id': -1,
      \   'sources': {},
      \ }

call s:Promise.on_unhandled_rejection({ err -> candle#log('[ERROR]', err) })

"
" candle#register
"
function! candle#register(definition) abort
  let s:state.sources[a:definition.name] = a:definition
endfunction

"
" candle#start
"
function! candle#start(option) abort
  let s:state.id += 1
  call candle#render#start(s:context(a:option))
endfunction

"
" candle#sources
"
function! candle#sources() abort
  return copy(s:state.sources)
endfunction

"
" candle#sync
"
function! candle#sync(promise_or_fn, ...) abort
  let l:timeout = get(a:000, 0, -1)
  let l:start = reltime()
  while v:true
    if type(a:promise_or_fn) == v:t_func
      if a:promise_or_fn()
        return
      endif
    else
      if a:promise_or_fn._state == 1
        return a:promise_or_fn._result
      elseif a:promise_or_fn._state == 2
        throw json_encode(a:promise_or_fn._result)
      endif
    endif
    sleep 1m

    if l:timeout != -1 && reltimefloat(reltime(l:start)) * 1000 > l:timeout
      throw 'candle#sync: timeout'
    endif
  endwhile
endfunction

"
" candle#log
"
function! candle#log(...) abort
  call writefile([join([strftime('%H:%M:%S')] + a:000, "\t")], '/tmp/candle.log', 'a')
endfunction

"
" candle#echo
"
function! candle#echo(...) abort
  for l:msg in a:000
    let l:msg = string(l:msg)
    let l:msg = substitute(l:msg, "\r\n", "\n", 'g')
    let l:msg = substitute(l:msg, "\r", "\n", 'g')
    for l:line in split(string(l:msg), "\n")
      echomsg l:line
    endfor
    echomsg ' '
  endfor
endfunction

"
" context
"
function! s:context(args) abort
  let l:context = {}
  let l:context.bufname = printf('candle-%s', s:state.id)
  let l:context.winwidth = get(a:args, 'winwidth', float2nr(&columns * 0.6))
  let l:context.winheight = get(a:args, 'winheight', float2nr(&lines * 0.6))
  let l:context.layout = get(a:args, 'layout', 'floating')
  let l:context.source = s:Source.new(
        \   s:Server.new(),
        \   s:state.sources[a:args.source],
        \   a:args
        \ )
  return l:context
endfunction
