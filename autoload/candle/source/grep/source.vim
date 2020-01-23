let s:dirname = expand('<sfile>:p:h')

"
" candle#source#grep#source#definition
"
function! candle#source#grep#source#definition() abort
  return {
        \   'name': 'grep',
        \   'script': s:dirname . '/source.go',
        \   'on_before_start': { args -> s:on_before_start(args) },
        \   'get_options': { -> s:get_options() },
        \   'get_actions': { -> s:get_actions() },
        \ }
endfunction

"
" on_before_start
"
function! s:on_before_start(args) abort
  if !has_key(a:args, 'pattern') || strlen(a:args.pattern) == 0
    throw '[grep] `pattern` is not valid.'
  endif
  if !has_key(a:args, 'cwd') || !isdirectory(a:args.cwd)
    throw '[grep] `cwd` is not valid.'
  endif
endfunction

"
" get_options
"
function! s:get_options() abort
  return [{
        \   'name': '--pattern=VALUE',
        \   'description': 'Specify grep pattern.',
        \   'extra': {
        \     'required': 0
        \   }
        \ }, {
        \   'name': '--cwd=VALUE',
        \   'description': 'Specify grep cwd.',
        \   'extra': {
        \     'default': getcwd(),
        \     'completion': 'file'
        \   }
        \ }]
endfunction

"
" get_actions
"
function! s:get_actions() abort
  return {
        \   'default': function('s:action_open'),
        \   'open': function('s:action_open'),
        \   'split': function('s:action_split'),
        \   'vsplit': function('s:action_vsplit'),
        \ }
endfunction

"
" action_open
"
function! s:action_open(candle) abort
  let l:item = a:candle.get_cursor_item()
  if empty(l:item)
    return
  endif

  call win_gotoid(a:candle.state.prev_winid)
  execute printf('edit %s', l:item.path)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', 1)])
  endif
endfunction

"
" action_split
"
function! s:action_split(candle) abort
  let l:item = a:candle.get_cursor_item()
  if empty(l:item)
    return
  endif

  call win_gotoid(a:candle.state.prev_winid)
  execute printf('split %s', l:item.path)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', 1)])
  endif
endfunction

"
" action_vsplit
"
function! s:action_vsplit(candle) abort
  let l:item = a:candle.get_cursor_item()
  if empty(l:item)
    return
  endif

  call win_gotoid(a:candle.state.prev_winid)
  execute printf('vsplit %s', l:item.path)
  if has_key(l:item, 'lnum')
    call cursor([l:item.lnum, get(l:item, 'col', 1)])
  endif
endfunction

