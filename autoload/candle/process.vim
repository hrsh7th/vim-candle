let s:Server = candle#server#import()

let s:process_id = 0

"
" candle#process#import
"
function! candle#process#import() abort
  return s:Process
endfunction

let s:Process = {}

"
" new
"
function! s:Process.new(source) abort
  let s:process_id += 1
  return extend(deepcopy(s:Process), {
        \   'id': string(s:process_id),
        \   'source': a:source,
        \   'server': s:Server.new(),
        \   'on_notification': { -> {} },
        \ })
endfunction

"
" start
"
function! s:Process.start() abort
  call self.server.start({ notification -> self.callback(notification) })
  return self.server.request('start', {
        \   'id': self.id,
        \   'script': self.source.script,
        \   'params': self.source.params
        \ })
endfunction

"
" fetch
"
function! s:Process.fetch(params) abort
  return self.server.request('fetch', extend(a:params, {
        \   'id': self.id
        \ }))
endfunction

"
" attach
"
function! s:Process.attach(on_notification) abort
  let self.on_notification = a:on_notification
endfunction

"
" detach
"
function! s:Process.detach() abort
  let self.on_notification = { -> {} }
endfunction

