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
  \   'cmd': a:args.command,
  \   'rpc': s:JSON.new(),
  \   'request_id': 0,
  \ })
  let l:server.events = l:server.rpc.events
  return l:server
endfunction

"
" start
"
function! s:Server.start() abort
  return self.rpc.start({
  \   'cmd': self.cmd,
  \ })
endfunction

"
" request
"
function! s:Server.request(method, params) abort
  return self.rpc.request(self.id(), a:method, a:params)
endfunction

"
" id
"
function! s:Server.id() abort
  let self.request_id += 1
  return self.request_id
endfunction

