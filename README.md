# vim-candle

Any candidates listing engine for vim/nvim built on [yaegi](https://github.com/containous/yaegi).

You can create a custom source with golang.


# Status

- Works well
- Not documented
- APIs aren't stable
- Should build binary by yourself

# Requirements

- latest vim or latest nvim


# Setting

```viml
autocmd vimrc User candle#initialize call s:on_candle_initialize()
function! s:on_candle_initialize()
  let g:candle.debug = '/tmp/candle.log'
  let g:candle.global.start_delay = 20
endfunction

autocmd vimrc User candle#start call s:on_candle_start()
function! s:on_candle_start()
  nnoremap <silent><buffer> k    :<C-u>call candle#mapping#cursor_up()<CR>
  nnoremap <silent><buffer> j    :<C-u>call candle#mapping#cursor_down()<CR>
  nnoremap <silent><buffer> gg   :<C-u>call candle#mapping#cursor_top()<CR>
  nnoremap <silent><buffer> G    :<C-u>call candle#mapping#cursor_bottom()<CR>
  nnoremap <silent><buffer> i    :<C-u>call candle#mapping#input_open()<CR>
  nnoremap <silent><buffer> a    :<C-u>call candle#mapping#input_open()<CR>
  nnoremap <silent><buffer> s    :<C-u>call candle#mapping#action('split')<CR>
  nnoremap <silent><buffer> v    :<C-u>call candle#mapping#action('vsplit')<CR>
  nnoremap <silent><buffer> <CR> :<C-u>call candle#mapping#action('open')<CR>
endfunction

autocmd vimrc User candle#input#start call s:on_candle_input_start()
function! s:on_candle_input_start()
  " ...
endfunction
```

# Concept

### High performance
fuzzy/substring/regex filter written in golang.


### Extensible
Can create a source with golang.


### Works on vim/neovim both
Use `job` API.
No need neovim-rpc.


### Works any platforms
Provide binary and auto-installer (in the future).

