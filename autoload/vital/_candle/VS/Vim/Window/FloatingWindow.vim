" ___vital___
" NOTE: lines between '" ___vital___' is generated by :Vitalize.
" Do not modify the code nor insert new lines before '" ___vital___'
function! s:_SID() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze__SID$')
endfunction
execute join(['function! vital#_candle#VS#Vim#Window#FloatingWindow#import() abort', printf("return map({'_vital_depends': '', 'is_available': '', 'new': '', '_vital_loaded': ''}, \"vital#_candle#function('<SNR>%s_' . v:key)\")", s:_SID()), 'endfunction'], "\n")
delfunction s:_SID
" ___vital___
"
" _vital_loaded
"
function! s:_vital_loaded(V) abort
  let s:Window = a:V.import('VS.Vim.Window')
endfunction

"
" _vital_depends
"
function! s:_vital_depends() abort
  return ['VS.Vim.Window']
endfunction

"
" managed floating windows.
"
let s:floating_windows = {}

"
" is_available
"
function! s:is_available() abort
  if has('nvim')
    return v:true
  endif
  return exists('*popup_create') && exists('*popup_hide') && exists('*popup_move') && exists('*popup_getpos')
endfunction

"
" new
"
function! s:new(...) abort
  call s:_init()

  return s:FloatingWindow.new(get(a:000, 0, {}))
endfunction

"
" _notify_opened
"
" @param {number} winid
" @param {VS.Vim.Window.FloatingWindow} floating_window
"
function! s:_notify_opened(winid, floating_window) abort
  let s:floating_windows[a:winid] = a:floating_window
  call a:floating_window._on_opened()
endfunction

"
" _notify_closed
"
function! s:_notify_closed() abort
  for [l:winid, l:floating_window] in items(s:floating_windows)
    if winheight(l:winid) == -1
      call l:floating_window._on_closed()
      unlet s:floating_windows[l:winid]
    endif
  endfor
endfunction

let s:FloatingWindow = {}

"
" new
"
" @param {function?} args.on_opened
" @param {function?} args.on_closed
"
function! s:FloatingWindow.new(args) abort
  return extend(deepcopy(s:FloatingWindow), {
  \   '_winid': v:null,
  \   '_bufnr': v:null,
  \   '_vars': {},
  \   '_on_opened': get(a:args, 'on_opened', { -> {} }),
  \   '_on_closed': get(a:args, 'on_closed', { -> {} }),
  \ })
endfunction

"
" get_size
"
" @param {number?} args.minwidth
" @param {number?} args.maxwidth
" @param {number?} args.minheight
" @param {number?} args.maxheight
"
function! s:FloatingWindow.get_size(args) abort
  if self._bufnr is# v:null
    throw 'VS.Vim.Window.FloatingWindow: Failed to detect bufnr.'
  endif

  let l:maxwidth = get(a:args, 'maxwidth', -1)
  let l:minwidth = get(a:args, 'minwidth', -1)
  let l:maxheight = get(a:args, 'maxheight', -1)
  let l:minheight = get(a:args, 'minheight', -1)
  let l:lines = getbufline(self._bufnr, '^', '$')

  " width
  let l:width = 0
  for l:line in l:lines
    let l:width = max([l:width, strdisplaywidth(l:line)])
  endfor

  let l:width = l:minwidth == -1 ? l:width : max([l:minwidth, l:width])
  let l:width = l:maxwidth == -1 ? l:width : min([l:maxwidth, l:width])

  " height
  let l:height = 0
  for l:line in l:lines
    let l:height += max([1, float2nr(ceil(strdisplaywidth(l:line) / str2float('' . l:width)))])
  endfor
  let l:height = l:minheight == -1 ? l:height : max([l:minheight, l:height])
  let l:height = l:maxheight == -1 ? l:height : min([l:maxheight, l:height])

  return {
  \   'width': max([1, l:width]),
  \   'height': max([1, l:height]),
  \ }
endfunction

"
" set_bufnr
"
" @param {number} bufnr
"
function! s:FloatingWindow.set_bufnr(bufnr) abort
  let self._bufnr = a:bufnr
endfunction

"
" get_bufnr
"
function! s:FloatingWindow.get_bufnr() abort
  return self._bufnr
endfunction

"
" get_winid
"
function! s:FloatingWindow.get_winid() abort
  if self.is_visible()
    return self._winid
  endif
  return v:null
endfunction

"
" set_var
"
" @param {string}  key
" @param {unknown} value
"
function! s:FloatingWindow.set_var(key, value) abort
  let self._vars[a:key] = a:value
  if self.is_visible()
    call setwinvar(self._winid, a:key, a:value)
  endif
endfunction

"
" get_var
"
" @param {string} key
"
function! s:FloatingWindow.get_var(key) abort
  return self._vars[a:key]
endfunction

"
" open
"
" @param {number} args.row 0-based indexing
" @param {number} args.col 0-based indexing
" @param {number} args.width
" @param {number} args.height
" @param {number?} args.topline
"
function! s:FloatingWindow.open(args) abort
  let l:style = {
  \   'row': a:args.row,
  \   'col': a:args.col,
  \   'width': a:args.width,
  \   'height': a:args.height,
  \   'topline': get(a:args, 'topline', 1),
  \ }

  let l:will_move = self.is_visible()
  if l:will_move
    let self._winid = s:_move(self, self._winid, self._bufnr, l:style)
  else
    let self._winid = s:_open(self._bufnr, l:style, { -> self._on_closed() })
  endif
  for [l:key, l:value] in items(self._vars)
    call setwinvar(self._winid, l:key, l:value)
  endfor
  if !l:will_move
    call s:_notify_opened(self._winid, self)
  endif
endfunction

"
" close
"
function! s:FloatingWindow.close() abort
  if self.is_visible()
    call s:_close(self._winid)
  endif
  let self._winid = v:null
endfunction

"
" enter
"
function! s:FloatingWindow.enter() abort
  call s:_enter(self._winid)
endfunction

"
" is_visible
"
function! s:FloatingWindow.is_visible() abort
  return s:_exists(self._winid) ? v:true : v:false
endfunction

"
" open
"
if has('nvim')
  function! s:_open(buf, style, callback) abort
    let l:winid = nvim_open_win(a:buf, v:false, s:_style(a:style))
    call s:Window.scroll(l:winid, a:style.topline)
    return l:winid
  endfunction
else
  function! s:_open(buf, style, callback) abort
    return popup_create(a:buf, extend(s:_style(a:style), {
    \  'callback': a:callback,
    \ }, 'force'))
  endfunction
endif

"
" close
"
if has('nvim')
  function! s:_close(winid) abort
    call nvim_win_close(a:winid, v:true)
    call s:_notify_closed()
  endfunction
else
  function! s:_close(winid) abort
    call popup_close(a:winid)
  endfunction
endif

"
" move
"
if has('nvim')
  function! s:_move(self, winid, bufnr, style) abort
    call nvim_win_set_config(a:winid, s:_style(a:style))
    if a:bufnr != nvim_win_get_buf(a:winid)
      call nvim_win_set_buf(a:winid, a:bufnr)
    endif
    call s:Window.scroll(a:winid, a:style.topline)
    return a:winid
  endfunction
else
  function! s:_move(self, winid, bufnr, style) abort
    " vim's popup window can't change bufnr so open new popup in here.
    if a:bufnr != winbufnr(a:winid)
      let l:On_closed = a:self._on_closed
      let a:self._on_closed = { -> {} }
      call s:_close(a:winid)
      let a:self._on_closed = l:On_closed
      return s:_open(a:bufnr, a:style, { -> a:self._on_closed() })
    endif
    call popup_move(a:winid, s:_style(a:style))
    return a:winid
  endfunction
endif

"
" enter
"
if has('nvim')
  function! s:_enter(winid) abort
    call win_gotoid(a:winid)
  endfunction
else
  function! s:_enter(winid) abort
    " not supported.
  endfunction
endif

"
" exists
"
if has('nvim')
  function! s:_exists(winid) abort
    return type(a:winid) == type(0) && nvim_win_is_valid(a:winid) && nvim_win_get_number(a:winid) != -1
  endfunction
else
  function! s:_exists(winid) abort
    return type(a:winid) == type(0) && winheight(a:winid) != -1
  endfunction
endif

"
" style
"
if has('nvim')
  function! s:_style(style) abort
    return {
    \   'relative': 'editor',
    \   'width': a:style.width,
    \   'height': a:style.height,
    \   'row': a:style.row,
    \   'col': a:style.col,
    \   'focusable': v:true,
    \   'style': 'minimal',
    \ }
  endfunction
else
  function! s:_style(style) abort
    return {
    \   'line': a:style.row + 1,
    \   'col': a:style.col + 1,
    \   'pos': 'topleft',
    \   'moved': [0, 0, 0],
    \   'scrollbar': 0,
    \   'maxwidth': a:style.width,
    \   'maxheight': a:style.height,
    \   'minwidth': a:style.width,
    \   'minheight': a:style.height,
    \   'tabpage': 0,
    \   'firstline': a:style.topline,
    \ }
  endfunction
endif

"
" init
"
let s:has_init = v:false
function! s:_init() abort
  if s:has_init || !has('nvim')
    return
  endif
  let s:has_init = v:true
  augroup printf('<sfile>')
    autocmd!
    autocmd WinEnter * call <SID>_notify_closed()
  augroup END
endfunction

