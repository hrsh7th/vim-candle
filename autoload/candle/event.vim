let s:event_map = {}

let s:managed_event_names = ['WinClosed', 'BufDelete']

let s:initialized = v:false

"
" candle#event#attach
"
function! candle#event#attach(name, func, ...) abort
  call s:initialize()

  let s:event_map[a:name] = get(s:event_map, a:name, [])

  if len(s:event_map[a:name]) == 0 && index(s:managed_event_names, a:name) == -1
    execute printf('augroup candle#event_%s', a:name)
      execute printf('autocmd! %s * call <SNR>%d_dispatch(''%s'')', a:name, s:SID(), a:name)
    augroup END
  endif

  call add(s:event_map[a:name], extend({
  \   'winid': win_getid(),
  \   'bufnr': bufnr('%'),
  \   'func': a:func,
  \ }, get(a:000, 0, {})))
endfunction

"
" candle#event#clean
"
function! candle#event#clean(bufnr) abort
  for [l:name, l:contexts] in items(s:event_map)
    let l:index = len(l:contexts) - 1
    while l:index >= 0
      if l:contexts[l:index].bufnr == a:bufnr
        call remove(l:contexts, l:index)
      endif
      let l:index -= 1
    endwhile
  endfor
endfunction

"
" dispatch
"
function! s:dispatch(name) abort
  let l:contexts = get(s:event_map, a:name, [])

  try
    let l:bufnr = bufnr('%')
    let l:i = 0
    while l:i < len(l:contexts)
      if l:contexts[l:i].bufnr == l:bufnr
        call l:contexts[l:i].func()
      endif
      let l:i += 1
    endwhile
  catch /.*/
    call candle#on_exception()
  endtry
endfunction

"
" s:initialize
"
function! s:initialize() abort
  if s:initialized
    return
  endif
  let s:initialized = v:true

  augroup candle#event:managed_events
    autocmd!
    autocmd BufLeave * call s:on_win_closed()
    autocmd BufDelete * call s:on_buf_delete()
  augroup END
endfunction

"
" on_win_closed
"
function! s:on_win_closed() abort
  for l:context in get(s:event_map, 'WinClosed', [])
    if win_id2tabwin(l:context.winid) == [0, 0]
      call l:context.func()
    endif
  endfor
endfunction

"
" on_buf_delete
"
function! s:on_buf_delete() abort
  let l:bufnr = expand('<abuf>')
  for l:context in get(s:event_map, 'BufDelete', [])
    if l:context.bufnr == l:bufnr
      call l:context.func()
    endif
  endfor
endfunction

"
" SID
"
function! s:SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction
