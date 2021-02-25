let g:candle#source#mru_dir#filepath = expand('~/.candle_mru_dir')

function! candle#source#mru_dir#new(args) abort
  return s:Source.new(a:args)
endfunction

let s:Source = {}

function! s:Source.new(args) abort
  return extend(deepcopy(s:Source), {
  \   '_filepath': get(a:args, 'filepath', g:candle#source#mru_dir#filepath),
  \ })
endfunction

function! s:Source.start(context) abort
  let l:ctx = {}
  let l:ctx.uniq = {}
  let l:ctx.context = a:context
  function! l:ctx.callback(dirname) abort
    if !has_key(self.uniq, a:dirname) && isdirectory(a:dirname)
      let self.uniq[a:dirname] = v:true
      call self.context.add_item({
      \   'title': a:dirname,
      \   'filename': a:dirname,
      \ })
    endif
  endfunction
  call candle#helper#foreach(reverse(readfile(self._filepath)), {
  \   'on_item': { item -> l:ctx.callback(item) },
  \   'on_done': { -> a:context.done() },
  \ })
endfunction
