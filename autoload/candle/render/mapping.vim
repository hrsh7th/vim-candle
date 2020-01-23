"
" candle#render#mapping#initialize
"
function! candle#render#mapping#initialize(candle) abort
  nnoremap <silent><buffer> k :<C-u>call <SID>on_k()<CR>
  nnoremap <silent><buffer> j :<C-u>call <SID>on_j()<CR>
  nnoremap <silent><buffer> gg :<C-u>call <SID>on_gg()<CR>
  nnoremap <silent><buffer> G :<C-u>call <SID>on_G()<CR>
  nnoremap <silent><buffer> i :<C-u>call <SID>on_i()<CR>
  nnoremap <silent><buffer> a :<C-u>call <SID>on_a()<CR>
  nnoremap <silent><buffer> <CR> :<C-u>call <SID>on_cr()<CR>
endfunction


"
" on_k
"
function! s:on_k() abort
  call b:candle.up()
endfunction

"
" on_j
"
function! s:on_j() abort
  call b:candle.down()
endfunction

"
" on_gg
"
function! s:on_gg() abort
  call b:candle.top()
endfunction

"
" on_G
"
function! s:on_G() abort
  call b:candle.bottom()
endfunction

"
" on_i
"
function! s:on_i() abort
  call candle#render#input#open(b:candle)
endfunction

"
" on_a
"
function! s:on_a() abort
  call candle#render#input#open(b:candle)
endfunction

"
" on_cr
"
function! s:on_cr() abort
  call candle#action('default')
endfunction

