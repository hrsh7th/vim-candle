let s:Connection = vital#candle#import('VS.RPC.JSON.Connection')

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
  \   'rpc': s:Connection.new(),
  \ })
  return l:server
endfunction

"
" start
"
function! s:Server.start() abort
  call self.rpc.start({ 'cmd': self.cmd })
endfunction

"
" request
"
function! s:Server.request(method, params) abort
  return self.rpc.request(a:method, a:params)
endfunction

