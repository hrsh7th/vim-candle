let g:candle#source#mru_file#filepath = expand('~/.candle_mru_file')

function! candle#source#mru_file#new(args) abort
  return s:Source.new(a:args)
endfunction

let s:Source = {}

function! s:Source.new(args) abort
  return extend(deepcopy(s:Source), {
  \   '_context': v:null,
  \   '_filepath': get(a:args, 'filepath', g:candle#source#mru_file#filepath),
  \   '_timer_id': -1,
  \   '_filenames': [],
  \ })
endfunction

function! s:Source.start(context) abort
  let self._context = a:context
  let self._filenames = readfile(self._filepath)
  call self._emit()
  let self._timer = timer_start(100, { -> self._emit() }, { 'repeat': -1 })
endfunction

function! s:Source._emit() abort
  for l:filename in remove(self._filenames, 0, min([200, len(self._filenames) - 1]))
    if filereadable(l:filename)
      call self._context.add_item({
      \   'title': l:filename,
      \   'filename': l:filename,
      \ })
    endif
  endfor
  if empty(self._filenames)
    call timer_stop(self._timer)
    call self._context.done()
  endif
endfunction
