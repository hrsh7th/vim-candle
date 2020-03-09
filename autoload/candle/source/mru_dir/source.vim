let g:candle#source#mru_dir#filepath = expand('~/.candle_mru_dir')
let g:candle#source#mru_dir#markers = ['.git', '.svn', 'package.json', 'tsconfig.json', 'go.mod']

let s:dirname = expand('<sfile>:p:h')
"
" candle#source#mru_dir#source#definition
"
function! candle#source#mru_dir#source#definition() abort
  return {
        \   'name': 'mru_dir',
        \   'create': function('s:create', ['mru_dir'])
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
  \       'filepath': get(a:args, 'filepath', g:candle#source#mru_dir#filepath),
  \       'ignore_patterns': get(a:args, 'ignore_patterns', []),
  \     }
  \   },
  \   'action': {
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

  let l:filenames = map(a:candle.get_action_items(), { _, item -> item.filename })
  let l:lines = readfile(a:candle.source.script.args.filepath)
  let l:lines = filter(l:lines, { _, line -> index(l:filenames, line) == -1 })
  call writefile(l:lines, a:candle.source.script.args.filepath)

  call a:candle.start()
endfunction

"
" events.
"
augroup candle#source#mru_dir#source
  autocmd!
  autocmd BufWinEnter,BufEnter,BufRead,BufNewFile * call <SID>on_touch()
augroup END

"
" on_touch
"
function! s:on_touch() abort
  if empty(g:candle#source#mru_dir#filepath)
    return
  endif
  if &buftype !=# ''
    return
  endif

  let l:path = fnamemodify(bufname('%'), ':p')

  let l:root = s:detect_root(l:path)

  " add mru entry
  if l:root !=# ''
    call writefile([substitute(l:root, '\/$', '', 'g')], g:candle#source#mru_dir#filepath, 'a')
  endif
endfunction

"
" s:detect_root
"
function! s:detect_root(path) abort
  if !filereadable(a:path)
    return ''
  endif

  for l:marker in g:candle#source#mru_dir#markers
    let l:path = fnamemodify(a:path, ':p')
    while v:true
      let l:candidate = resolve(l:path . '/' . l:marker)
      if filereadable(l:candidate) || isdirectory(l:candidate)
        return l:path
      endif
      let l:up = fnamemodify(l:path, ':h')
      if l:path ==# l:up
        break
      endif
      let l:path = l:up
    endwhile
  endfor
  return ''
endfunction

