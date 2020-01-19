"
" candle#render#mapping#initialize
"
function! candle#render#mapping#initialize(context) abort
  nnoremap <silent><buffer> k :<C-u>call <SID>on_k()<CR>
  nnoremap <silent><buffer> j :<C-u>call <SID>on_j()<CR>
  nnoremap <silent><buffer> gg :<C-u>call <SID>on_gg()<CR>
  nnoremap <silent><buffer> G :<C-u>call <SID>on_G()<CR>
  nnoremap <silent><buffer> i :<C-u>call <SID>on_i()<CR>
endfunction


"
" on_k
"
function! s:on_k() abort
  if 1 == line('.')
    let b:candle.state.index = max([0, b:candle.state.index - 1])
  else
    normal! k
    let b:candle.state.cursor = line('.')
  endif
  call candle#render#refresh({ 'bufname': bufname('%'), 'sync': v:true })
endfunction

"
" on_j
"
function! s:on_j() abort
  let l:max = min([winheight(0), line('$')])
  if l:max == line('.')
    let b:candle.state.index = min([b:candle.total - winheight(0), b:candle.state.index + 1])
  else
    normal! j
    let b:candle.state.cursor = line('.')
  endif
  call candle#render#refresh({ 'bufname': bufname('%'), 'sync': v:true })
endfunction

"
" on_gg
"
function! s:on_gg() abort
  let b:candle.state.index = 0
  let b:candle.state.cursor = 1
  call candle#render#refresh({ 'bufname': bufname('%'), 'sync': v:true })
endfunction

"
" on_G
"
function! s:on_G() abort
  let b:candle.state.index = b:candle.total - winheight(0)
  let b:candle.state.cursor = line('$')
  call candle#render#refresh({ 'bufname': bufname('%'), 'sync': v:true })
endfunction

"
" on_i
"
function! s:on_i() abort
  call candle#render#input#open(b:candle)
endfunction
