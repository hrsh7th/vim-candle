let s:initial_state = {
\     'winid': -1,
\     'prev_winid': -1,
\     'total': 0,
\     'filtered_total': 0,
\     'items': [],
\     'query': '',
\     'index': 0,
\     'cursor': 1,
\     'selected_ids': [],
\     'status': 'progress',
\     'is_selected_all': v:false,
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
  let l:candle = extend({}, deepcopy(s:Context))
  let l:candle = extend(l:candle, a:context)
  let l:candle = extend(l:candle, {
        \   'request_id': 0,
        \   'state': deepcopy(s:initial_state),
        \   'prev_state': deepcopy(s:initial_state),
        \ })
  call bufnr(l:candle.bufname, v:true)
  call setbufvar(l:candle.bufname, 'candle', l:candle)
  call setbufvar(l:candle.bufname, '&filetype', 'candle')
  call setbufvar(l:candle.bufname, '&buftype', 'nofile')
  call setbufvar(l:candle.bufname, '&number', 0)
  call setbufvar(l:candle.bufname, '&signcolumn', 'yes')
  return l:candle
endfunction

"
" start
"
function! s:Context.start() abort
  call self.source.start({ n -> self.on_notification(n) })
  let self.state.status = 'progress'
  let self.state.total = 0
  let self.state.filtered_total = 0
  let self.state.selected_ids = []
  let self.state.is_selected_all = v:false
  let self.state.items = []

  try
    call candle#sync({ -> self.can_display_new_items() || self.state.status ==# 'done' }, 100)
  catch /.*/
  endtry
  call self.refresh()
endfunction

"
" stop
"
function! s:Context.stop() abort
  call self.source.stop()
endfunction

"
" on_notification
"
function! s:Context.on_notification(notification) abort
  if a:notification.method ==# 'start'
    call self.refresh({ 'async': v:true })

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
    redraw
    echon a:notification.params.message . "\n"
  endif
endfunction

"
" fetch
"
function! s:Context.fetch() abort
  return self.source.fetch({
        \   'query': self.state.query,
        \   'index': self.state.index,
        \   'count': self.option.maxheight,
        \ })
endfunction

"
" fetch_all
"
function! s:Context.fetch_all() abort
  return self.source.fetch({
        \   'query': self.state.query,
        \   'index': 0,
        \   'count': -1,
        \ })
endfunction

"
" action
"
function! s:Context.action(name) abort
  try
    " action before.
    call win_gotoid(self.state.prev_winid)

    " action execute.
    let l:after = self.source.action(a:name, self)

    " action after
    if get(l:after, 'restart', v:false)
      call self.start()
    elseif get(l:after, 'quit', v:true)
      let l:current_winid = win_getid()
      call win_gotoid(self.state.winid)
      quit
      call win_gotoid(l:current_winid)
    endif
  catch /.*/
    call candle#on_exception()

    if win_id2win(self.state.winid) != -1
      call win_gotoid(self.state.winid)
    endif
  endtry
endfunction

"
" query
"
function! s:Context.query(query) abort
  if self.state.query != a:query
    let self.state.query = a:query
    call self.top()
  endif
  call self.refresh()
endfunction

"
" toggle_select_all
"
function! s:Context.toggle_select_all() abort
  let self.state.is_selected_all = !self.state.is_selected_all
  if !self.state.is_selected_all
    let self.state.selected_ids = []
  endif
  call self.refresh()
endfunction

"
" toggle_select
"
function! s:Context.toggle_select() abort
  let l:item = self.get_cursor_item()
  let l:index = index(self.state.selected_ids, l:item.id)
  if l:index >= 0
    call remove(self.state.selected_ids, l:index)
  else
    let self.state.selected_ids += [l:item.id]
  endif
  call self.move_cursor(1)
  call self.refresh()
endfunction

"
" move_cursor
"
function! s:Context.move_cursor(offset) abort
  let l:winheight = winheight(win_id2win(self.state.winid))

  let l:index = self.state.index
  let l:cursor = self.state.cursor + a:offset
  if l:cursor > l:winheight
    let l:index = min([self.state.filtered_total - l:winheight, l:index + l:cursor - l:winheight])
    let l:cursor = l:winheight
  elseif l:cursor < 1
    let l:index = max([0, l:index + l:cursor - 1])
    let l:cursor = 1
  else
    call cursor(l:cursor, col('.'))
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
  let l:winheight = winheight(win_id2win(self.state.winid))
  let self.state.index = self.state.filtered_total - l:winheight
  let self.state.cursor = l:winheight
  call self.refresh()
endfunction

"
" state_changed
"
function! s:Context.state_changed(names) abort
  let l:changed = v:false
  for l:name in a:names
    let l:changed = l:changed || self.state[l:name] != self.prev_state[l:name]
  endfor
  return l:changed
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

  if len(self.state.selected_ids) == 0
    let l:item = self.get_cursor_item()
    if empty(l:item)
      return []
    endif
    return [l:item]
  endif

  return filter(copy(self.state.items), { _, item -> index(self.state.selected_ids, item.id) >= 0 })
endfunction

"
" refresh
"
function! s:Context.refresh(...) abort
  let l:option = extend({ 'async': v:false }, get(a:000, 0, {}))

  " initialize window
  if self.state.winid == -1
    let self.state.prev_winid = win_getid()
    call candle#render#window#initialize(self)
    call candle#render#autocmd#initialize(self)
    let self.state.winid = win_getid()

    doautocmd User candle#start

    if self.option.start_input
      call candle#render#input#open(self)
    endif
  endif

  " update statusline
  call candle#render#statusline#initialize(self)

  " update cursor
  if self.state_changed(['cursor'])
    if bufnr(self.bufname) ==# bufnr('%') && self.state.cursor != line('.')
      call cursor([self.state.cursor, col('.')])
    endif
    call candle#render#signs#cursor(self)
  endif

  " update selected_ids
  if self.state_changed(['selected_ids', 'is_selected_all'])
    call candle#render#signs#selected_ids(self)
  endif

  " update items
  if self.state_changed(['query', 'index']) || self.can_display_new_items()
    let self.request_id += 1
    let l:id = self.request_id

    let l:promise = self.fetch().then({ response -> self.on_response(l:id, response) })
    if !l:option.async
      try
        call candle#sync(l:promise)
      catch /.*/
        call candle#on_exception()
      endtry
    endif
  else
    call candle#render#window#resize(self)
  endif

  let self.prev_state = deepcopy(self.state)
endfunction

"
" on_response
"
function! s:Context.on_response(id, response) abort
  if a:id != self.request_id
    return
  endif

  let self.state.items = a:response.items
  let self.state.total = a:response.total
  let self.state.filtered_total = a:response.filtered_total
  call candle#render#window#resize(self)
  call setbufline(self.bufname, 1, map(copy(self.state.items), { _, item ->
  \   item.title
  \ }))
  call deletebufline(self.bufname, len(self.state.items) + 1, '$')
endfunction

"
" can_display_new_items
"
function! s:Context.can_display_new_items() abort
  let l:has_enough_items = self.option.maxheight <= len(self.state.items)
  let l:has_new_items = self.state.index + len(self.state.items) < self.state.filtered_total
  return !l:has_enough_items && l:has_new_items
endfunction

