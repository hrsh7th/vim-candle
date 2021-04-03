function! candle#source#item#new(args) abort
  return s:Source.new(a:args)
endfunction

let s:Source = {}

function! s:Source.new(args) abort
  return extend(deepcopy(s:Source), {
  \   '_items': a:args.items,
  \ })
endfunction

function! s:Source.start(context) abort
  call map(copy(self._items), { _, item -> a:context.add_item(item) })
  call a:context.done()
endfunction

