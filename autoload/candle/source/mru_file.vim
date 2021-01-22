let g:candle#source#mru_file#filepath = expand('~/.candle_mru_file')

function! candle#source#mru_file#new(args) abort
  return s:Source.new(a:args)
endfunction

let s:Source = {}

function! s:Source.new(args) abort
  return extend(deepcopy(s:Source), {
  \   '_context': v:null,
  \   '_job': v:null,
  \   '_filepath': get(a:args, 'filepath', g:candle#source#mru_file#filepath),
  \   '_timer_id': -1,
  \   '_filenames': [],
  \ })
endfunction

function! s:Source.start(context) abort
  let self._context = a:context
  let self._job = job_start(['cat', self._filepath], {
  \   'out_io': 'pipe',
  \   'out_mode': 'raw',
  \   'err_io': 'pipe',
  \   'err_mode': 'raw',
  \   'out_cb': { job, text -> self._on_stdout(text) },
  \   'err_cb': { job, text -> self._on_stderr(text) },
  \   'exit_cb': { -> self._context.done() }
  \ })
  call self._context.on_abort({ -> [job_stop(self._job), execute('let self._job = v:null')] })

  let self._timer = timer_start(200, { -> self._emit() }, { 'repeat': -1 })
endfunction

function! s:Source._on_stdout(text) abort
  let self._filenames += split(a:text, "\n")
endfunction

function! s:Source._on_stderr(text) abort
  echomsg a:text
endfunction

function! s:Source._emit() abort
  for l:filename in remove(self._filenames, 0, min([50, len(self._filenames) - 1]))
    if filereadable(l:filename)
      call self._context.add_item({
      \   'title': l:filename,
      \   'filename': l:filename,
      \ })
    endif
  endfor
  if empty(self._job) && empty(self._filenames)
    call timer_stop(self._timer)
  endif
endfunction
