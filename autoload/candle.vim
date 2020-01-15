let s:Promise = vital#candle#import('Async.Promise')
let s:Process = candle#process#import()

let s:root = expand('<sfile>:p:h:h')

call s:Promise.on_unhandled_rejection({ err -> candle#log('[ERROR]', err) })

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
" candle#initialize
"
function! candle#start(source) abort
  let l:context = {}
  let l:context.bufnr = bufnr('aiueo', v:true)
  let l:context.process = s:Process.new(a:source)
  call timer_start(0, { -> candle#buffer#render(l:context) }, { 'repeat': 1 })
endfunction

"
" candle#root
"
function! candle#root() abort
  return s:root
endfunction

"
" candle#log
"
function! candle#log(...) abort
  call writefile([join([strftime('%H:%M:%S')] + a:000, "\t")], '/tmp/candle.log', 'a')
endfunction

