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

function! candle#mapping#input_open() abort
  if has_key(b:, 'candle')
    call candle#render#input#open(b:candle)
  endif
  return ''
endfunction

