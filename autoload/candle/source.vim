let s:Server = candle#server#import()

let s:source_id = 0

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
function! s:Source.new(server, source, params) abort
  let s:source_id += 1
  return extend(deepcopy(s:Source), {
        \   'id': string(s:source_id),
        \   'name': a:source.name,
        \   'source': a:source,
        \   'params': a:params,
        \   'server': a:server,
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
  \   'id': self.id,
  \   'script': self.source.script,
  \   'params': self.params,
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
  if !empty(l:config) && has_key(l:config, 'action') && has_key(l:config.action, a:name)
    if type(l:config.action[a:name]) == type('')
      let l:Action = get(self.source.get_actions(), a:name, {})
    elseif type(l:config.action[a:name]) == type({ -> {} })
      let l:Action = l:config.action[a:name]
    endif
  else
    let l:Action = get(self.source.get_actions(), a:name, {})
  endif

  if empty(l:Action)
    throw printf('No such action: `%s`', a:name)
  endif

  let l:after = l:Action(a:candle)
  return empty(l:after) ? {} : l:after
endfunction

"
" fetch
"
function! s:Source.fetch(args) abort
  return self.server.request('fetch', {
  \   'id': self.id,
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
  if self.id == a:notification.params.id
    call self.callback(a:notification)
  endif
endfunction

