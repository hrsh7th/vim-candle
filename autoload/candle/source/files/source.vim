let s:dirname = expand('<sfile>:p:h')

"
" candle#source#files#source#definition
"
function! candle#source#files#source#definition() abort
  return {
        \   'name': 'files',
        \   'script': s:dirname . '/source.go',
        \   'get_script_params': { params -> s:get_script_params(params) },
        \   'get_actions': { -> s:get_actions() },
        \ }
endfunction

"
" get_script_params
"
function! s:get_script_params(params) abort
  return {
  \   'root_path': get(a:params, 'root_path', getcwd()),
  \   'ignore_patterns': get(a:params, 'ignore_patterns', [])
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

