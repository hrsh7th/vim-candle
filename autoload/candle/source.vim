let s:Promise = vital#candle#import('Async.Promise')
let s:Matcher = vital#candle#import('VS._.List.Matcher')

function! candle#source#import() abort
  return s:State
endfunction

let s:State = {}

function! s:State.new(args) abort
  return extend(deepcopy(s:State), {
  \   '_source': a:args.source,
  \   '_query': v:null,
  \   '_count': 0,
  \   '_index': 0,
  \   '_item_time': reltime(),
  \   '_item_id': 0,
  \   '_items': [],
  \   '_filtered_items': [],
  \   '_status': 'processing',
  \   '_on_abort': { -> {} },
  \ })
endfunction

function! s:State.request(method, params) abort
  if a:method ==# 'fetch'
    return self.fetch(a:params)
  elseif a:method ==# 'start'
    let self._item_time = reltime()
    let self._item_id = 0
    let self._items = []
    let self._status = 'progress'
    call self._source.start(self)
    return s:Promise.resolve()
  endif
endfunction

function! s:State.fetch(args) abort
  let self._count = a:args.count
  let self._index = a:args.index

  if self._query is# v:null || self._query !=# a:args.query
    let self._query = a:args.query
    if self._query !=# ''
      let self._filtered_items = s:Matcher.match({
      \   'items': self._items,
      \   'query': self._query,
      \   'key': 'title',
      \ })
    else
      let self._filtered_items = self._items
    endif
  endif

  let l:filtered_total = len(self._filtered_items)
  let l:min = max([0, self._index])
  let l:max = min([l:filtered_total - 1, self._index + self._count - 1])
  return s:Promise.resolve({
  \   'items': self._filtered_items[ l:min : l:max ],
  \   'total': len(self._items),
  \   'filtered_total': l:filtered_total,
  \ })
endfunction

function! s:State.add_item(item) abort
  if a:item is# v:null
    return
  endif

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

function! s:State.get_items() abort
  return copy(self._items)
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

