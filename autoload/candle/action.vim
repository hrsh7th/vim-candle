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
  let l:actions = s:get_normalized_action_map(a:candle)
  if has_key(l:actions, a:name) && l:actions[a:name].accept(a:candle)
    return l:actions[a:name]
  endif
  return v:null
endfunction

"
" candle#action#resolve
"
function! candle#action#resolve(candle) abort
  return filter(values(s:get_normalized_action_map(a:candle)), 'v:val.accept(a:candle)')
endfunction

"
" get_normalized_action_map
"
function! s:get_normalized_action_map(candle) abort
  let l:actions = {}

  " Gather actions.
  for l:action in reverse(copy(s:actions))
    if !has_key(l:actions, l:action.name)
      let l:actions[l:action.name] = l:action
    endif
  endfor

  let l:specific_actions = {}
  let l:specific_actions = extend(l:specific_actions, get(a:candle.source, 'action', {}))
  let l:specific_actions = extend(l:specific_actions, a:candle.option.action)

  " Function actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(l:specific_actions)
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      let l:actions[l:action_name] = {
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \   'accept': { -> v:true },
      \ }
    endif
  endfor

  " Redirect actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(l:specific_actions)
    if type(l:Invoke_or_redirect_action_name) == v:t_string
      if has_key(l:actions, l:Invoke_or_redirect_action_name)
        let l:actions[l:action_name] = extend({ 'name': l:action_name }, l:actions[l:Invoke_or_redirect_action_name], 'keep')
      else
        unlet l:actions[l:action_name]
      endif
    endif
  endfor

  return l:actions
endfunction

