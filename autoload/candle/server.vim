let s:JSON = vital#candle#import('VS.RPC.JSON')

"
" candle#server#import
"
function! candle#server#import() abort
  return s:Server
endfunction

let s:Server = {}

"
" new
"
function! s:Server.new(args) abort
  let l:server = extend(deepcopy(s:Server), {
  \   'connection': s:JSON.new({
  \     'command': a:args.command,
  \   }),
  \   'request_id': 0,
  \ })
  let l:server.emitter = l:server.connection.emitter
  return l:server
endfunction

"
" start
"
function! s:Server.start() abort
  return self.connection.start()
endfunction

"
" request
"
function! s:Server.request(method, params) abort
  return self.connection.request(self.id(), a:method, a:params)
endfunction

"
" id
"
function! s:Server.id() abort
  let self.request_id += 1
  return self.request_id
endfunction

