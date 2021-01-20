let s:actions = []

"
" candle#action#register
"
function! candle#action#register(action) abort
  if !has_key(a:action, 'name')
    throw '`name` is required.'
  endif

  if !has_key(a:action, 'accept')
    throw '`accept` is required.'
  endif

  if !has_key(a:action, 'invoke')
    throw '`invoke` is required.'
  endif

  let s:actions += [a:action]
endfunction

"
" candle#action#find
"
function! candle#action#find(candle, name) abort
  let l:actions = {}

  " Global actions.
  for l:action in reverse(copy(s:actions))
    if !has_key(l:actions, l:action.name)
      let l:actions[l:action.name] = l:action
    endif
  endfor

  " Source actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(get(a:candle.source, 'action', {}))
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      if a:name ==# l:action.name
        return {
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \   'accept': { -> v:true },
        \ }
      endif
    endif
  endfor

  " Argumented actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(copy(a:candle.option.action))
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      return {
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \   'accept': { -> v:true },
      \ }
    endif
  endfor

  " Redirect source actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(get(a:candle.source, 'action', {}))
    if type(l:Invoke_or_redirect_action_name) == v:t_string && has_key(l:actions, l:Invoke_or_redirect_action_name)
      let l:actions[l:action_name] = extend({ 'name': l:action_name }, l:actions[l:Invoke_or_redirect_action_name], 'keep')
    endif
  endfor

  " Redirect argumented actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(copy(a:candle.option.action))
    if type(l:Invoke_or_redirect_action_name) == v:t_string && has_key(l:actions, l:Invoke_or_redirect_action_name)
      let l:actions[l:action_name] = extend({ 'name': l:action_name }, l:actions[l:Invoke_or_redirect_action_name], 'keep')
    endif
  endfor

  return get(l:actions, a:name, v:null)
endfunction

"
" candle#action#resolve
"
function! candle#action#resolve(candle) abort
  let l:actions = {}

  " Global actions.
  for l:action in reverse(copy(s:actions))
    if !has_key(l:actions, l:action.name)
      let l:actions[l:action.name] = l:action
    endif
  endfor

  " Source actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(get(a:candle.source, 'action', {}))
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      let l:actions[l:action.name] = {
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \   'accept': { -> v:true },
      \ }
    endif
  endfor

  " Argumented actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(copy(a:candle.option.action))
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      let l:actions[l:action.name] = {
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \   'accept': { -> v:true },
      \ }
    endif
  endfor

  " Redirect source actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(get(a:candle.source, 'action', {}))
    if type(l:Invoke_or_redirect_action_name) == v:t_string && has_key(l:actions, l:Invoke_or_redirect_action_name)
      let l:actions[l:action_name] = extend({ 'name': l:action_name }, l:actions[l:Invoke_or_redirect_action_name], 'keep')
    endif
  endfor

  " Redirect argumented actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(copy(a:candle.option.action))
    if type(l:Invoke_or_redirect_action_name) == v:t_string && has_key(l:actions, l:Invoke_or_redirect_action_name)
      let l:actions[l:action_name] = extend({ 'name': l:action_name }, l:actions[l:Invoke_or_redirect_action_name], 'keep')
    endif
  endfor

  return filter(values(l:actions), 'v:val.accept(a:candle)')
endfunction

"
" compare
"
function! s:compare(action1, action2) abort
  let l:len1 = strchars(a:action1.name)
  let l:len2 = strchars(a:action2.name)

  let l:i = 0
  while l:i < min([l:len1, l:len2])
    let l:diff = strgetchar(a:action1.name, l:i) - strgetchar(a:action2.name, l:i)
    if l:diff != 0
      return l:diff
    endif
    let l:i += 1
  endwhile

  return l:len1 - l:len2
endfunction

