let s:dirname = expand('<sfile>:p:h')

let g:candle#source#mru_dirs#filepath = expand('~/.candle_mru_dirs')
let g:candle#source#mru_dirs#markers = ['.git', '.svn', 'autoload', 'package.json', 'tsconfig.json', 'go.mod']

"
" candle#source#mru_dirs#source#definition
"
function! candle#source#mru_dirs#source#definition() abort
  return {
        \   'name': 'mru_dirs',
        \   'create': function('s:create', ['mru_dirs'])
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
  \       'filepath': get(a:args, 'filepath', g:candle#source#mru_dirs#filepath),
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
augroup candle#source#mru_dirs#source
  autocmd!
  autocmd BufWinEnter,BufEnter,BufRead,BufNewFile * call <SID>on_touch()
augroup END

"
" on_touch
"
function! s:on_touch() abort
  if empty(g:candle#source#mru_dirs#filepath)
    return
  endif
  if &buftype !=# ''
    return
  endif

  let l:path = fnamemodify(bufname('%'), ':p')

  " skip same to recently added
  if s:state.recent == l:path
    return
  endif

  let l:root = s:detect_root(l:path)

  " add mru entry
  if l:root !=# ''
    call writefile([l:root], g:candle#source#mru_dirs#filepath, 'a')
  endif
  let s:state.recent = l:path
endfunction

"
" s:detect_root
"
function! s:detect_root(path) abort
  let l:path = fnamemodify(a:path, ':p')
  while l:path !=# '' && l:path !=# '/'
    for l:marker in g:candle#source#mru_dirs#markers
      let l:candidate = resolve(l:path . '/' . l:marker)
      if filereadable(l:candidate) || isdirectory(l:candidate)
        return l:path
      endif
    endfor
    let l:path = substitute(l:path, '/[^/]*$', '', 'g')
  endwhile
  return ''
endfunction

