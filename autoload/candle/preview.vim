let s:Buffer = vital#candle#import('VS.Vim.Buffer')

"
" candle#preview#filename
"
function! candle#preview#filename(filename, ...) abort
  if executable('bat')
    let l:args = get(a:000, 0, {})
    let l:bufnr = candle#preview#command(printf('bat --style=plain --color=always --paging=never --line-range=%s: --highlight-line=%s %s',
    \   max([1, get(l:args, 'lnum', 1) - 3]),
    \   get(l:args, 'lnum', 1),
    \   a:filename
    \ ))
    if !empty(l:bufnr)
      return l:bufnr
    endif
  endif

  let l:bufnr = s:Buffer.pseudo(a:filename)
  call map({
  \   '&buftype': 'nofile',
  \   '&swapfile': 0,
  \   '&undofile': 0,
  \ }, 'setbufvar(l:bufnr, v:key, v:val)')
  return l:bufnr
endfunction

"
" candle#preview#command
"
function! candle#preview#command(cmd) abort
  if has('nvim')
    if exists('s:term')
      call jobstop(getbufvar(s:term, '&channel'))
      execute printf('%sbdelete!', s:term)
    endif
    let s:term = s:Buffer.create()
    call s:Buffer.do(s:term, { -> termopen(a:cmd) })
    call setbufvar(s:term, '&scrollback', 0)
    return s:term
  endif
  return v:null
endfunction

