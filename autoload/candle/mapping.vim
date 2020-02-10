function! candle#mapping#restart() abort
  if has_key(b:, 'candle')
    call b:candle.start()
  endif
endfunction

function! candle#mapping#cursor_move(offset) abort
  if has_key(b:, 'candle')
    call b:candle.move_cursor(a:offset)
  endif
endfunction

function! candle#mapping#cursor_top() abort
  if has_key(b:, 'candle')
    call b:candle.top()
  endif
endfunction

function! candle#mapping#cursor_bottom() abort
  if has_key(b:, 'candle')
    call b:candle.bottom()
  endif
endfunction

function! candle#mapping#toggle_select() abort
  if has_key(b:, 'candle')
    call b:candle.toggle_select()
  endif
endfunction

function! candle#mapping#toggle_select_all() abort
  if has_key(b:, 'candle')
    call b:candle.toggle_select_all()
  endif
endfunction

function! candle#mapping#choose_action() abort
  if has_key(b:, 'candle')
    call b:candle.choose_action()
  endif
endfunction

function! candle#mapping#action(name) abort
  if has_key(b:, 'candle')
    call b:candle.action(a:name)
  endif
endfunction

function! candle#mapping#input_open() abort
  if has_key(b:, 'candle')
    call candle#render#input#open(b:candle)
  endif
endfunction

function! candle#mapping#input_close() abort
  if has_key(b:, 'candle')
    let l:candle = b:candle
    if &filetype ==# 'candle.input'
      stopinsert
      quit
      call win_gotoid(l:candle.winid)
    endif
  endif
endfunction

