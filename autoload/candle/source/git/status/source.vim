let s:dirname = expand('<sfile>:p:h')

"
" candle#source#git#status#source#definition
"
function! candle#source#git#status#source#definition() abort
  return {
        \   'name': 'git/status',
        \   'create': function('s:create', ['git/status'])
        \ }
endfunction

"
" create
"
function! s:create(name, args) abort
  let l:working_dir = get(a:args, 'working_dir', getcwd())
  if l:working_dir ==# ''
    echoerr 'does not detect working dir'
  endif

  return {
  \   'name': a:name,
  \   'script': {
  \     'path': s:dirname . '/source.go',
  \     'args': {
  \       'working_dir': get(a:args, 'working_dir', getcwd()),
  \     }
  \   },
  \   'action': {
  \     'diff': function('s:action_diff'),
  \     'add': function('s:action_add'),
  \     'rm': function('s:action_rm'),
  \     'reset': function('s:action_reset'),
  \     'checkout': function('s:action_checkout'),
  \     'commit': function('s:action_commit'),
  \     'commit_amend': function('s:action_commit_amend'),
  \     'toggle': function('s:action_toggle'),
  \     'default': function('s:action_diff'),
  \   }
  \ }
endfunction

"
" s:action_diff
"
function! s:action_diff(candle) abort
  for l:item in a:candle.get_action_items()
    call candle#source#git#diff_status(a:candle, l:item)
  endfor
endfunction

"
" s:action_commit
"
function! s:action_commit(candle) abort
  call a:candle.close()
  let l:items = a:candle.get_action_items()
  call candle#source#git#commit(a:candle, l:items, v:false)
endfunction

"
" s:action_commit_amend
"
function! s:action_commit_amend(candle) abort
  call a:candle.close()
  let l:items = a:candle.get_action_items()
  call candle#source#git#commit(a:candle, l:items, v:true)
endfunction

"
" s:action_toggle
"
function! s:action_toggle(candle) abort
  let l:items = a:candle.get_action_items()
  call candle#source#git#run_items(a:candle, 'reset', filter(copy(l:items), { _, item -> candle#source#git#is_staged_status(item) }))
  call candle#source#git#run_items(a:candle, 'add', filter(copy(l:items), { _, item -> !candle#source#git#is_staged_status(item) }))
  call a:candle.start()
endfunction

"
" s:action_add
"
function! s:action_add(candle) abort
  let l:items = a:candle.get_action_items()
  call candle#source#git#run_items(a:candle, 'add', filter(copy(l:items), { _, item -> !candle#source#git#is_staged_status(item) }))
  call a:candle.start()
endfunction

"
" s:action_rm
"
function! s:action_rm(candle) abort
  let l:items = a:candle.get_action_items()
  call candle#source#git#run_items(a:candle, 'rm', filter(copy(l:items), { _, item -> !candle#source#git#is_staged_status(item) }))
  call a:candle.start()
endfunction

"
" s:action_reset
"
function! s:action_reset(candle) abort
  let l:items = a:candle.get_action_items()
  call candle#source#git#run_items(a:candle, 'reset', filter(copy(l:items), { _, item -> candle#source#git#is_staged_status(item) }))
  call a:candle.start()
endfunction

"
" s:action_checkout
"
function! s:action_checkout(candle) abort
  let l:items = a:candle.get_action_items()
  call candle#source#git#run_items(a:candle, 'reset', filter(copy(l:items), { _, item -> candle#source#git#is_staged_status(item) }))
  call candle#source#git#run_items(a:candle, 'checkout', l:items)
  call a:candle.start()
endfunction

