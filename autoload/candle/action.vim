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
" candle#action#resolve
"
function! candle#action#resolve(candle) abort
  " Global actions.
  let l:actions = copy(s:actions)
  let l:actions = reverse(l:actions)
  let l:actions = filter(l:actions, { i, action -> action.accept(a:candle) })

  " Source or Argumented actions.
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(extend(
  \   copy(get(a:candle.source, 'action', {})),
  \   copy(a:candle.option.action),
  \ ))

    " Source specific action.
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      call insert(l:actions, {
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \ }, 0)

    " Redirect action.
    elseif type(l:Invoke_or_redirect_action_name) == type('')
      let l:redirect_action = get(filter(copy(l:actions), { i, action -> action.name ==# l:Invoke_or_redirect_action_name }), 0, {})
      if !empty(l:redirect_action)
        call insert(l:actions, extend(copy(l:redirect_action),{ 'name': l:action_name } ), 0)
      endif
    endif
  endfor

  return s:normalize(l:actions)
endfunction

"
" normalize
"
function! s:normalize(actions) abort
  let l:actions = copy(a:actions)
  let l:actions = sort(l:actions, function('s:compare'))
  let l:actions = uniq(l:actions, function('s:compare'))
  return l:actions
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

