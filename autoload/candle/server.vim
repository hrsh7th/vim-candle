let s:Promise = vital#candle#import('Async.Promise')
let s:Channel = candle#server#channel#import()

let s:root_dir= expand('<sfile>:p:h:h:h')

"
" candle#server#import
"
function! candle#server#import() abort
  return s:Server
endfunction

"
" s:Server
"
let s:Server = {
      \   'started': v:false
      \ }

"
" new
"
function! s:Server.new() abort
  return extend(deepcopy(s:Server), {
        \   'started': v:false,
        \   'channel': s:Channel.new({ 'command': s:command() }),
        \   'on_notification': { -> {} }
        \ })
endfunction

"
" start
"
function! s:Server.start(on_notification) abort
  if self.started
    return
  endif
  let self.started = v:true

  call self.channel.start({ notification -> a:on_notification(notification) })
endfunction

"
" stop
"
function! s:Server.stop() abort
  call self.channel.stop()
endfunction

"
" request
"
function! s:Server.request(method, params) abort
  return self.channel.request(a:method, a:params)
endfunction

"
" response
"
function! s:Server.response(id, params) abort
  call self.channel.response(a:id, a:params)
endfunction

"
" notify
"
function! s:Server.notify(method, params) abort
  call self.channel.notify(a:method, a:params)
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

