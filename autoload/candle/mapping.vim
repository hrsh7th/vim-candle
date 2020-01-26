function! candle#mapping#cursor_up() abort
  if has_key(b:, 'candle')
    call b:candle.up()
  endif
endfunction

function! candle#mapping#cursor_down() abort
  if has_key(b:, 'candle')
    call b:candle.down()
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

function! candle#mapping#action(name) abort
  if has_key(b:, 'candle')
    call b:candle.action(a:name)
  endif
endfunction

function! candle#mapping#input_open() abort
  call candle#render#input#open(b:candle)
endfunction

function! candle#mapping#input_close() abort
  if has_key(b:, 'candle')
  endif
endfunction

