"
" candle#source#git#is_staged
"
function! candle#source#git#is_staged_status(item) abort
  return index(['R ', 'M ', 'A ', 'D '], a:item.status) >= 0
endfunction

"
" candle#source#git#is_modified
"
function! candle#source#git#is_modified(item) abort
  return index(['R ', ' R', 'M ', ' M'], a:item.status) >= 0
endfunction

"
" candle#source#git#run
"
function! candle#source#git#run(candle, subcommand, args) abort
  let l:output = system(printf(
  \   'git -C %s %s %s',
  \   fnameescape(a:candle.source.script.args.working_dir),
  \   a:subcommand,
  \   join(map(copy(a:args), { _, v -> escape(v, ' ') })),
  \ ))
  let l:output = type(l:output) == v:t_list ? join(l:output, '\n') : l:output
  let l:output = substitute(l:output, "\n", '\n', 'g')
  let l:output = split(l:output, "\n", v:true)
  return filter(l:output, { _, v -> v !=# '' })
endfunction

"
" candle#source#git#run_items
"
function! candle#source#git#run_items(candle, subcommand, items, ...) abort
  if len(a:items) > 0
    let l:output = system(printf(
    \   'git -C %s %s %s -- %s',
    \   fnameescape(a:candle.source.script.args.working_dir),
    \   a:subcommand,
    \   join(map(copy(get(a:000, 0, [])), { _, v -> escape(v, ' ') })),
    \   join(map(copy(a:items), { _, item -> fnameescape(item.filename) }))
    \ ))
    let l:output = type(l:output) == v:t_list ? join(l:output, '\n') : l:output
    let l:output = substitute(l:output, "\n", '\n', 'g')
    return split(l:output, "\n")
  endif
  return []
endfunction

"
" candle#source#git#diff_status
"
function! candle#source#git#diff_status(candle, status_item) abort
  if !candle#source#git#is_modified(a:status_item)
    echomsg printf('`%s` is not modified file.', a:status_item.filename)
    return
  endif

  let l:filename_a = fnameescape(s:join(a:candle.source.script.args.working_dir, a:status_item.filename))
  let l:filename_b = fnameescape(substitute(l:filename_a, '\(\.[^\.]\+\)$', '~HEAD'. '\1', 'g'))

  let l:object = system(printf(
  \   'git -C %s show HEAD:%s',
  \   fnameescape(a:candle.source.script.args.working_dir),
  \   fnameescape(a:status_item.filename)
  \ ))

  noautocmd silent! execute printf('tabnew | file! %s | put!=l:object | $delete | diffthis | setlocal bufhidden=hide buftype=nofile nobuflisted noswapfile nomodifiable nomodified | normal! zM', l:filename_b)
  filetype detect

  noautocmd silent! execute printf('topleft vsplit %s | diffthis | normal! zMgg', l:filename_a)
  filetype detect
endfunction

"
" candle#source#git#commit
"
function! candle#source#git#commit(candle, status_items, amend) abort
  if len(a:status_items) <= 0
    echomsg 'nothing to commit'
    return
  endif

  " open buffer.
  execute printf('noautocmd silent! tabedit %s', s:join(a:candle.source.script.args.working_dir, '.git', 'COMMIT_EDITMSG'))
  set filetype=gitcommit

  " initialize vars.
  let b:candle_git_commit = {}
  let b:candle_git_commit.candle = a:candle
  let b:candle_git_commit.amend = a:amend
  let b:candle_git_commit.items = a:status_items
  function! b:candle_git_commit.commit() abort
    if s:yesno('commit?')
      let l:args = ['-F', s:join(self.candle.source.script.args.working_dir, '.git', 'COMMIT_EDITMSG')]
      if self.amend
        let l:args += ['--amend']
      endif
      call s:echomsg(candle#source#git#run_items(self.candle, 'commit', b:candle_git_commit.items, l:args))
      call getchar()
    endif
    bdelete!
    call self.candle.close()
  endfunction

  " initialize buffer.
  silent % delete _

  if a:amend
    put!=candle#source#git#run(a:candle, 'show', ['-s', '--format=%B'])
  endif

  let l:separator = ["#####"]
  put=l:separator

  let l:verbose = candle#source#git#run_items(a:candle, 'commit', b:candle_git_commit.items, ['--dry-run', '-v'] + (a:amend ? ['--reuse-message=HEAD'] : []))
  let l:verbose = type(l:verbose) == type([]) ? l:verbose : split(l:verbose, "\n")
  let l:verbose = map(l:verbose, { _, line -> strcharpart(line, 0, 500) })
  put=l:verbose
  noautocmd write!
  call cursor(1, 1)

  augroup candle_git_commit
    autocmd!
    autocmd! BufWinEnter <buffer> setlocal bufhidden=wipe nobuflisted noswapfile
    autocmd! BufWritePre <buffer> execute 'silent %s/#####\_.*$//ge'
    autocmd! BufWritePost <buffer> call b:candle_git_commit.commit()
  augroup END
endfunction

"
" s:join
"
function! s:join(...) abort
  let l:path = ''
  for l:part in a:000
    if l:part[0:0] !=# '/'
      let l:part = '/' .. l:part
    endif
    let l:path = l:path .. substitute(l:part, '\/$', '', 'g')
  endfor
  return l:path
endfunction

"
" s:yesno
"
function! s:yesno(msg) abort
  let choose = input(a:msg . '(yes/no): ')
  echomsg ' '
  if index(['y', 'ye', 'yes'], choose) > -1
    return v:true
  endif
  return v:false
endfunction

"
" s:echomsg
"
function! s:echomsg(text) abort
  for l:text in (type(a:text) == v:t_list ? a:text : split(a:text, "\n"))
    echomsg l:text
  endfor
endfunction
