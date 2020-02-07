let s:Promise = vital#candle#import('Async.Promise')
let s:Server = candle#server#import()
let s:Context = candle#context#import()

let s:root_dir = expand('<sfile>:p:h:h')

let s:state = {
\   'version': '',
\   'context_id': -1,
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
function! candle#start(source, ...) abort
  let l:option = get(a:000, 0, {})
  try
    call candle#log('')
    call candle#log('[START]', string({ 'source': a:source, 'option': l:option }))
    call s:Context.new(s:context(a:source, l:option)).start()
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
" candle#sync
"
function! candle#sync(promise_or_fn, ...) abort
  let l:timeout = get(a:000, 0, lamp#config('global.timeout'))
  let l:reltime = reltime()

  if type(a:promise_or_fn) == v:t_func
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
      echomsg '[CANDLE] ' . l:line
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
  if index(['y', 'ye', 'yes'], input(l:prompt . "\n" . 'yes/no > ')) >= 0
    echo "\n"
    return v:true
  endif
    echo "\n"
  return v:false
endfunction

"
" context
"
function! s:context(source, option) abort
  let s:state.context_id += 1

  let l:context = {}
  let l:context.bufname = printf('candle-%s', s:state.context_id)
  let l:context.option = extend({
  \   'layout': 'split',
  \   'filter': 'substring',
  \   'start_input': v:false,
  \   'maxwidth': float2nr(&columns * 0.2),
  \   'maxheight': float2nr(&lines * 0.2),
  \   'close_on': 'WinClosed',
  \   'action': {},
  \ }, a:option)
  let l:context.server = s:Server.new()
  let l:context.source = s:source(a:source)

  return l:context
endfunction

"
" source
"
function! s:source(source) abort
  let  [l:source, l:params] = items(a:source)[0]

  let l:source = s:state.sources[l:source].create(l:params)

  if !has_key(l:source, 'name')
    throw '`name` is requried.'
  endif

  if !has_key(l:source, 'script')
    throw '`script` is requried.'
  endif

  if !has_key(l:source.script, 'path')
    throw '`script.path` is requried.'
  endif

  if !has_key(l:source.script, 'args')
    throw '`script.args` is requried.'
  endif

  return l:source
endfunction

