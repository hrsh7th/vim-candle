let s:Buffer = vital#candle#import('VS.Vim.Buffer')
let s:TextMark = vital#candle#import('VS.Vim.Buffer.TextMark')
let s:Window = vital#candle#import('VS.Vim.Window')
let s:FloatingWindow = vital#candle#import('VS.Vim.Window.FloatingWindow')

let s:preview = s:FloatingWindow.new({})

let s:initial_state = {
\   'total': 0,
\   'filtered_total': 0,
\   'items': [],
\   'query': '',
\   'index': 0,
\   'cursor': 1,
\   'selected_id_map': {},
\   'status': 'progress',
\   'preview': v:false,
\   'is_selected_all': v:false,
\ }

"
" candle#context#import
"
function! candle#context#import() abort
  return s:Context
endfunction

let s:Context = {}

"
" new
"
function! s:Context.new(context) abort
  let l:context = extend({}, deepcopy(s:Context))
  let l:context = extend(l:context, a:context)
  let l:context = extend(l:context, {
  \   'request_id': 0,
  \   'stopped': v:false,
  \   'winid': 0,
  \   'prev_bufnr': 0,
  \   'prev_winid': 0,
  \   'state': deepcopy(s:initial_state),
  \   'prev_state': deepcopy(s:initial_state),
  \ })
  call bufadd(l:context.bufname)
  call bufload(l:context.bufname)
  call setbufvar(l:context.bufname, 'candle', l:context)
  call setbufvar(l:context.bufname, '&filetype', 'candle')
  call setbufvar(l:context.bufname, '&buftype', 'nofile')
  call setbufvar(l:context.bufname, '&buflisted', 0)
  call setbufvar(l:context.bufname, '&bufhidden', 'hide')
  call setbufvar(l:context.bufname, '&number', 0)
  call setbufvar(l:context.bufname, '&signcolumn', 'yes')
  call setbufvar(l:context.bufname, '&scrolloff', 0)
  return l:context
endfunction

"
" start
"
function! s:Context.start() abort
  let self.state.status = 'progress'
  let self.state.total = 0
  let self.state.filtered_total = 0
  let self.state.selected_id_map = {}
  let self.state.is_selected_all = v:false
  let self.state.items = []

  call candle#sync(
  \   self.server.request('start', {
  \     'id': self.bufname,
  \     'path': self.source.script.path,
  \     'args': self.source.script.args,
  \   })
  \ )
  call self.open()
endfunction

"
" stop
"
function! s:Context.stop() abort
  call self.server.request('stop', {
  \   'id': self.bufname,
  \ })
endfunction

"
" is_visible
"
function! s:Context.is_visible() abort
  let [l:tabnr, l:winnr] = win_id2tabwin(self.winid)
  return l:tabnr == tabpagenr() && l:winnr > 0
endfunction

"
" is_alive
"
function! s:Context.is_alive() abort
  return bufloaded(self.bufname)
endfunction

"
" open
"
function! s:Context.open() abort
  if self.is_visible()
    return
  endif

  call self.refresh({ 'force': v:true, 'async': v:false })

  " initialize window.
  let self.prev_bufnr = bufnr('%')
  let self.prev_winid = win_getid()
  call candle#render#window#initialize(self)
  call candle#render#statusline#update(self, v:true)
  let self.winid = win_getid()

  " initialize events.
  let l:ctx = {
  \   'winid': self.winid,
  \   'bufnr': bufnr(self.bufname),
  \ }
  call candle#event#clean(bufnr(self.bufname))
  call candle#event#attach('WinClosed', { -> [s:preview.close(), win_gotoid(self.prev_winid)] }, l:ctx)
  call candle#event#attach('BufEnter', { -> [self.refresh({ 'force': v:true, 'async': v:true })] }, l:ctx)
  call candle#event#attach('BufDelete', { -> [self.stop(), candle#event#clean(bufnr(self.bufname))] }, l:ctx)

  try
    call candle#sync({ -> self.can_display_new_items() || self.state.status ==# 'done' }, 200)
  catch /.*/
  endtry

  doautocmd <nomodeline> User candle#start

  if self.option.start_input
    call timer_start(0, { -> candle#render#input#open(self) })
  endif
endfunction

"
" close
"
function! s:Context.close() abort
  if !self.is_visible()
    return
  endif
  let l:curr_winid = win_getid()
  noautocmd call win_gotoid(self.winid)
  noautocmd silent keepalt keepjumps quit
  let l:next_winid = l:curr_winid == self.winid ? self.prev_winid : l:curr_winid
  noautocmd call win_gotoid(l:next_winid)
endfunction

"
" on_notification
"
function! s:Context.on_notification(notification) abort
  if a:notification.method ==# 'start'
    call self.refresh({ 'async': v:true, 'force': v:true })

  elseif a:notification.method ==# 'progress'
    let self.state.total = a:notification.params.total
    let self.state.filtered_total = a:notification.params.filtered_total
    let self.state.status = 'progress'
    call self.refresh({ 'async': v:true })

  elseif a:notification.method ==# 'done'
    let self.state.total = a:notification.params.total
    let self.state.filtered_total = a:notification.params.filtered_total
    let self.state.status = 'done'
    call self.refresh({ 'async': v:true })

  elseif a:notification.method ==# 'message'
    echomsg a:notification.params.message . "\n"
  endif
endfunction

"
" fetch
"
function! s:Context.fetch() abort
  return self.server.request('fetch', {
  \   'id': self.bufname,
  \   'query': self.state.query,
  \   'index': self.state.index,
  \   'count': self.option.maxheight,
  \ })
endfunction

"
" fetch_all
"
function! s:Context.fetch_all() abort
  return self.server.request('fetch', {
  \   'id': self.bufname,
  \   'query': self.state.query,
  \   'index': 0,
  \   'count': self.state.filtered_total,
  \ })
endfunction

"
" choose_action
"
function! s:Context.choose_action()
  call candle#start({
  \   'item':  map(candle#action#resolve(self), { i, action -> { 'id': string(i), 'title': action.name } })
  \ }, {
  \   'start_input': g:candle.option.start_input_action,
  \   'action': {
  \     'default': {
  \       candle -> [
  \         candle.close(),
  \         self.open(),
  \         self.action(candle.get_action_items()[0].title),
  \       ]
  \     }
  \   },
  \   'parent': self,
  \ })
endfunction

"
" auto_action
"
function! s:Context.auto_action(name) abort
  try
    let l:action_item = self.get_cursor_item()
    if empty(l:action_item)
      return
    endif

    let l:action = candle#action#find(self, a:name)
    if !empty(l:action)
      call l:action.invoke(self.parent)
    endif
  catch /.*/
    call candle#on_exception()
  endtry
endfunction

"
" action
"
function! s:Context.action(name) abort
  try
    let l:action = candle#action#find(self, a:name)
    if !empty(l:action)
      call l:action.invoke(self)
    else
      throw printf('No such action: `%s`', a:name)
    endif
  catch /.*/
    call candle#on_exception()
  endtry
endfunction

"
" query
"
function! s:Context.query(query) abort
  if self.state.query != a:query
    let self.state.query = a:query
  endif
  call self.refresh()
endfunction

"
" toggle_select_all
"
function! s:Context.toggle_select_all() abort
  let self.state.is_selected_all = !self.state.is_selected_all
  if !self.state.is_selected_all
    let self.state.selected_id_map = {}
  endif
  call self.refresh()
endfunction

"
" toggle_select
"
function! s:Context.toggle_select() abort
  let l:item = self.get_cursor_item()
  if has_key(self.state.selected_id_map, l:item.id)
    unlet self.state.selected_id_map[l:item.id]
  else
    let self.state.selected_id_map[l:item.id] = v:true
  endif
  call self.move_cursor(1)
  call self.refresh()
endfunction

"
" move_cursor
"
function! s:Context.move_cursor(offset) abort
  if self.is_visible()
    let l:winheight = winheight(win_id2win(self.winid))
  else
    let l:winheight = len(self.state.items)
  endif

  let l:index = self.state.index
  let l:cursor = self.state.cursor + a:offset
  if l:cursor > l:winheight
    let l:index = min([self.state.filtered_total - l:winheight, l:index + l:cursor - l:winheight])
    let l:cursor = l:winheight
  elseif l:cursor < 1
    let l:index = max([0, l:index + l:cursor - 1])
    let l:cursor = 1
  else
    if win_getid() == self.winid
      call cursor(l:cursor, col('.'))
    endif
  endif

  let self.state.index = l:index
  let self.state.cursor = l:cursor
  call self.refresh()
endfunction

"
" set_cursor
"
function! s:Context.set_cursor(cursor) abort
  if self.state.cursor != a:cursor
    let self.state.cursor = a:cursor
    call self.refresh()
  endif
endfunction

"
" top
"
function! s:Context.top() abort
  let self.state.index = 0
  let self.state.cursor = 1
  call self.refresh()
endfunction

"
" bottom
"
function! s:Context.bottom() abort
  if self.is_visible()
    let l:winheight = winheight(win_id2win(self.winid))
  else
    let l:winheight = len(self.state.items)
  endif
  let self.state.index = self.state.filtered_total - l:winheight
  let self.state.cursor = l:winheight
  call self.refresh()
endfunction

"
" state_changed
"
function! s:Context.state_changed(names) abort
  for l:name in a:names
    if self.state[l:name] != self.prev_state[l:name]
      return v:true
    endif
  endfor
  return v:false
endfunction

"
" get_cursor_item
"
function! s:Context.get_cursor_item() abort
  return get(self.state.items, self.state.cursor - 1, {})
endfunction

"
" get_action_items
"
function! s:Context.get_action_items() abort
  if self.state.is_selected_all
    return candle#sync(self.fetch_all()).items
  endif

  if empty(self.state.selected_id_map)
    let l:item = self.get_cursor_item()
    if empty(l:item)
      return []
    endif
    return [l:item]
  endif

  " TODO: resolve by server.
  return filter(copy(self.state.items), 'has_key(self.state.selected_id_map, v:val.id)')
endfunction

"
" get_selected_items
"
function s:Context.get_selected_items() abort
  if self.state.is_selected_all
    return candle#sync(self.fetch_all()).items
  endif
  return filter(copy(self.state.items), 'has_key(self.state.selected_id_map, v:val.id)')
endfunction

"
" get_items
"
function! s:Context.get_items() abort
  return self.state.items
endfunction

"
" toggle_preview
"
function! s:Context.toggle_preview() abort
  let self.state.preview = !self.state.preview
  if self.state.preview
    call self.refresh()
  else
    call s:preview.close()
  endif
endfunction

"
" close_preview
"
function! s:Context.close_preview() abort
  call s:preview.close()
endfunction

"
" preview
"
function! s:Context.preview(bufnr_or_path, ...) abort
  if !self.is_visible()
    return
  endif
  if !self.state.preview
    return
  endif

  let l:line = get(a:000, 0, { 'line': 1 }).line
  let l:main = getwininfo(self.winid)[0]
  let l:width = float2nr(l:main.width / 2)
  call s:preview.set_bufnr(s:Buffer.load(a:bufnr_or_path))
  call s:preview.open({
  \   'row': l:main.winrow,
  \   'col': l:main.wincol + l:main.width - l:width,
  \   'width': l:width,
  \   'height': l:main.height,
  \   'topline': max([1, l:line - float2nr(l:main.height / 2)]),
  \ })
  if l:line != 1
    call s:TextMark.clear(s:preview.get_bufnr(), 'candle:preview')
    call s:TextMark.set(s:preview.get_bufnr(), 'candle:preview', [{
    \   'start_pos': [l:line, 1],
    \   'end_pos': [l:line + 1, 1],
    \   'highlight': 'CandlePreviewLine'
    \ }])
  endif
endfunction

"
" refresh
"
function! s:Context.refresh(...) abort
  let l:option = extend({ 'async': v:true, 'force': v:false }, get(a:000, 0, {}))

  let l:on_window = win_getid() == self.winid && self.is_visible()

  " update statusline
  if l:on_window
    call candle#render#statusline#update(self, l:option.force)
  endif

  " update items
  if self.state_changed(['query', 'index']) || self.can_display_new_items() || l:option.force
    let self.request_id += 1
    let l:id = self.request_id

    let l:promise = self.fetch().then({ response -> self.on_response(l:id, l:option, response) })
    if !l:option.async
      try
        call candle#sync(l:promise)
      catch /.*/
        call candle#on_exception()
      endtry
    endif
  else
    if self.is_visible()
      call self.refresh_others(l:option)
      call candle#render#window#resize(self)
    endif
  endif
endfunction

"
" on_response
"
function! s:Context.on_response(id, option, response) abort
  if a:id != self.request_id
    return
  endif

  let self.state.items = a:response.items
  let self.state.total = a:response.total
  let self.state.filtered_total = a:response.filtered_total
  silent call deletebufline(self.bufname, 1, '$')
  call setbufline(self.bufname, 1, map(copy(self.state.items), { _, item -> item.title }))

  if self.is_visible()
    call candle#render#window#resize(self)
    call self.refresh_others(a:option)
  endif
endfunction

"
" refresh_others
"
function! s:Context.refresh_others(option) abort
  if !self.is_visible()
    return
  endif

  let l:on_window = win_getid() == self.winid && self.is_visible()

  " update highlight
  if l:on_window
    call clearmatches()
    for l:query in split(self.state.query, '\s\+')
      call matchadd('IncSearch', '\c\V' . escape(l:query, '\/?') . '\m')
    endfor
  end

  " update cursor
  if l:on_window && (self.state.cursor != line('.') || a:option.force)
    call cursor([self.state.cursor, col('.')])
  endif
  if self.state_changed(['cursor']) || a:option.force
    call candle#render#signs#cursor(self)
  endif

  " update selected signs
  if self.state_changed(['index', 'selected_id_map', 'is_selected_all', 'query']) || a:option.force
    call candle#render#signs#selected(self)
  endif

  if self.state.preview
    call self.auto_action('preview')
  else
    call s:preview.close()
  endif

  let self.prev_state = deepcopy(self.state)
  redraw!
endfunction

"
" can_display_new_items
"
function! s:Context.can_display_new_items() abort
  let l:has_enough_items = self.option.maxheight <= len(self.state.items)
  let l:has_new_items = self.state.index + len(self.state.items) < self.state.filtered_total
  return !l:has_enough_items && l:has_new_items
endfunction

