vim-candle
===

Any candidates listing engine for vim/nvim built on [yaegi](https://github.com/containous/yaegi).


Status
===

- Works
- Not documented
- APIs aren't stable
- Tested only in mac


Requirements
===

- vim
  - exists('*win_exeute')

- nvim
  - exists('deletebufline')


Concept
===

### Performance
fuzzy/substring/regex filter written in golang.

### Works on vim/neovim
Use `job` API only.


Setting
===

<details>
  <summary>Example settings</summary>

```viml
augroup vimrc
 autocmd!
augroup END

"
" mapping for candle buffer
"
autocmd vimrc User candle#start call s:on_candle_start()
function! s:on_candle_start()
  nnoremap <silent><buffer> k     :<C-u>call candle#mapping#cursor_move(-1)<CR>
  nnoremap <silent><buffer> j     :<C-u>call candle#mapping#cursor_move(1)<CR>
  nnoremap <silent><buffer> K     :<C-u>call candle#mapping#cursor_move(-10)<CR>
  nnoremap <silent><buffer> J     :<C-u>call candle#mapping#cursor_move(10)<CR>
  nnoremap <silent><buffer> gg    :<C-u>call candle#mapping#cursor_top()<CR>
  nnoremap <silent><buffer> G     :<C-u>call candle#mapping#cursor_bottom()<CR>
  nnoremap <silent><buffer> -     :<C-u>call candle#mapping#toggle_select()<CR>
  nnoremap <silent><buffer> *     :<C-u>call candle#mapping#toggle_select_all()<CR>
  nnoremap <silent><buffer> i     :<C-u>call candle#mapping#input_open()<CR>
  nnoremap <silent><buffer> a     :<C-u>call candle#mapping#input_open()<CR>
  nnoremap <silent><buffer> <Tab> :<C-u>call candle#mapping#choose_action()<CR>

  nnoremap <silent><buffer> <CR>  :<C-u>call candle#mapping#action('default')<CR>
  nnoremap <silent><buffer> s     :<C-u>call candle#mapping#action('split')<CR>
  nnoremap <silent><buffer> v     :<C-u>call candle#mapping#action('vsplit')<CR>
  nnoremap <silent><buffer> d     :<C-u>call candle#mapping#action('delete')<CR>
endfunction

"
" mapping for candle.input buffer
"
autocmd vimrc User candle#input#start call s:on_candle_input_start()
function! s:on_candle_input_start()
  let b:lexima_disabled = v:true
  inoremap <silent><buffer> <Tab> <Esc>:<C-u>quit \| call candle#mapping#choose_action()<CR>
  inoremap <silent><buffer> <CR>  <Esc>:<C-u>quit \| call candle#mapping#action('default')<CR>
  inoremap <silent><buffer> <Esc> <Esc>:<C-u>call candle#mapping#input_close()<CR>
  inoremap <silent><buffer> <C-k> <C-o>:<C-u>call candle#mapping#cursor_move(-1)<CR>
  inoremap <silent><buffer> <C-j> <C-o>:<C-u>call candle#mapping#cursor_move(1)<CR>
endfunction

"
" file mru (ignore displayed buffers)
"
nnoremap <silent>mru_file :<C-u>call candle#start({
\   'source': 'mru_file',
\   'params': {
\     'filepath': g:candle#source#mru_file#filepath,
\     'ignore_patterns': map(range(1, tabpagewinnr(tabpagenr(), '$')), { i, winnr ->
\       fnamemodify(bufname(winbufnr(winnr)), ':p')
\     })
\   }
\ })<CR>

"
" all files in your project
"
nnoremap <silent>file :<C-u>call candle#start({
\   'source': 'file',
\   'params': {
\     'root_path': 'path to root dir',
\     'ignore_patterns': ['.git/', 'node_modules'],
\   }
\ })<CR>

"
" grep (auto-detect ripgrep, ag, pt, jvgrep, grep)
"
nnoremap <silent>grep :<C-u>call candle#start({
\   'source': 'grep',
\   'params': {
\     'root_path': 'path to root dir',
\     'pattern': input('PATTERN: '),
\   }
\ })<CR>

"
" any items and any action
"
nnoremap <silent>menu :<C-u>call candle#start({
\   'source': 'item',
\   'actions': {
\     'default': { candle -> execute(candle.get_cursor_item().execute) }
\   },
\   'params': {
\     'items': [{
\       'id': 1,
\       'title': 'PlugUpdate',
\       'execute': 'PlugUpdate'
\     }, {
\       'id': 2,
\       'title': 'Open .vimrc',
\       'execute': 'vsplit $MYVIMRC'
\     }],
\   },
\ })<CR>
```
</details>

