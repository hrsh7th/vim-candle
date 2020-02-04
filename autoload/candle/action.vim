"
" candle#action#register
"
function! candle#action#register(action) abort
  if !has_key(a:action, 'name')
    throw '[CANDLE] `name` is required.'
  endif

  if !has_key(a:action, 'accept')
    throw '[CANDLE] `accept` is required.'
  endif

  if !has_key(a:action, 'invoke')
    throw '[CANDLE] `invoke` is required.'
  endif

  let s:actions += [a:action]
endfunction

"
" candle#action#resolve
"
function! candle#action#resolve(candle) abort
  " Global actions.
  let l:actions = copy(s:actions)
  let l:actions = filter(l:actions, { i, action -> action.accept(a:candle) })

  " Source specific actions
  for [l:action_name, l:Invoke_or_redirect_action_name] in items(a:candle.source.actions)

    " Source specific action.
    if type(l:Invoke_or_redirect_action_name) == v:t_func
      let l:actions += [{
      \   'name': l:action_name,
      \   'invoke': l:Invoke_or_redirect_action_name,
      \ }]

    " Redirect action.
    elseif type(l:Invoke_or_redirect_action_name) == type('')
      let l:redirect_action = get(filter(copy(l:actions), { i, action -> action.name ==# l:Invoke_or_redirect_action_name }), 0, {})
      if !empty(l:redirect_action)
        let l:actions += [extend(copy(l:redirect_action),{ 'name': l:action_name } )]
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
  let l:actions = reverse(l:actions)
  return l:actions
endfunction

"
" Built-in actions
"
let s:actions = []
let s:actions += candle#action#location#get()

