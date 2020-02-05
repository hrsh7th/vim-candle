"
" candle#action#common#get
"
function! candle#action#common#get() abort
  return [{
  \   'name': 'echo',
  \   'accept': { candle -> v:true },
  \   'invoke': { candle -> s:echo(candle.get_action_items()) }
  \ }, {
  \   'name': 'yank',
  \   'accept': { candle -> len(candle.get_action_items()) == 1 },
  \   'invoke': { candle -> s:yank(candle.get_action_items()[0]) }
  \ }]
endfunction

"
" echo
"
function! s:echo(items) abort
  echomsg string(a:items)
endfunction

"
" yank
"
function! s:yank(item) abort
  let l:msgs = ['Item has following keys:']
  for l:key in keys(a:item)
    let l:msgs += [printf('  %s', l:key)]
  endfor
  let l:msgs += ['Choose key to yank (default: title) > ']

  let l:key = input(join(l:msgs, "\n"), 'title')
  if has_key(a:item, l:key)
    call setreg('*', a:item[l:key])
  endif
endfunction

