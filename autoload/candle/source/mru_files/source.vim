let s:dirname = expand('<sfile>:p:h')

let g:candle#source#mru_files#filepath = expand('~/.candle_mru_files')

"
" candle#source#mru_files#source#definition
"
function! candle#source#mru_files#source#definition() abort
  return {
        \   'name': 'mru_files',
        \   'create': function('s:create', ['mru_files'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'filepath': get(a:args, 'filepath', g:candle#source#mru_files#filepath),
  \       'ignore_patterns': get(a:args, 'ignore_patterns', []),
  \     }
  \   },
  \   'actions': {
  \     'default': 'edit'
  \   }
  \ }
endfunction


let s:state = {
      \   'recent': '',
      \ }

"
" events.
"
augroup candle#source#mru_files#source
  autocmd!
  autocmd BufWinEnter,BufRead,BufNewFile * call <SID>on_touch()
augroup END

"
" on_touch
"
function! s:on_touch() abort
  if empty(g:candle#source#mru_files#filepath)
    return
  endif
  if &buftype !=# ''
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
  call writefile([l:filepath], g:candle#source#mru_files#filepath, 'a')
  let s:state.recent = l:filepath
endfunction

