function! candle#source#file#new(args) abort
  return s:Source.new(a:args)
endfunction

let s:Source = {}

function! s:Source.new(args) abort
  return extend(deepcopy(s:Source), {
  \   '_root_path': a:args.root_path,
  \ })
endfunction

function! s:Source.start(context) abort
  let l:job = job_start(self._command(), {
  \   'in_mode': 'raw',
  \   'in_io': 'pipe',
  \   'out_mode': 'raw',
  \   'out_io': 'pipe',
  \   'out_cb': { job, text -> map(split(text, "\n"), { _, line -> a:context.add_item(self._to_item(line)) }) },
  \   'exit_cb': { job, code -> a:context.done() },
  \ })
  call a:context.on_abort({ -> job_stop(l:job) })
endfunction

function! s:Source._to_item(line) abort
  return {
  \   'title': fnamemodify(a:line, ':~'),
  \   'filename': fnamemodify(a:line, ':p'),
  \ }
endfunction

function! s:Source._command() abort
  if executable('fd')
    return ['fd', '--type', 'f', '--color', 'never', '', self._root_path]
  endif
  return ['find', self._root_path, '-type', 'f']
endfunction

