let s:Promise = vital#candle#import('Async.Promise')
let s:Server = candle#server#import()
let s:Source = candle#source#import()
let s:Context = candle#context#import()

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
  try
    call candle#log('')
    call candle#log('[START]', string(a:option))
    call s:Context.new(s:context(a:option)).start()
  catch /.*/
    echomsg v:exception
  endtry
endfunction

"
" candle#action
"
function! candle#action(name) abort
  if !has_key(b:, 'candle')
    return
  endif
  call b:candle.action(a:name)
endfunction

"
" candle#sync
"
function! candle#sync(promise_or_fn, ...) abort
  let l:timeout = get(a:000, 0, 500)
  let l:start = reltime()
  while v:true
    if type(a:promise_or_fn) == v:t_func && a:promise_or_fn()
      return
    elseif has_key(a:promise_or_fn, '_vital_promise')
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
  if g:candle.debug
    call writefile([join([strftime('%H:%M:%S')] + a:000, "\t")], '/tmp/candle.log', 'a')
  endif
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
function! s:context(option) abort
  let s:state.id += 1

  let a:option.maxwidth = get(a:option, 'maxwidth', float2nr(&columns * 0.8))
  let a:option.maxheight = get(a:option, 'maxheight', float2nr(&lines * 0.2))
  let a:option.layout = get(a:option, 'layout', 'split')
  let a:option.filter = get(a:option, 'filter', 'substring')
  let a:option.start_input = get(a:option, 'start_input', v:false)

  let l:context = {}
  let l:context.bufname = printf('candle-%s', s:state.id)
  let l:context.option = copy(a:option)
  let l:context.source = s:Source.new(
        \   s:Server.new(),
        \   s:state.sources[a:option.source],
        \   get(a:option, 'params')
        \ )

  return l:context
endfunction

