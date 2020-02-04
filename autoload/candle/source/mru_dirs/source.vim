let g:candle#source#mru_dirs#filepath = expand('~/.candle_mru_dirs')
let g:candle#source#mru_dirs#markers = ['.git', '.svn', 'package.json', 'tsconfig.json', 'go.mod']

let s:dirname = expand('<sfile>:p:h')
let s:state = {}
let s:state.recent = ''

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
  \     'default': 'edit',
  \     'delete': function('s:action_delete'),
  \   }
  \ }
endfunction

"
" action_delete
"
function! s:action_delete(candle) abort
  let l:msgs = ['Following mru entry will be removed.']
  for l:item in a:candle.get_action_items()
    let l:msgs += [printf('  %s', l:item.title)]
  endfor

  if !candle#yesno(l:msgs)
    throw 'Cancel.'
  endif

  let l:paths = map(a:candle.get_action_items(), { _, item -> fnamemodify(item.title, ':p') })
  let l:lines = readfile(a:candle.source.script.args.filepath)
  let l:lines = filter(l:lines, { _, line -> index(l:paths, line) == -1 })
  call writefile(l:lines, a:candle.source.script.args.filepath)

  call a:candle.start()
endfunction

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
    call writefile([substitute(l:root, '\/$', '', 'g')], g:candle#source#mru_dirs#filepath, 'a')
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

