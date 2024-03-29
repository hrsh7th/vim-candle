let s:Promise = vital#candle#import('Async.Promise')
let s:Context = candle#context#import()
let s:Server = candle#server#import()

let s:root_dir = expand('<sfile>:p:h:h')

let s:debounce_ids = {}
let s:throttle_ids = {}

let s:state = {
\   'version': '',
\   'context_id': -1,
\   'sources': {},
\   'server': v:null
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
  if !has_key(l:option, 'parent') && has_key(b:, 'candle')
    let l:option.parent = b:candle
  endif
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
  let l:timeout = get(a:000, 0, 1000)
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
      echomsg printf('[CANDLE] %s', substitute(l:msg, "^'\|'$", '', 'g'))
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
" candle#debounce
"
function! candle#debounce(id, fn, timeout) abort
  if has_key(s:debounce_ids, a:id)
    call timer_stop(s:debounce_ids[a:id])
  endif

  let l:ctx = {}
  let l:ctx.id = a:id
  let l:ctx.fn = a:fn
  function! l:ctx.callback() abort
    unlet s:debounce_ids[self.id]
    try
      call self.fn()
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
  endfunction
  let s:debounce_ids[a:id] = timer_start(a:timeout, { -> l:ctx.callback() })
endfunction

"
" candle#throttle
"
function! candle#throttle(id, fn, timeout) abort
  let l:timeout = a:timeout
  if has_key(s:throttle_ids, a:id)
    let s:throttle_ids[a:id].callback = a:fn
    return
  endif

  let l:ctx = {}
  let l:ctx.id = a:id
  function! l:ctx.callback() abort
    try
      call s:throttle_ids[self.id].fn()
    catch /.*/
      echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
    endtry
    unlet s:throttle_ids[self.id]
  endfunction

  let s:throttle_ids[a:id] = {
  \   'time': reltimefloat(reltime()) * 1000,
  \   'fn': a:fn,
  \   'timer_id': timer_start(l:timeout, { -> l:ctx.callback() })
  \ }
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
  let l:context.option = extend(a:option, g:candle.option, 'keep')
  let l:context.server = s:server()
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

"
" server
"
function! s:server() abort
  try
    if !empty(s:state.server)
      return s:state.server
    endif
    let s:state.server = s:Server.new({ 'command': s:command() })
    call s:state.server.rpc().on_stderr({ err -> candle#log('[ERROR]', err) })
    call s:state.server.rpc().on_notification('start', { params -> s:on_notification({ 'method': 'start', 'params': params }) })
    call s:state.server.rpc().on_notification('progress', { params -> s:on_notification({ 'method': 'progress', 'params': params }) })
    call s:state.server.rpc().on_notification('done', { params -> s:on_notification({ 'method': 'done', 'params': params }) })
    call s:state.server.start()
    return s:state.server
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
endfunction

"
" on_notification
"
function! s:on_notification(notification) abort
  if has_key(a:notification.params, 'id')
    let l:candle = getbufvar(a:notification.params.id, 'candle', {})
    if !empty(l:candle)
      call l:candle.on_notification(a:notification)
    endif
  endif
endfunction
"
" command
"
function! s:command() abort
  " Manual built binary.
  if filereadable(printf('%s/bin/candle-server/candle-server', s:root_dir))
    return [printf('%s/bin/candle-server/candle-server', s:root_dir)]
  endif

  call candle#install#do()

  return [candle#install#get_binary_path()]
endfunction

