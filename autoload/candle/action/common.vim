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
" candle#action#common#expect_keys_single
"
function! candle#action#common#expect_keys_single(keys, candle) abort
  let l:items = a:candle.get_action_items()
  if len(l:items) != 1
    return v:false
  endif
  let l:item = l:items[0]

  for l:key in a:keys
    if !has_key(l:item, l:key)
      return v:false
    endif
  endfor

  return v:true
endfunction

"
" candle#action#common#expect_keys_multiple
"
function! candle#action#common#expect_keys_multiple(keys, candle) abort
  for l:item in a:candle.get_action_items()
    for l:key in a:keys
      if !has_key(l:item, l:key)
        return v:false
      endif
    endfor
  endfor
  return v:true
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

