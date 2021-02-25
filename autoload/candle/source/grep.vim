function! candle#source#grep#new(args) abort
  return s:Source.new(a:args)
endfunction

let s:Source = {}

function! s:Source.new(args) abort
  return extend(deepcopy(s:Source), {
  \   '_root_path': a:args.root_path,
  \ })
endfunction

function! s:Source.start(context) abort
  call candle#helper#process(self._command(), {
  \   'on_item': { text -> a:context.add_item(self._to_item(text)) },
  \   'on_done': { -> a:context.done() }
  \ })
endfunction

function! s:Source._to_item(line) abort
  let l:match = matchlist(a:line, '^\([^:]\+\):\([^:]\+\):\(.*\)')
  if !empty(l:match)
    return {
    \   'title': printf('%s:%s: %s', fnamemodify(l:match[1], ':~'), l:match[2], l:match[3]),
    \   'lnum': l:match[2],
    \   'filename': fnamemodify(l:match[1], ':p'),
    \ }
  endif
  return v:null
endfunction

function! s:Source._command() abort
  let l:input = input('Pattern: ')
  if executable('rg')
    return ['rg', '-i', '--vimgrep', '--no-heading', '--no-column', l:input, self._root_path]
  endif
  if executable('ag')
    return ['ag', '-i', '--nocolor', '--noheading', '--nobreak', l:input, self._root_path]
  endif
  if executable('pt')
    return ['pt', '-i', '--nogroup', '--nocolor', l:input, self._root_path]
  endif
  if executable('jvgrep')
    return ['jvgrep', '-iR', '--no-color', l:input, self._root_path]
  endif
  return ['grep', '-rin', l:input, self._root_path]
endfunction

