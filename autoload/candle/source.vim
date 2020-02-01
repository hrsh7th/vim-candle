let s:Server = candle#server#import()

"
" candle#process#import
"
function! candle#source#import() abort
  return s:Source
endfunction

let s:Source = {}

"
" new
"
function! s:Source.new(server, source) abort
  return extend(deepcopy(s:Source), {
        \   'server': a:server,
        \   'source': a:source,
        \ })
endfunction

"
" start
"
function! s:Source.start(callback) abort
  let self.callback = a:callback
  call self.server.start({ notification ->
  \   self.on_notification(notification)
  \ })
  return self.server.request('start', {
  \   'path': self.source.script.path,
  \   'args': self.source.script.args,
  \ })
endfunction

"
" stop
"
function! s:Source.stop() abort
  call self.server.stop()
endfunction

"
" action
"
function! s:Source.action(name, candle) abort
  let l:config = get(g:candle.source, self.source.name, {})

  " override by global-config.
  if !empty(l:config) && has_key(l:config, 'action') && has_key(l:config.action, a:name)

    " Redirect action.
    if type(l:config.action[a:name]) == type('')
      let l:Action = get(self.source.actions, a:name, {})

    " Function action.
    elseif type(l:config.action[a:name]) == type({ -> {} })
      let l:Action = l:config.action[a:name]
    endif
  else
    " Source action.
    let l:Action = get(self.source.actions, a:name, {})
  endif

  if type(l:Action) != type({ -> {} })
    throw printf('No such action: `%s`', a:name)
  endif

  let l:after = l:Action(a:candle)
  return type(l:after) != type({}) ? {} : l:after
endfunction

"
" fetch
"
function! s:Source.fetch(args) abort
  return self.server.request('fetch', {
  \   'query': a:args.query,
  \   'index': a:args.index,
  \   'count': a:args.count
  \ })
endfunction

"
" attach
"
function! s:Source.attach(callback) abort
  let self.callback = a:callback
endfunction

"
" detach
"
function! s:Source.detach() abort
  let self.callback = { -> {} }
endfunction

"
" on_notification
"
function! s:Source.on_notification(notification) abort
  call self.callback(a:notification)
endfunction

