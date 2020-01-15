let s:Promise = vital#candle#import('Async.Promise')

"
" candle#buffer#render
"
function! candle#buffer#render(context) abort
  " show buffer
  execute printf('%sbuffer', a:context.bufnr)

  " add events
  execute printf('augroup candle#buffer:%s', a:context.bufnr)
    autocmd! BufWinEnter <buffer> call s:on_buf_win_enter()
    autocmd! BufWinLeave <buffer> call s:on_buf_win_leave()
  augroup END

  " add mappings
  nnoremap <buffer> k :<C-u>call <SID>on_k()<CR>
  nnoremap <buffer> j :<C-u>call <SID>on_j()<CR>

  " add context
  let b:candle = {}
  let b:candle.index = 0
  let b:candle.cursor = 1
  let b:candle.process = a:context.process

  call a:context.process.start()
  call s:on_buf_win_enter()
endfunction

"
" on_buf_win_enter
"
function! s:on_buf_win_enter() abort
  let l:bufnr = bufnr('%')
  call b:candle.process.attach({ notification ->
        \   s:refresh({
        \     'bufnr': l:bufnr,
        \     'sync': v:false,
        \     'notification': notification,
        \   })
        \ })
endfunction

"
" on_buf_win_leave
"
function! s:on_buf_win_leave() abort
  call b:candle.process.detach()
endfunction

"
" on_k
"
function! s:on_k() abort
  if 1 == line('.')
    let b:candle.index = max([1, b:candle.index - 1])
    call s:refresh({ 'bufnr': bufnr('%'), 'sync': v:true })
  else
    normal! k
    let b:candle.cursor = line('.')
  endif
  call s:refresh({ 'bufnr': bufnr('%'), 'sync': v:true })
endfunction

"
" on_j
"
function! s:on_j() abort
  let l:max = min([winheight(0), line('$')])
  if l:max == line('.')
    let b:candle.index = min([l:max, b:candle.index + 1])
    call s:refresh({ 'bufnr': bufnr('%'), 'sync': v:true })
  else
    normal! j
    let b:candle.cursor = line('.')
  endif
endfunction

"
" refresh
"
function! s:refresh(option) abort
  let l:candle = getbufvar(a:option.bufnr, 'candle')
  let l:p = s:Promise.resolve()
  let l:p = l:p.then({ ->
        \   l:candle.process.fetch({
        \     'index': l:candle.index,
        \     'count': winheight(bufwinnr(a:option.bufnr))
        \   })
        \ })
  let l:p = l:p.then({ response -> s:on_response(a:option.bufnr, response) })

  if get(a:option, 'sync', v:false)
    call candle#sync(l:p)
  endif
endfunction

"
" on_response
"
function! s:on_response(bufnr, response) abort
  call setbufvar(a:bufnr, '&modifiable', 1)
  call setbufvar(a:bufnr, '&modified', 1)
  let l:items = a:response.items[0 : winheight(winbufnr(a:bufnr))]
  let b:candle.items = l:items
  call setbufline(a:bufnr, 1, map(copy(l:items), { _, item -> item.title }))
  call setbufvar(a:bufnr, '&modifiable', 0)
  call setbufvar(a:bufnr, '&modified', 0)
endfunction

