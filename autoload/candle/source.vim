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
" get_highlights
"
function! s:Source.get_highlights() abort
  return self.source.get_highlights()
endfunction

"
" fetch
"
function! s:Source.fetch(params) abort
  return self.server.request('fetch', {
        \   'id': self.id,
        \   'query': a:params.query,
        \   'index': a:params.index,
        \   'count': a:params.count
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

