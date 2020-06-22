let s:recent = v:null

function! candle#mapping#toggle() abort
  if !empty(s:recent) && s:recent.is_alive()
    if s:recent.is_visible()
      call s:recent.close()
    else
      call s:recent.open()
    endif
  endif
  return ''
endfunction

function! candle#mapping#open() abort
  if has_key(b:, 'candle')
    call b:candle.open()
  endif
  return ''
endfunction

function! candle#mapping#close() abort
  if has_key(b:, 'candle')
    call b:candle.close()
  endif
  return ''
endfunction

function! candle#mapping#restart() abort
  if has_key(b:, 'candle')
    call b:candle.start()
  endif
  return ''
endfunction

function! candle#mapping#cursor_move(offset) abort
  if has_key(b:, 'candle')
    call b:candle.move_cursor(a:offset)
  endif
  return ''
endfunction

function! candle#mapping#cursor_top() abort
  if has_key(b:, 'candle')
    call b:candle.top()
  endif
  return ''
endfunction

function! candle#mapping#cursor_bottom() abort
  if has_key(b:, 'candle')
    call b:candle.bottom()
  endif
  return ''
endfunction

function! candle#mapping#toggle_select() abort
  if has_key(b:, 'candle')
    call b:candle.toggle_select()
  endif
  return ''
endfunction

function! candle#mapping#toggle_select_all() abort
  if has_key(b:, 'candle')
    call b:candle.toggle_select_all()
  endif
  return ''
endfunction

function! candle#mapping#choose_action() abort
  if has_key(b:, 'candle')
    call b:candle.choose_action()
  endif
  return ''
endfunction

function! candle#mapping#action(name) abort
  if has_key(b:, 'candle')
    call b:candle.action(a:name)
  endif
  return ''
endfunction

function! candle#mapping#action_next(name) abort
  if !empty(s:recent) && s:recent.is_alive()
    call s:recent.move_cursor(+1)
    call s:recent.action(a:name)
  endif
endfunction

function! candle#mapping#action_prev(name) abort
  if !empty(s:recent) && s:recent.is_alive()
    call s:recent.move_cursor(-1)
    call s:recent.action(a:name)
  endif
endfunction

function! candle#mapping#input_open() abort
  if has_key(b:, 'candle')
    call candle#render#input#open(b:candle)
  endif
  return ''
endfunction

function! candle#mapping#init() abort
  augroup candle#mapping
    autocmd!
    autocmd BufEnter * call s:on_buf_enter()
  augroup END
endfunction

"
" on_buf_enter
"
function! s:on_buf_enter() abort
  if getbufvar('%', 'candle', v:null) isnot# v:null
    let s:recent = b:candle
  endif
endfunction

