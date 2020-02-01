let s:Promise = vital#candle#import('Async.Promise')
let s:Server = candle#server#import()
let s:Source = candle#source#import()
let s:Context = candle#context#import()

let s:root_dir = expand('<sfile>:p:h:h')

let s:state = {
\   'version': '',
\   'session_id': -1,
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
function! candle#start(args) abort
  try
    call candle#log('')
    call candle#log('[START]', string(a:args))
    call s:Context.new(s:context(a:args)).start()
  catch /.*/
    call candle#on_exception()
  endtry
endfunction

"
" candle#version
"
function! candle#version() abort
  if strlen(s:state.version) > 0
    return s:state.version
  endif

  try
    let l:package_json = json_decode(join(readfile(resolve(s:root_dir . '/package.json')), ''))
    let s:state.version = l:package_json.version
  catch /.*/
  endtry
  return s:state.version
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
  let l:timeout = get(a:000, 0, lamp#config('global.timeout'))
  let l:reltime = reltime()

  if type(a:promise_or_fn) == type({ -> {} })
    while v:true
      if  a:promise_or_fn()
        return
      endif

      if l:timeout != -1 && reltimefloat(reltime(l:reltime)) * 1000 > l:timeout
        throw 'candle#sync: timeout'
      endif
      sleep 1m
    endwhile
  elseif type(a:promise_or_fn) == type({}) && has_key(a:promise_or_fn, '_vital_promise')
    while v:true
      if a:promise_or_fn._state == 1
        return a:promise_or_fn._result
      elseif a:promise_or_fn._state == 2
        throw json_encode(a:promise_or_fn._result)
      endif

      if l:timeout != -1 && reltimefloat(reltime(l:reltime)) * 1000 > l:timeout
        throw 'candle#sync: timeout'
      endif

      sleep 1m
    endwhile
  endif
endfunction

"
" candle#log
"
function! candle#log(...) abort
  if strlen(get(g:candle, 'debug', '')) > 0
    call writefile([join([strftime('%H:%M:%S')] + a:000, "\t")], '/tmp/candle.log', 'a')
  endif
endfunction

"
" candle#echo
"
function! candle#echo(...) abort
  for l:msg in a:000
    let l:msg = type(l:msg) != type('') ? string(l:msg) : l:msg
    let l:msg = substitute(l:msg, "\r\n", "\n", 'g')
    let l:msg = substitute(l:msg, "\r", "\n", 'g')
    for l:line in split(string(l:msg), "\n")
      echomsg l:line
    endfor
    echomsg ' '
  endfor
endfunction

"
" candle#on_exception
"
function! candle#on_exception() abort
  if strlen(get(g:candle, 'debug', '')) > 0
    call candle#echo({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  else
    call candle#echo(v:exception)
  endif
endfunction

"
" candle#yesno
"
function! candle#yesno(prompt) abort
  let l:prompt = type(a:prompt) == type([]) ? join(a:prompt, "\n") : a:prompt
  if index(['y', 'ye', 'yes'], input(l:prompt . "\ny[es]: ")) >= 0
    echo "\n"
    return v:true
  endif
    echo "\n"
  return v:false
endfunction

"
" context
"
function! s:context(args) abort
  let s:state.session_id += 1

  let a:args.maxwidth = get(a:args, 'maxwidth', float2nr(&columns * 0.8))
  let a:args.maxheight = get(a:args, 'maxheight', float2nr(&lines * 0.2))
  let a:args.layout = get(a:args, 'layout', 'split')
  let a:args.filter = get(a:args, 'filter', 'substring')
  let a:args.start_input = get(a:args, 'start_input', v:false)

  let l:context = {}
  let l:context.bufname = printf('candle-%s', s:state.session_id)
  let l:context.option = copy(a:args)
  let l:context.source = s:Source.new(
        \   s:Server.new(),
        \   s:state.sources[a:args.source].create(a:args.params)
        \ )

  return l:context
endfunction

