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
  let l:candle = extend(deepcopy(s:Context), {
        \   'bufname': a:context.bufname,
        \   'maxwidth': get(a:context, 'maxwidth', float2nr(&columns * 0.6)),
        \   'maxheight': get(a:context, 'maxheight', float2nr(&lines * 0.3)),
        \   'layout': get(a:context, 'layout', 'floating'),
        \   'source': a:context.source,
        \   'state': {
        \     'winid': -1,
        \     'prev_winid': -1,
        \     'total': 0,
        \     'items': [],
        \     'query': '',
        \     'index': 0,
        \     'cursor': 1,
        \     'selected_ids': [],
        \     'is_selected_all': v:false,
        \   },
        \   'prev_state': {
        \     'winid': -1,
        \     'prev_winid': -1,
        \     'total': 0,
        \     'items': [],
        \     'query': '',
        \     'index': -1,
        \     'cursor': -1,
        \     'selected_ids': [],
        \     'is_selected_all': v:false,
        \   }
        \ })
  call bufnr(a:context.bufname, v:true)
  call setbufvar(a:context.bufname, 'candle', l:candle)
  call setbufvar(a:context.bufname, '&buftype', 'nofile')
  call setbufvar(a:context.bufname, '&number', 0)
  call setbufvar(a:context.bufname, '&signcolumn', 'yes')
  return l:candle
endfunction

"
" start
"
function! s:Context.start() abort
  let self.state.prev_winid = win_getid()
  call candle#render#window#initialize(self)
  call candle#render#highlight#initialize(self)
  call candle#render#autocmd#initialize(self)
  call candle#render#mapping#initialize(self)
  let self.state.winid = win_getid()

  doautocmd User candle#start

  call candle#sync(self.source.start({ n -> self.on_notification(n) }))

  " NOTE: This sleep needs to reduce flicker on first opening window.
  " start -> (...async) -> on_notification -> refresh
  sleep 20m
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
  if a:notification.method ==# 'progress'
    let self.state.total = a:notification.params.total
  elseif a:notification.method ==# 'done'
    let self.state.total = a:notification.params.total
  endif
  call self.refresh({ 'async': v:true })
endfunction

"
" fetch
"
function! s:Context.fetch() abort
  return self.source.fetch({
        \   'query': self.state.query,
        \   'index': self.state.index,
        \   'count': self.maxheight,
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
  let l:after = self.source.action(a:name, self)
  if get(l:after, 'quit', v:true)
    let l:current_winid = win_getid()
    call win_gotoid(self.state.winid)
    quit
    call win_gotoid(l:current_winid)
  endif
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
    call self.up()
  else
    let self.state.selected_ids += [l:item.id]
    call self.down()
  endif
  call self.refresh()
endfunction

"
" up
"
function! s:Context.up() abort
  if self.state.cursor == 1
    let self.state.index = max([0, self.state.index - 1])
  else
    if win_getid() == self.state.winid
      normal! k
    endif
    let self.state.cursor -= 1
  endif
  call self.refresh()
endfunction

"
" down
"
function! s:Context.down() abort
  let l:winheight = winheight(win_id2win(self.state.winid))
  if l:winheight == self.state.cursor
    let self.state.index = min([self.state.total - l:winheight, self.state.index + 1])
  else
    if win_getid() == self.state.winid
      normal! j
    endif
    let self.state.cursor += 1
  endif
  call self.refresh()
endfunction

"
" set_cursor
"
function! s:Context.set_cursor(cursor) abort
  let self.state.cursor = a:cursor
  call self.refresh()
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
  let self.state.index = self.state.total - l:winheight
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
" flush
"
function! s:Context.flush() abort
  let self.prev_state = copy(self.state)
endfunction

"
" get_cursor_item
"
function! s:Context.get_cursor_item() abort
  return get(self.state.items, self.state.cursor - 1, {})
endfunction

"
" get_selected_items
"
function! s:Context.get_selected_items() abort
  if self.state.is_select_all
    return candle#sync(self.fetch_all()).items
  endif
  return filter(copy(self.state.items), { _, item -> index(self.selects, item.id) >= 0 })
endfunction

"
" refresh
"
function! s:Context.refresh(...) abort
  let l:option = extend({
  \   'async': v:false
  \ }, get(a:000, 0, {}))

  " update cursor
  if self.state_changed(['cursor'])
    if self.bufname ==# bufname('%')
      call cursor([self.state.cursor, col('.')])
    endif
    call candle#render#signs#cursor(self)
  endif

  " update selected_ids
  if self.state_changed(['selected_ids', 'is_selected_all'])
    call candle#render#signs#selected_ids(self)
  endif

  " update items
  if self.state_changed(['query', 'index'])
    let l:p = self.fetch().then({ response -> self.on_response(response) })
    if !l:option.async
      try
        call candle#sync(l:p)
      catch /.*/
        call candle#echo({ 'exception': v:exception, 'throwpoint': v:throwpoint })
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
function! s:Context.on_response(response) abort
  let self.state.items = a:response.items
  let self.state.total = a:response.total
  call candle#render#window#resize(self)
  call setbufline(self.bufname, 1, map(copy(self.state.items), { _, item ->
  \   item.title
  \ }))
  call deletebufline(self.bufname, len(self.state.items) + 1, '$')
endfunction

