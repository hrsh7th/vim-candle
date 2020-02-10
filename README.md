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
use `job` API only.

### Use function, not command.
The reason is that command can't pass complex object.


Setting
===

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
  nnoremap <silent><buffer> <C-l> :<C-u>call candle#mapping#restart()<CR>

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

```

# Recipes

### mru files

Recently opened files (and exclude displayed files).

```viml
nnoremap <silent>mru_file :<C-u>call candle#start({
\   'mru_file': {
\     'ignore_patterns': map(range(1, tabpagewinnr(tabpagenr(), '$')), { i, winnr ->
\       fnamemodify(bufname(winbufnr(winnr)), ':p')
\     })
\ })<CR>
```


### mru projects

Recently projects (When choose one project, listing all files).

```viml
  nnoremap <silent><Leader>mru_project :<C-u>call candle#start({
  \   'mru_dir': {},
  \ }, {
  \   'action': {
  \     'default': { candle -> [
  \       execute('quit'),
  \       win_gotoid(cnadle.prev_winid)
  \       candle#start({
  \         'source': 'file',
  \         'params': {
  \           'root_path': candle.get_action_items()[0].path,
  \           'ignore_patterns': ['.git/', 'node_modules'],
  \         }
  \       })
  \     ] }
  \   }
  \ })<CR>
```


### files

All files under specified root.

```viml
nnoremap <silent>file :<C-u>call candle#start({
\   'file': {
\     'root_path': 'path to root dir',
\     'ignore_patterns': ['.git/', 'node_modules'],
\   }
\ })<CR>
```


### grep

Invoke ripgrep/ag/pt/jvgrep/grep.

```viml
nnoremap <silent>grep :<C-u>call candle#start({
\   'grep': {
\     'root_path': 'path to root dir',
\     'pattern': input('PATTERN: '),
\   }
\ })<CR>
```

### grep + [vim-qfreplace](https://github.com/thinca/vim-qfreplace)

Modify grep results with qfreplace.

```viml

function! s:qfreplace_accept(candle) abort
  return len(filter(a:candle.get_action_items()), { _, item ->
  \   !has_key(item, 'path') || !has_key(item, 'lnum') || !has_key(item, 'text')
  \ }) == 0
endfunction

function! s:qfreplace_invoke(candle) abort
  call setqflist(map(a:candle.get_action_items(), { _, item -> {
  \   'filename': item.path,
  \   'lnum': item.lnum,
  \   'text': item.text
  \ } }))
  call qfreplace#start('')
endfunction

call candle#action#register({
\   'name': 'qfreplace',
\   'accept': function('s:qfreplace_accept'),
\   'invoke': function('s:qfreplace_invoke'),
\ })
```

### menus

Your custom menu.

```viml
nnoremap <silent>menu :<C-u>call candle#start({
\   'item': [{
\     'id': 1,
\     'title': 'PlugUpdate',
\     'execute': 'PlugUpdate'
\   }, {
\     'id': 2,
\     'title': 'Open .vimrc',
\     'execute': 'vsplit $MYVIMRC'
\   }]
\ }, {
\   'action': {
\     'default': { candle -> execute(candle.get_cursor_item().execute) }
\   }
\ })<CR>
```

