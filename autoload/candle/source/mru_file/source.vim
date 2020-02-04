let g:candle#source#mru_file#filepath = expand('~/.candle_mru_file')

let s:dirname = expand('<sfile>:p:h')
let s:state = {}
let s:state.recent = ''

"
" candle#source#mru_file#source#definition
"
function! candle#source#mru_file#source#definition() abort
  return {
        \   'name': 'mru_file',
        \   'create': function('s:create', ['mru_file'])
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
  \       'filepath': get(a:args, 'filepath', g:candle#source#mru_file#filepath),
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
  call writefile([l:filepath], g:candle#source#mru_file#filepath, 'a')
  let s:state.recent = l:filepath
endfunction

