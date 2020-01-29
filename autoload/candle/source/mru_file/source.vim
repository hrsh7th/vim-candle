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
        \   'get_script_params': { params -> s:get_script_params(params) },
        \   'get_actions': { -> s:get_actions() },
        \ }
endfunction

"
" get_script_params
"
function! s:get_script_params(params) abort
  return {
  \   'filepath': get(a:params, 'filepath', g:candle#source#mru_file#filepath),
  \   'ignore_patterns': get(a:params, 'ignore_patterns', []),
  \ }
endfunction

"
" get_actions
"
function! s:get_actions() abort
  let l:actions = {}
  let l:actions = extend(l:actions, candle#action#location#get())
  let l:actions.default = l:actions.edit
  return l:actions
endfunction

"
" events.
"
augroup candle#source#mru_file#source
  autocmd!
  autocmd BufWinEnter,BufRead,BufNewFile * call <SID>on_touch()
augroup END

"
" on_touch
"
function! s:on_touch() abort
  if empty(g:candle#source#mru_file#filepath)
    return
  endif

  let l:filepath = fnamemodify(bufname('%'), ':p')

  " skip same to recently added
  if s:state.recent == l:filepath
    return
  endif

  " skip not file
  if !filereadable(l:filepath)
    return
  endif

  " add mru entry
  call writefile([l:filepath], g:candle#source#mru_file#filepath, 'a')
  let s:state.recent = l:filepath
endfunction

