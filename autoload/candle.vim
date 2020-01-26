let s:Promise = vital#candle#import('Async.Promise')
let s:OptionParser = vital#candle#import('OptionParser')
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
" candle#get_source
"
function! candle#get_source(name) abort
  return get(s:state.sources, a:name, {})
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
" candle#get_option_parser
"
function! candle#get_option_parser() abort
  let s:parser = s:OptionParser.new()
  call s:parser.on('--source=VALUE', '', {
  \   'required': 1,
  \   'completion': { -> keys(s:state.sources) }
  \ })
  call s:parser.on('--layout', '', {
  \   'completion': { -> ['floating', 'split', 'vsplit'] }
  \ })
  call s:parser.on('--filter', '', {
  \   'completion': { -> ['fuzzy', 'substring', 'regexp'] }
  \ })
  call s:parser.on('--maxwidth', '', {})
  call s:parser.on('--maxheight', '', {})
  return s:parser
endfunction

"
" context
"
function! s:context(args) abort
  let s:state.id += 1

  let a:args.maxwidth = get(a:args, 'maxwidth', float2nr(&columns * 0.8))
  let a:args.maxheight = get(a:args, 'maxheight', float2nr(&lines * 0.2))
  let a:args.layout = get(a:args, 'layout', 'split')
  let a:args.filter = get(a:args, 'filter', 'substring')

  let l:source = s:state.sources[a:args.source]
  if has_key(l:source, 'on_before_start')
    call l:source.on_before_start(a:args)
  endif

  let l:context = copy(a:args)
  let l:context.bufname = printf('candle-%s', s:state.id)
  let l:context.source = s:Source.new(
        \   s:Server.new(),
        \   s:state.sources[a:args.source],
        \   a:args
        \ )

  return l:context
endfunction

