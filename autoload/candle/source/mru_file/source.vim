let g:candle#source#mru_file#filepath = expand('~/.candle_mru_file')

let s:dirname = expand('<sfile>:p:h')

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
" candle#source#mru_file#source#touch
"
function! candle#source#mru_file#source#touch(path) abort
  call s:on_touch(a:path, v:true)
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
augroup candle#source#mru_file#source
  autocmd!
  autocmd BufWinEnter,BufEnter,BufRead,BufNewFile * call <SID>on_touch(bufname('%'))
augroup END

"
" on_touch
"
function! s:on_touch(path, ...) abort
  let l:force = get(a:000, 0, v:false)

  if empty(g:candle#source#mru_file#filepath)
    return
  endif

  if &buftype !=# '' && !l:force
    return
  endif

  let l:filepath = fnamemodify(a:path, ':p')

  " skip not file
  if !filereadable(l:filepath)
    return
  endif

  " add mru entry
  call writefile([l:filepath], g:candle#source#mru_file#filepath, 'a')
endfunction

