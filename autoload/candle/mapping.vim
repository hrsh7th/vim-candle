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
      quit
      call win_gotoid(l:candle.state.winid)
    endif
  endif
endfunction

