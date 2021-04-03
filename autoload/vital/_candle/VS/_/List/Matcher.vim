" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_candle#VS#_#List#Matcher#import() abort', printf("return map({'_vital_depends': '', 'match': ''}, \"vital#_candle#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
let s:file = expand('<sfile>:p:h') . '/Matcher.lua'

"
" _vital_depends
"
function! s:_vital_depends() abort
  return {
  \   'files': ['./Matcher.lua']
  \ }
endfunction

"
" match
"
function! s:match(args) abort
  let l:items = a:args.items
  let l:query = a:args.query
  let l:key = get(a:args, 'key', v:null)
  try
    if has('nvim')
      return luaeval(printf('dofile("%s").match(_A[1], _A[2], _A[3])', s:file), [l:items, l:query, l:key])
    else
      return matchfuzzy(l:items, l:query, { 'key': l:key })
    endif
  catch /.*/
    echomsg string({ 'exception': v:exception, 'throwpoint': v:throwpoint })
  endtry
  return []
endfunction

