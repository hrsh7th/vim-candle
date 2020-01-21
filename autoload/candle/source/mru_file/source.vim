let s:dirname = expand('<sfile>:p:h')

let g:candle#source#mru_file#filepath = expand('~/.candle_mru_file')

let s:state = {
      \   'recent': '',
      \ }

"
" candle#source#mru_file#source#definition
"
function! candle#source#mru_file#source#definition() abort
  return {
        \   'name': 'mru_file',
        \   'script': s:dirname . '/source.go',
        \   'get_options': { -> s:get_options() }
        \ }
endfunction

"
" get_options
"
function! s:get_options() abort
  return [{
        \   'name': '--filepath',
        \   'description': '',
        \   'extra': {
        \     'default': g:candle#source#mru_file#filepath
        \   }
        \ }]
endfunction

augroup candle#source#mru_file#source
  autocmd!
  autocmd BufWinEnter * call <SID>on_buf_win_enter()
augroup END

"
" on_buf_enter
"
function! s:on_buf_win_enter() abort
  if empty(g:candle#source#mru_file#filepath)
    return
  endif

  let l:filepath = fnamemodify(bufname('%'), ':p')
  if s:state.recent == l:filepath
    return
  endif

  if !filereadable(l:filepath)
    return
  endif

  call writefile([l:filepath], g:candle#source#mru_file#filepath, 'a')
  let s:state.recent = l:filepath
endfunction

