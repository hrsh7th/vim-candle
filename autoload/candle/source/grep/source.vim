let s:dirname = expand('<sfile>:p:h')

"
" candle#source#grep#source#definition
"
function! candle#source#grep#source#definition() abort
  return {
        \   'name': 'grep',
        \   'script': s:dirname . '/source.go',
        \   'get_script_params': { params -> s:get_script_params(params) },
        \   'get_actions': { -> s:get_actions() },
        \ }
endfunction

"
" get_script_params
"
function! s:get_script_params(params) abort
  if strlen(get(a:params, 'pattern', 0)) == 0
    throw '[grep] pattern is required.'
  endif

  return {
  \   'root_path': get(a:params, 'root_path', getcwd()),
  \   'pattern': get(a:params, 'pattern', ''),
  \ }
endfunction

"
" get_actions
"
function! s:get_actions() abort
  let l:actions = {}
  let l:actions = extend(l:actions, candle#action#location#get())
  let l:actions.default = l:actions.edit
  return l:actions
endfunction

