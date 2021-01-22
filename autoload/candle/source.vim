let s:Promise = vital#candle#import('Async.Promise')

function! candle#source#import() abort
  return s:State
endfunction

let s:State = {}

function! s:State.new(args) abort
  return extend(deepcopy(s:State), {
  \   '_item_time': reltime(),
  \   '_item_id': 0,
  \   '_source': a:args.source,
  \   '_status': 'processing',
  \   '_query': '',
  \   '_items': [],
  \   '_on_abort': { -> {} },
  \ })
endfunction

function! s:State.start() abort
  call self._source.start(self)
endfunction

function! s:State.request(method, params) abort
  if a:method ==# 'fetch'
    return self.fetch(a:params)
  elseif a:method ==# 'start'
    return s:Promise.resolve()
  endif
endfunction

function! s:State.fetch(args) abort
  let self._query = a:args.query
  let self._count = a:args.count
  let self._index = a:args.index

  if self._query !=# ''
    let l:filtered = matchfuzzy(self._items, self._query, {
    \   'key': 'title',
    \ })
  else
    let l:filtered = self._items
  endif

  let l:filtered_total = len(l:filtered)
  let l:min = max([0, self._index])
  let l:max = min([l:filtered_total - 1, self._index + self._count - 1])
  return s:Promise.resolve({
  \   'items': l:filtered[ l:min : l:max ],
  \   'total': len(self._items),
  \   'filtered_total': l:filtered_total,
  \ })
endfunction

function! s:State.add_item(item) abort
  let self._item_id += 1
  let self._items += [extend(a:item, { 'id': self._item_id })]
  if reltimefloat(reltime(self._item_time)) * 1000 > 100
    let self._item_time = reltime()
    call self.fetch({
    \   'query': self._query,
    \   'count': self._count,
    \   'index': self._index,
    \ }).then({ res ->
    \   candle#on_notification({
    \     'method': 'progress',
    \     'params': extend(res, { 'id': self.id }),
    \   })
    \ })
  endif
endfunction

function! s:State.done() abort
  let self._status = 'done'
  call self.fetch({
  \   'query': self._query,
  \   'count': self._count,
  \   'index': self._index,
  \ }).then({ res ->
  \   candle#on_notification({
  \     'method': 'done',
  \     'params': extend(res, { 'id': self.id }),
  \   })
  \ })

endfunction

function! s:State.abort() abort
  let self._status = 'abort'
  call self._on_abort()
endfunction

function! s:State.on_abort(on_abort) abort
  let self._on_abort = a:on_abort
endfunction

